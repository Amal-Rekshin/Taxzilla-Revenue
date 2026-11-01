const { query } = require('../db/client');
const { getAllSections } = require('../services/sectionService');
const { calculateDayTotals } = require('../services/calculationService');
const { fetchEntriesForMonth, validateMonthParam } = require('./reportController');
const { getTodayInKolkata, isValidDateFormat, isSunday } = require('../utils/dateUtils');
const { ValidationError } = require('../utils/errors');

async function getEntriesHistoryList(req, res, next) {
  try {
    const { month, filter = 'all' } = req.query;
    validateMonthParam(month);

    if (!['all', 'pending', 'edited'].includes(filter)) {
      throw ValidationError("Filter must be one of 'all', 'pending', or 'edited'.");
    }

    const sections = await getAllSections();
    const rows = await fetchEntriesForMonth(month);
    const today = getTodayInKolkata();

    const [yearStr, monthStr] = month.split('-');
    const year = parseInt(yearStr, 10);
    const monthNum = parseInt(monthStr, 10);
    const daysInMonth = new Date(year, monthNum, 0).getDate();

    // Map entries by date and slot
    const entriesByDate = new Map();
    for (const r of rows) {
      const dateStr = typeof r.entry_date === 'string'
        ? r.entry_date.substring(0, 10)
        : `${r.entry_date.getFullYear()}-${String(r.entry_date.getMonth() + 1).padStart(2, '0')}-${String(r.entry_date.getDate()).padStart(2, '0')}`;

      if (!entriesByDate.has(dateStr)) {
        entriesByDate.set(dateStr, { MORNING: [], AFTERNOON: [], EVENING: [] });
      }
      const slotMap = entriesByDate.get(dateStr);
      if (slotMap[r.slot]) {
        slotMap[r.slot].push(r);
      } else {
        slotMap[r.slot] = [r];
      }
    }

    // Query audit entries for the month to flag edited dates and fetch lastUpdated info
    const auditSql = `
      SELECT 
        a.entry_date::text AS entry_date,
        a.slot,
        a.changed_at,
        u.username AS changed_by_username
      FROM entry_audit a
      LEFT JOIN users u ON u.id = a.changed_by
      WHERE a.entry_date >= $1 AND a.entry_date <= $2
      ORDER BY a.changed_at DESC;
    `;
    const startDate = `${month}-01`;
    const endDate = `${month}-${String(daysInMonth).padStart(2, '0')}`;
    const auditRes = await query(auditSql, [startDate, endDate]);

    const auditByDate = new Map();
    for (const a of auditRes.rows) {
      if (!auditByDate.has(a.entry_date)) {
        auditByDate.set(a.entry_date, []);
      }
      auditByDate.get(a.entry_date).push(a);
    }

    // Generate days in ascending chronological order (1 to daysInMonth)
    const daysList = [];

    for (let d = 1; d <= daysInMonth; d++) {
      const dayStr = String(d).padStart(2, '0');
      const dateStr = `${month}-${dayStr}`;

      const dayEntries = entriesByDate.get(dateStr) || { MORNING: [], AFTERNOON: [], EVENING: [] };
      const morningDone = (dayEntries.MORNING?.length > 0) || (dayEntries.AFTERNOON?.length > 0);
      const eveningDone = dayEntries.EVENING?.length > 0;

      // Calculate evening totals
      let total1 = 0;
      let total2 = 0;
      if (eveningDone) {
        const eveningItems = dayEntries.EVENING.map(e => {
          const sec = sections.find(s => s.id === e.section_id);
          return {
            amount: e.amount,
            in_core_total: sec ? sec.in_core_total : false,
          };
        });
        const totals = calculateDayTotals(eveningItems);
        total1 = totals.total1;
        total2 = totals.total2;
      }

      const dayAudits = auditByDate.get(dateStr) || [];
      const isEdited = dayAudits.length > 0;
      const isSun = isSunday(dateStr);
      const isPending = !eveningDone && !isSun;

      let lastUpdatedBy = null;
      let lastUpdatedAt = null;

      if (isEdited) {
        lastUpdatedBy = dayAudits[0].changed_by_username;
        lastUpdatedAt = dayAudits[0].changed_at;
      } else if (eveningDone || morningDone) {
        const allEntries = [...(dayEntries.EVENING || []), ...(dayEntries.AFTERNOON || []), ...(dayEntries.MORNING || [])];
        allEntries.sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at));
        lastUpdatedAt = allEntries[0].updated_at;
      }

      const item = {
        date: dateStr,
        morningDone,
        afternoonDone: morningDone,
        eveningDone,
        total1,
        total2,
        isPending,
        isSunday: isSun,
        isEdited,
        lastUpdatedBy,
        lastUpdatedAt,
      };

      // Filter logic
      if (filter === 'pending') {
        // Pending only (for current month, only up to today; exclude Sundays)
        if (isPending && (dateStr <= today)) {
          daysList.push(item);
        }
      } else if (filter === 'edited') {
        if (isEdited) {
          daysList.push(item);
        }
      } else {
        daysList.push(item);
      }
    }

    res.json({
      month,
      filter,
      entries: daysList,
    });
  } catch (err) {
    next(err);
  }
}

async function getEntryAuditHistory(req, res, next) {
  try {
    const { date } = req.params;
    const slot = req.params.slot || req.query.slot;

    if (!isValidDateFormat(date)) {
      throw ValidationError('Invalid date format. Expected YYYY-MM-DD.');
    }
    if (slot && slot !== 'MORNING' && slot !== 'AFTERNOON' && slot !== 'EVENING' && slot !== 'ALL') {
      throw ValidationError("Slot must be 'AFTERNOON', 'EVENING', or 'ALL'.");
    }

    let sql = `
      SELECT 
        a.id,
        a.entry_date::text AS entry_date,
        a.section_id,
        s.code AS section_code,
        s.name AS section_name,
        CASE WHEN a.slot = 'MORNING' THEN 'AFTERNOON' ELSE a.slot END AS slot,
        a.old_values,
        a.new_values,
        a.changed_by,
        u.username AS changed_by_username,
        a.changed_at
      FROM entry_audit a
      JOIN sections s ON s.id = a.section_id
      LEFT JOIN users u ON u.id = a.changed_by
      WHERE a.entry_date = $1
    `;
    const params = [date];

    if (slot && slot !== 'ALL') {
      if (slot === 'MORNING' || slot === 'AFTERNOON') {
        sql += ` AND a.slot IN ('MORNING', 'AFTERNOON')`;
      } else {
        sql += ` AND a.slot = $2`;
        params.push(slot);
      }
    }

    sql += ` ORDER BY a.changed_at DESC;`;

    const { rows } = await query(sql, params);
    const formatted = rows.map(r => ({
      ...r,
      id: parseInt(r.id, 10) || r.id,
      section_id: parseInt(r.section_id, 10) || r.section_id,
      changed_by: r.changed_by != null ? parseInt(r.changed_by, 10) : null,
    }));
    res.json(formatted);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getEntriesHistoryList,
  getEntryAuditHistory,
};

