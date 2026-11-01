const ExcelJS = require('exceljs');
const { calculateDayTotals } = require('./calculationService');

const CURRENCY_FORMAT = '₹#,##0.00';
const INTEGER_FORMAT = '#,##0';

/**
 * Generates the official multi-sheet Excel workbook for a calendar month.
 * 
 * Rules:
 * - Sheet 1: Evening (official numbers, used for all totals)
 * - Sheet 2: Afternoon (reference only)
 * - Sections Order: EXIM, GST, REGISTRATION, CRO, ACCOUNTS, MARKETING
 * - Total 1 formula: =B + C + D + E (EXIM + GST + REGISTRATION + CRO)
 * - Total 2 formula: =SUM(B:G)
 * - Week Total rows use Excel formulas =SUM(...) for natural 7-day groups
 * - Monthly Total row at the bottom sums all Week Total rows using formulas
 * - Brand styling: Purple (#753C8D) headers, Green (#85C041) Total 2, Soft Lavender week rows
 * 
 * @param {Object} report - Result of compileMonthlyReport
 * @param {Array} afternoonRows - Raw dbRows for afternoon/morning reference slot
 * @param {Array} sections - Ordered list of sections
 * @returns {Promise<Buffer>} Excel file buffer
 */
async function generateMonthlyExcelWorkbook(report, afternoonRows, sections) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'RevPulse Daily Revenue Tracker';
  workbook.created = new Date();

  const headerFont = {
    name: 'Calibri',
    size: 11,
    bold: true,
    color: { argb: 'FFFFFFFF' },
  };

  const headerFill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF753C8D' }, // Brand Purple
  };

  // ==========================================
  // SHEET 1: Evening (Official)
  // ==========================================
  const sheet = workbook.addWorksheet('Evening (Official)', {
    views: [{ state: 'frozen', xSplit: 1, ySplit: 1 }],
  });

  sheet.columns = [
    { header: 'Date', key: 'date', width: 14 },
    { header: 'EXIM', key: 'exim', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'GST', key: 'gst', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Registration', key: 'registration', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'CRO', key: 'cro', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Accounts', key: 'accounts', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Marketing', key: 'marketing', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Total 1', key: 'total1', width: 16, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Total 2', key: 'total2', width: 16, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'EXIM Jobs', key: 'exim_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'GST Jobs', key: 'gst_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Registration Jobs', key: 'reg_jobs', width: 17, style: { numFmt: INTEGER_FORMAT } },
    { header: 'CRO Jobs', key: 'cro_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Marketing Jobs', key: 'mkt_jobs', width: 15, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc New (₹)', key: 'acc_new_amt', width: 16, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Acc Outstanding (₹)', key: 'acc_outstanding_amt', width: 18, style: { numFmt: CURRENCY_FORMAT } },
  ];

  // Style header row
  const headerRow = sheet.getRow(1);
  headerRow.height = 24;
  headerRow.eachCell((cell) => {
    cell.fill = headerFill;
    cell.font = headerFont;
    cell.alignment = { vertical: 'middle', horizontal: 'center' };
  });

  const weekTotalRowFont = {
    name: 'Calibri',
    size: 11,
    bold: true,
    color: { argb: 'FF753C8D' }, // Brand Purple
  };
  const weekTotalRowFill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFF3E8FF' }, // Soft lavender
  };

  const numDays = report.days.length;
  let currentRow = 2;
  let weekStartRow = 2;
  let weekIndex = 0;
  const weekTotalRowNumbers = [];

  for (let i = 0; i < numDays; i++) {
    const day = report.days[i];
    const row = sheet.getRow(currentRow);
    row.height = 20;

    row.getCell('A').value = day.isSunday ? `${day.date} (Sun)` : day.date;
    row.getCell('A').alignment = { vertical: 'middle', horizontal: 'center' };

    if (day.status === 'COMPLETE') {
      row.getCell('B').value = day.amounts.EXIM || 0;
      row.getCell('C').value = day.amounts.GST || 0;
      row.getCell('D').value = day.amounts.REGISTRATION || 0;
      row.getCell('E').value = day.amounts.CRO || 0;
      row.getCell('F').value = day.amounts.ACCOUNTS || 0;
      row.getCell('G').value = day.amounts.MARKETING || 0;

      // Core Total 1 = EXIM + GST + REGISTRATION + CRO (B + C + D + E)
      row.getCell('H').value = { formula: `B${currentRow}+C${currentRow}+D${currentRow}+E${currentRow}`, result: day.total1 };
      // Grand Total 2 = SUM(B:G)
      row.getCell('I').value = { formula: `SUM(B${currentRow}:G${currentRow})`, result: day.total2 };

      row.getCell('J').value = day.jobs.EXIM || 0;
      row.getCell('K').value = day.jobs.GST || 0;
      row.getCell('L').value = day.jobs.REGISTRATION || 0;
      row.getCell('M').value = day.jobs.CRO || 0;
      row.getCell('N').value = day.jobs.MARKETING || 0;

      row.getCell('O').value = day.accounts.new_jobs_amount || 0;
      row.getCell('P').value = day.accounts.outstanding_jobs_amount || 0;
    } else {
      // Pending or Sunday: cells are blank for financial columns
      for (let c = 2; c <= 16; c++) {
        row.getCell(c).value = null;
      }
    }

    const isLastDay = i === numDays - 1;
    if (day.isSunday || isLastDay) {
      // Insert Week Total row
      const weekEndRow = currentRow;
      currentRow++;
      const weekTotalRow = sheet.getRow(currentRow);
      weekTotalRow.height = 22;

      const currentWeek = report.weeks && report.weeks[weekIndex] ? report.weeks[weekIndex] : null;
      const weekNum = currentWeek ? currentWeek.weekNumber : (weekIndex + 1);

      weekTotalRow.getCell('A').value = `Week ${weekNum} Total`;
      weekTotalRow.getCell('A').alignment = { vertical: 'middle', horizontal: 'center' };

      // SUM formulas for this week: B through N
      const colLetters = ['B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];
      for (const col of colLetters) {
        weekTotalRow.getCell(col).value = { formula: `SUM(${col}${weekStartRow}:${col}${weekEndRow})` };
      }

      // Accounts: O is sum of new_jobs_amount, P is running balance of outstanding_jobs_amount
      if (currentWeek) {
        weekTotalRow.getCell('O').value = { formula: `SUM(O${weekStartRow}:O${weekEndRow})` };
        weekTotalRow.getCell('P').value = currentWeek.totals.accounts.outstanding_jobs_amount;
      }

      // Style week total row
      weekTotalRow.eachCell((cell) => {
        cell.font = weekTotalRowFont;
        cell.fill = weekTotalRowFill;
        cell.border = {
          top: { style: 'thin', color: { argb: 'FFD8B4FE' } },
          bottom: { style: 'thin', color: { argb: 'FFD8B4FE' } },
        };
      });

      weekTotalRowNumbers.push(currentRow);
      weekIndex++;
      weekStartRow = currentRow + 1;
    }

    currentRow++;
  }

  // Monthly Grand Total row
  const totalRow = sheet.getRow(currentRow);
  totalRow.height = 24;

  const totalRowFont = {
    name: 'Calibri',
    size: 11,
    bold: true,
    color: { argb: 'FF1F2937' },
  };
  const totalRowFill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFE5E7EB' }, // Light gray
  };

  totalRow.getCell('A').value = 'Month Total';
  totalRow.getCell('A').alignment = { vertical: 'middle', horizontal: 'center' };

  // SUM formulas for Month Total (sums all Week Total rows)
  const colLetters = ['B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];
  for (const col of colLetters) {
    totalRow.getCell(col).value = { formula: weekTotalRowNumbers.map(r => `${col}${r}`).join('+') };
  }

  // O is sum of all week total O's
  totalRow.getCell('O').value = { formula: weekTotalRowNumbers.map(r => `O${r}`).join('+') };
  // P holds the last-day running balance from calculateAccountsRunningBalances
  totalRow.getCell('P').value = report.monthTotals.accounts.outstanding_jobs_amount;

  // Style total row
  totalRow.eachCell((cell) => {
    cell.font = totalRowFont;
    cell.fill = totalRowFill;
    cell.border = {
      top: { style: 'thin' },
      bottom: { style: 'double' },
    };
  });

  // ==========================================
  // SHEET 2: Afternoon (reference)
  // ==========================================
  const morningSheet = workbook.addWorksheet('Afternoon (reference)', {
    views: [{ state: 'frozen', xSplit: 1, ySplit: 1 }],
  });

  morningSheet.columns = [
    { header: 'Date', key: 'date', width: 14 },
    { header: 'EXIM', key: 'exim', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'GST', key: 'gst', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Registration', key: 'registration', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'CRO', key: 'cro', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Accounts', key: 'accounts', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Marketing', key: 'marketing', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'EXIM Jobs', key: 'exim_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'GST Jobs', key: 'gst_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Registration Jobs', key: 'reg_jobs', width: 17, style: { numFmt: INTEGER_FORMAT } },
    { header: 'CRO Jobs', key: 'cro_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Marketing Jobs', key: 'mkt_jobs', width: 15, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc New (₹)', key: 'acc_new_amt', width: 16, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Acc Outstanding (₹)', key: 'acc_outstanding_amt', width: 18, style: { numFmt: CURRENCY_FORMAT } },
  ];

  const mHeaderRow = morningSheet.getRow(1);
  mHeaderRow.height = 24;
  mHeaderRow.eachCell((cell) => {
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF595959' }, // Gray header to denote reference only
    };
    cell.font = headerFont;
    cell.alignment = { vertical: 'middle', horizontal: 'center' };
  });

  // Index afternoon rows by date and section_id
  function toDateString(val) {
    if (typeof val === 'string') return val.substring(0, 10);
    const y = val.getFullYear();
    const m = String(val.getMonth() + 1).padStart(2, '0');
    const d = String(val.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  const morningEntryMap = new Map();
  if (Array.isArray(afternoonRows)) {
    for (const r of afternoonRows) {
      if (r.slot === 'AFTERNOON' || r.slot === 'MORNING') {
        const dStr = toDateString(r.entry_date);
        if (!morningEntryMap.has(dStr)) {
          morningEntryMap.set(dStr, new Map());
        }
        morningEntryMap.get(dStr).set(r.section_id, r);
      }
    }
  }

  for (let i = 0; i < numDays; i++) {
    const day = report.days[i];
    const row = morningSheet.getRow(i + 2);
    row.height = 20;

    row.getCell('A').value = day.isSunday ? `${day.date} (Sun)` : day.date;
    row.getCell('A').alignment = { vertical: 'middle', horizontal: 'center' };

    const mSecMap = morningEntryMap.get(day.date);
    if (mSecMap && mSecMap.size > 0) {
      let cIdx = 2;
      for (const sec of sections) {
        const ent = mSecMap.get(sec.id);
        row.getCell(cIdx++).value = ent && ent.amount !== null ? parseFloat(ent.amount) : 0;
      }
      for (const sec of sections) {
        const ent = mSecMap.get(sec.id);
        if (sec.count_type === 'SINGLE') {
          row.getCell(cIdx++).value = ent && ent.jobs_completed !== null ? ent.jobs_completed : 0;
        } else if (sec.count_type === 'TRIPLE' || sec.code === 'ACCOUNTS') {
          row.getCell(cIdx++).value = ent && ent.new_jobs_amount !== null ? parseFloat(ent.new_jobs_amount) : 0;
          row.getCell(cIdx++).value = ent && ent.outstanding_jobs_amount !== null ? parseFloat(ent.outstanding_jobs_amount) : 0;
        }
      }
    }
  }

  // Return generated buffer
  const buffer = await workbook.xlsx.writeBuffer();
  return buffer;
}

module.exports = {
  generateMonthlyExcelWorkbook,
};
