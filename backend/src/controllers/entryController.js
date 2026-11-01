const { query, pool } = require('../db/client');
const { validatePutEntries } = require('../validators/entryValidator');
const { isValidDateFormat } = require('../utils/dateUtils');
const { ValidationError } = require('../utils/errors');

async function getEntriesByDate(req, res, next) {
  try {
    const { date } = req.params;
    if (!isValidDateFormat(date)) {
      return next(ValidationError('Invalid date format. Expected YYYY-MM-DD.'));
    }

    // Query both AFTERNOON (or MORNING) and EVENING entries joined with sections
    const getSlotEntries = async (slots) => {
      const sql = `
        SELECT 
          s.id AS section_id,
          s.code,
          s.name,
          s.in_core_total,
          s.count_type,
          s.sort_order,
          e.id AS entry_id,
          e.amount,
          e.new_jobs_amount,
          e.outstanding_jobs_amount,
          e.jobs_completed,
          e.ongoing_jobs,
          e.new_jobs,
          e.outstanding_jobs,
          e.updated_by,
          e.updated_at,
          (e.id IS NOT NULL) AS is_entered
        FROM sections s
        LEFT JOIN daily_entries e 
          ON e.section_id = s.id 
          AND e.entry_date = $1 
          AND e.slot = ANY($2::text[])
        ORDER BY s.sort_order ASC;
      `;
      const { rows } = await query(sql, [date, slots]);
      return rows.map(r => ({
        section_id: r.section_id,
        code: r.code,
        name: r.name,
        in_core_total: r.in_core_total,
        count_type: r.count_type,
        sort_order: r.sort_order,
        entry_id: r.entry_id,
        amount: r.amount !== null ? r.amount : '0.00',
        new_jobs_amount: r.new_jobs_amount !== null ? r.new_jobs_amount : '0.00',
        outstanding_jobs_amount: r.outstanding_jobs_amount !== null ? r.outstanding_jobs_amount : '0.00',
        jobs_completed: r.jobs_completed,
        ongoing_jobs: r.ongoing_jobs,
        new_jobs: r.new_jobs,
        outstanding_jobs: r.outstanding_jobs,
        is_entered: r.is_entered,
        updated_by: r.updated_by,
        updated_at: r.updated_at,
      }));
    };

    const [afternoon, evening] = await Promise.all([
      getSlotEntries(['AFTERNOON', 'MORNING']),
      getSlotEntries(['EVENING']),
    ]);

    res.json({
      date,
      morning: afternoon,
      afternoon,
      evening,
    });
  } catch (err) {
    next(err);
  }
}

async function putEntries(req, res, next) {
  const { date, slot } = req.params;
  const targetSlot = slot.toUpperCase() === 'MORNING' ? 'AFTERNOON' : slot.toUpperCase();
  const validation = await validatePutEntries(date, targetSlot, req.body);

  if (!validation.valid) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: validation.error,
      },
    });
  }

  const entriesToSave = validation.data;
  const userId = req.user ? req.user.id : null;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const savedEntries = [];

    for (const item of entriesToSave) {
      // 1. Fetch current existing row to detect changes for audit
      const existingRes = await client.query(
        `SELECT id, amount, new_jobs_amount, outstanding_jobs_amount, jobs_completed, ongoing_jobs, new_jobs, outstanding_jobs 
         FROM daily_entries 
         WHERE entry_date = $1 AND section_id = $2 AND slot IN ($3, 'MORNING')`,
        [date, item.section_id, targetSlot]
      );
      const oldRow = existingRes.rows[0];

      // 2. Perform transactional upsert
      const upsertSql = `
        INSERT INTO daily_entries (
          entry_date, section_id, slot, amount, new_jobs_amount, outstanding_jobs_amount, jobs_completed, ongoing_jobs, new_jobs, outstanding_jobs, updated_by, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, now())
        ON CONFLICT (entry_date, section_id, slot)
        DO UPDATE SET
          amount = EXCLUDED.amount,
          new_jobs_amount = EXCLUDED.new_jobs_amount,
          outstanding_jobs_amount = EXCLUDED.outstanding_jobs_amount,
          jobs_completed = EXCLUDED.jobs_completed,
          ongoing_jobs = EXCLUDED.ongoing_jobs,
          new_jobs = EXCLUDED.new_jobs,
          outstanding_jobs = EXCLUDED.outstanding_jobs,
          updated_by = EXCLUDED.updated_by,
          updated_at = now()
        RETURNING *;
      `;

      const result = await client.query(upsertSql, [
        date,
        item.section_id,
        targetSlot,
        item.amount,
        item.new_jobs_amount,
        item.outstanding_jobs_amount,
        item.jobs_completed,
        item.ongoing_jobs,
        item.new_jobs,
        item.outstanding_jobs,
        userId,
      ]);
      savedEntries.push(result.rows[0]);

      // 3. Write audit log if an existing row was modified with different values
      if (oldRow) {
        const oldAmount = parseFloat(oldRow.amount || '0').toFixed(2);
        const newAmount = parseFloat(item.amount || '0').toFixed(2);
        const oldNja = parseFloat(oldRow.new_jobs_amount || '0').toFixed(2);
        const newNja = parseFloat(item.new_jobs_amount || '0').toFixed(2);
        const oldOja = parseFloat(oldRow.outstanding_jobs_amount || '0').toFixed(2);
        const newOja = parseFloat(item.outstanding_jobs_amount || '0').toFixed(2);

        const isChanged =
          oldAmount !== newAmount ||
          oldNja !== newNja ||
          oldOja !== newOja ||
          oldRow.jobs_completed !== item.jobs_completed;

        if (isChanged) {
          const oldValues = {
            amount: oldAmount,
            new_jobs_amount: oldNja,
            outstanding_jobs_amount: oldOja,
            jobs_completed: oldRow.jobs_completed,
          };
          const newValues = {
            amount: newAmount,
            new_jobs_amount: newNja,
            outstanding_jobs_amount: newOja,
            jobs_completed: item.jobs_completed,
          };

          await client.query(
            `INSERT INTO entry_audit (
              entry_date, section_id, slot, old_values, new_values, changed_by, changed_at
            ) VALUES ($1, $2, $3, $4, $5, $6, now())`,
            [date, item.section_id, targetSlot, JSON.stringify(oldValues), JSON.stringify(newValues), userId]
          );
        }
      }
    }

    await client.query('COMMIT');

    res.json({
      message: 'Entries saved successfully',
      date,
      slot: targetSlot,
      entries: savedEntries,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

module.exports = {
  getEntriesByDate,
  putEntries,
};
