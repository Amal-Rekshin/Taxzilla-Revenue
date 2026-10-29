const ExcelJS = require('exceljs');
const { compileMonthlyReport } = require('./calculationService');

function getMonthSheetName(yearMonth) {
  const [year, month] = yearMonth.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, 1));
  const monthName = date.toLocaleString('en-US', { month: 'short', timeZone: 'UTC' });
  return `${monthName} ${year}`;
}

/**
 * Generate Excel workbook for a selected month using ExcelJS
 * 
 * @param {string} yearMonth - Format 'YYYY-MM'
 * @param {Array} sections - Ordered list of sections
 * @param {Array} dbRows - All raw entries for the month (both MORNING and EVENING)
 * @returns {Promise<ExcelJS.Workbook>}
 */
async function generateMonthlyExcelWorkbook(yearMonth, sections, dbRows) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Daily Revenue Tracker';
  workbook.created = new Date();

  // 1. Calculate compiled report using shared calculation service
  const report = compileMonthlyReport(yearMonth, sections, dbRows);

  // Currency format for Rupee
  const CURRENCY_FORMAT = '[$₹-en-IN] #,##0.00';
  const INTEGER_FORMAT = '#,##0';

  const headerFill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF753C8D' }, // Brand Purple #753C8D
  };
  const headerFont = {
    name: 'Calibri',
    size: 11,
    bold: true,
    color: { argb: 'FFFFFFFF' },
  };
  const totalRowFont = {
    name: 'Calibri',
    size: 11,
    bold: true,
  };
  const totalRowFill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFF2F4F7' },
  };

  // ==========================================
  // SHEET 1: Evening Data (Active Reporting)
  // ==========================================
  const sheetName = getMonthSheetName(yearMonth);
  const sheet = workbook.addWorksheet(sheetName, {
    views: [{ state: 'frozen', xSplit: 1, ySplit: 1 }],
  });

  // Columns A through Q
  sheet.columns = [
    { header: 'Date', key: 'date', width: 14 },
    { header: 'EXIM', key: 'exim', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'CRO', key: 'cro', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'GST', key: 'gst', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Accounts', key: 'accounts', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Registration', key: 'registration', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Marketing', key: 'marketing', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Total 1', key: 'total1', width: 16, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Total 2', key: 'total2', width: 16, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'EXIM Jobs', key: 'exim_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'CRO Jobs', key: 'cro_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'GST Jobs', key: 'gst_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Registration Jobs', key: 'reg_jobs', width: 17, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Marketing Jobs', key: 'mkt_jobs', width: 15, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc Ongoing', key: 'acc_ongoing', width: 14, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc New', key: 'acc_new', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc Outstanding', key: 'acc_outstanding', width: 16, style: { numFmt: INTEGER_FORMAT } },
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
      row.getCell('C').value = day.amounts.CRO || 0;
      row.getCell('D').value = day.amounts.GST || 0;
      row.getCell('E').value = day.amounts.ACCOUNTS || 0;
      row.getCell('F').value = day.amounts.REGISTRATION || 0;
      row.getCell('G').value = day.amounts.MARKETING || 0;

      // Row formulas as strictly specified:
      row.getCell('H').value = { formula: `B${currentRow}+C${currentRow}+D${currentRow}+F${currentRow}`, result: day.total1 };
      row.getCell('I').value = { formula: `SUM(B${currentRow}:G${currentRow})`, result: day.total2 };

      row.getCell('J').value = day.jobs.EXIM || 0;
      row.getCell('K').value = day.jobs.CRO || 0;
      row.getCell('L').value = day.jobs.GST || 0;
      row.getCell('M').value = day.jobs.REGISTRATION || 0;
      row.getCell('N').value = day.jobs.MARKETING || 0;

      row.getCell('O').value = day.accounts.ongoing_jobs || 0;
      row.getCell('P').value = day.accounts.new_jobs || 0;
      row.getCell('Q').value = day.accounts.outstanding_jobs || 0;
    } else {
      // Pending or Sunday: cells are blank for financial columns
      for (let c = 2; c <= 17; c++) {
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

      // Accounts: O & Q are static running balances at week end, P is sum
      if (currentWeek) {
        weekTotalRow.getCell('O').value = currentWeek.totals.accounts.ongoing_jobs;
        weekTotalRow.getCell('P').value = { formula: `SUM(P${weekStartRow}:P${weekEndRow})` };
        weekTotalRow.getCell('Q').value = currentWeek.totals.accounts.outstanding_jobs;
      }

      // Style week total row
      weekTotalRow.eachCell((cell) => {
        cell.font = weekTotalRowFont;
        cell.fill = weekTotalRowFill;
        cell.border = {
          top: { style: 'thin' },
          bottom: { style: 'thin' },
        };
      });

      weekTotalRowNumbers.push(currentRow);
      weekIndex++;
      weekStartRow = currentRow + 1;
    }

    currentRow++;
  }

  // Final "Month Total" row
  const totalRow = sheet.getRow(currentRow);
  totalRow.height = 24;

  totalRow.getCell('A').value = 'Month Total';
  totalRow.getCell('A').alignment = { vertical: 'middle', horizontal: 'center' };

  // SUM formulas for Month Total (sums all Week Total rows)
  const colLetters = ['B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];
  for (const col of colLetters) {
    totalRow.getCell(col).value = { formula: weekTotalRowNumbers.map(r => `${col}${r}`).join('+') };
  }

  // O and Q hold the last-day static values from calculateAccountsRunningBalances
  totalRow.getCell('O').value = report.monthTotals.accounts.ongoing_jobs;
  // P is sum of week new jobs
  totalRow.getCell('P').value = { formula: weekTotalRowNumbers.map(r => `P${r}`).join('+') };
  totalRow.getCell('Q').value = report.monthTotals.accounts.outstanding_jobs;

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
    { header: 'CRO', key: 'cro', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'GST', key: 'gst', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Accounts', key: 'accounts', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Registration', key: 'registration', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'Marketing', key: 'marketing', width: 15, style: { numFmt: CURRENCY_FORMAT } },
    { header: 'EXIM Jobs', key: 'exim_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'CRO Jobs', key: 'cro_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'GST Jobs', key: 'gst_jobs', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Registration Jobs', key: 'reg_jobs', width: 17, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Marketing Jobs', key: 'mkt_jobs', width: 15, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc Ongoing', key: 'acc_ongoing', width: 14, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc New', key: 'acc_new', width: 13, style: { numFmt: INTEGER_FORMAT } },
    { header: 'Acc Outstanding', key: 'acc_outstanding', width: 16, style: { numFmt: INTEGER_FORMAT } },
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

  // Map afternoon entries
  const morningMap = new Map();
  for (const row of dbRows) {
    if (row.slot === 'MORNING' || row.slot === 'AFTERNOON') {
      const dateStr = typeof row.entry_date === 'string'
        ? row.entry_date.substring(0, 10)
        : `${row.entry_date.getFullYear()}-${String(row.entry_date.getMonth() + 1).padStart(2, '0')}-${String(row.entry_date.getDate()).padStart(2, '0')}`;
      if (!morningMap.has(dateStr)) {
        morningMap.set(dateStr, new Map());
      }
      morningMap.get(dateStr).set(row.section_id, row);
    }
  }

  for (let i = 0; i < numDays; i++) {
    const day = report.days[i];
    const r = i + 2;
    const row = morningSheet.getRow(r);
    row.height = 20;

    row.getCell('A').value = day.date;
    row.getCell('A').alignment = { vertical: 'middle', horizontal: 'center' };

    const mEntries = morningMap.get(day.date);
    if (mEntries) {
      for (const sec of sections) {
        const ent = mEntries.get(sec.id);
        const amt = ent && ent.amount !== null ? parseFloat(ent.amount) : 0;
        if (sec.code === 'EXIM') row.getCell('B').value = amt;
        if (sec.code === 'CRO') row.getCell('C').value = amt;
        if (sec.code === 'GST') row.getCell('D').value = amt;
        if (sec.code === 'ACCOUNTS') row.getCell('E').value = amt;
        if (sec.code === 'REGISTRATION') row.getCell('F').value = amt;
        if (sec.code === 'MARKETING') row.getCell('G').value = amt;

        if (sec.count_type === 'SINGLE') {
          const jc = ent && ent.jobs_completed !== null ? ent.jobs_completed : 0;
          if (sec.code === 'EXIM') row.getCell('H').value = jc;
          if (sec.code === 'CRO') row.getCell('I').value = jc;
          if (sec.code === 'GST') row.getCell('J').value = jc;
          if (sec.code === 'REGISTRATION') row.getCell('K').value = jc;
          if (sec.code === 'MARKETING') row.getCell('L').value = jc;
        } else if (sec.count_type === 'TRIPLE') {
          row.getCell('M').value = ent && ent.ongoing_jobs !== null ? ent.ongoing_jobs : 0;
          row.getCell('N').value = ent && ent.new_jobs !== null ? ent.new_jobs : 0;
          row.getCell('O').value = ent && ent.outstanding_jobs !== null ? ent.outstanding_jobs : 0;
        }
      }
    }
  }

  return workbook;
}

module.exports = {
  generateMonthlyExcelWorkbook,
  getMonthSheetName,
};
