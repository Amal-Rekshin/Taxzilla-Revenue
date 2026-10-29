const { query } = require('../db/client');
const { getAllSections } = require('../services/sectionService');
const { compileMonthlyReport } = require('../services/calculationService');
const { generateMonthlyExcelWorkbook } = require('../services/excelService');
const { ValidationError } = require('../utils/errors');

function validateMonthParam(month) {
  if (!month || typeof month !== 'string' || !/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
    throw ValidationError("Invalid month format. Expected YYYY-MM (e.g. '2026-10').");
  }
}

async function fetchEntriesForMonth(yearMonth) {
  const [yearStr, monthStr] = yearMonth.split('-');
  const year = parseInt(yearStr, 10);
  const month = parseInt(monthStr, 10);
  const daysInMonth = new Date(year, month, 0).getDate();

  const startDate = `${yearMonth}-01`;
  const endDate = `${yearMonth}-${String(daysInMonth).padStart(2, '0')}`;

  const sql = `
    SELECT 
      e.id,
      e.entry_date::text AS entry_date,
      e.section_id,
      e.slot,
      e.amount,
      e.jobs_completed,
      e.ongoing_jobs,
      e.new_jobs,
      e.outstanding_jobs,
      e.updated_by,
      e.updated_at
    FROM daily_entries e
    WHERE e.entry_date >= $1 AND e.entry_date <= $2
    ORDER BY e.entry_date ASC, e.section_id ASC;
  `;
  const { rows } = await query(sql, [startDate, endDate]);
  return rows;
}

async function getMonthlyReport(req, res, next) {
  try {
    const { month } = req.query;
    validateMonthParam(month);

    const sections = await getAllSections();
    const rows = await fetchEntriesForMonth(month);

    const report = compileMonthlyReport(month, sections, rows);
    res.json(report);
  } catch (err) {
    next(err);
  }
}

async function exportMonthlyReport(req, res, next) {
  try {
    const { month } = req.query;
    validateMonthParam(month);

    const sections = await getAllSections();
    const rows = await fetchEntriesForMonth(month);

    const workbook = await generateMonthlyExcelWorkbook(month, sections, rows);

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="Revenue_Report_${month}.xlsx"`
    );

    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMonthlyReport,
  exportMonthlyReport,
  validateMonthParam,
  fetchEntriesForMonth,
};
