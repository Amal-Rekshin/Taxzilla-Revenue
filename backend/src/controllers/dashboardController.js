const { query } = require('../db/client');
const { getAllSections } = require('../services/sectionService');
const { compileMonthlyReport } = require('../services/calculationService');
const { fetchEntriesForMonth, validateMonthParam } = require('./reportController');
const { getTodayInKolkata } = require('../utils/dateUtils');

function getPreviousMonth(yearMonth) {
  const [yearStr, monthStr] = yearMonth.split('-');
  let year = parseInt(yearStr, 10);
  let month = parseInt(monthStr, 10) - 1;
  if (month === 0) {
    month = 12;
    year -= 1;
  }
  return `${year}-${String(month).padStart(2, '0')}`;
}

async function getDashboard(req, res, next) {
  try {
    const { month } = req.query;
    validateMonthParam(month);

    const sections = await getAllSections();
    const today = getTodayInKolkata();

    // 1. Fetch current month and previous month data
    const prevMonth = getPreviousMonth(month);
    const [currentRows, prevRows] = await Promise.all([
      fetchEntriesForMonth(month),
      fetchEntriesForMonth(prevMonth),
    ]);

    const currentReport = compileMonthlyReport(month, sections, currentRows);
    const prevReport = compileMonthlyReport(prevMonth, sections, prevRows);

    // 2. Summary cards (Total 1 and Total 2 from evening data only)
    const totals = {
      total1: currentReport.monthTotals.total1,
      total2: currentReport.monthTotals.total2,
    };

    // 3. Section breakdown
    const totalRevenue = currentReport.monthTotals.total2;
    const sectionBreakdown = sections.map((sec) => {
      const amount = currentReport.monthTotals.amounts[sec.code] || 0;
      const jobs = sec.count_type === 'SINGLE'
        ? (currentReport.monthTotals.jobs[sec.code] || 0)
        : currentReport.monthTotals.accounts.new_jobs;

      const percentageShare = totalRevenue > 0
        ? parseFloat(((amount / totalRevenue) * 100).toFixed(2))
        : 0;

      return {
        code: sec.code,
        name: sec.name,
        in_core_total: sec.in_core_total,
        count_type: sec.count_type,
        amount,
        jobs,
        percentageShare,
      };
    });

    // 4. Accounts card
    const accounts = {
      newJobsAmount: currentReport.monthTotals.accounts.new_jobs_amount || 0,
      outstandingAmount: currentReport.monthTotals.accounts.outstanding_jobs_amount || 0,
      ongoing: 0,
      newJobs: 0,
      outstanding: 0,
    };

    // 5. Daily trend chart (Total 1 and Total 2 for each calendar day)
    const dailyTrend = currentReport.days.map((d) => ({
      date: d.date,
      total1: d.total1,
      total2: d.total2,
      status: d.status,
    }));

    // 6. Today's status (Morning entered? Evening entered?)
    const todaySql = `
      SELECT slot, COUNT(id) as count
      FROM daily_entries
      WHERE entry_date = $1
      GROUP BY slot;
    `;
    const todayRes = await query(todaySql, [today]);
    let morningDone = false;
    let eveningDone = false;
    for (const r of todayRes.rows) {
      if ((r.slot === 'MORNING' || r.slot === 'AFTERNOON') && parseInt(r.count, 10) > 0) morningDone = true;
      if (r.slot === 'EVENING' && parseInt(r.count, 10) > 0) eveningDone = true;
    }

    const todayStatus = {
      date: today,
      morningDone,
      afternoonDone: morningDone,
      eveningDone,
    };

    // 7. Pending days count for the month (days with no evening entry, up to today, excluding Sundays)
    let pendingDaysCount = 0;
    for (const d of currentReport.days) {
      if (d.status === 'PENDING' && d.date <= today && !d.isSunday) {
        pendingDaysCount++;
      }
    }

    // 8. Comparison with the previous month
    const curT1 = currentReport.monthTotals.total1;
    const curT2 = currentReport.monthTotals.total2;
    const prevT1 = prevReport.monthTotals.total1;
    const prevT2 = prevReport.monthTotals.total2;

    const diffT1 = Math.round((curT1 - prevT1) * 100) / 100;
    const diffT2 = Math.round((curT2 - prevT2) * 100) / 100;

    const pctT1 = prevT1 > 0 ? parseFloat(((diffT1 / prevT1) * 100).toFixed(2)) : null;
    const pctT2 = prevT2 > 0 ? parseFloat(((diffT2 / prevT2) * 100).toFixed(2)) : null;

    const previousMonthComparison = {
      month: prevMonth,
      total1: prevT1,
      total2: prevT2,
      diffTotal1: diffT1,
      diffTotal2: diffT2,
      percentageChangeTotal1: pctT1,
      percentageChangeTotal2: pctT2,
    };

    res.json({
      month,
      totals,
      sectionBreakdown,
      accounts,
      dailyTrend,
      today: todayStatus,
      pendingDays: pendingDaysCount,
      previousMonth: previousMonthComparison,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getDashboard,
  getPreviousMonth,
};

