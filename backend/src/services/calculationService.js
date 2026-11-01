/**
 * Shared Calculation Service
 * 
 * Used by both the Monthly Report API endpoint and the Excel export service
 * to ensure numbers and totals always match exactly.
 * 
 * Core Rules:
 * 1. ONLY EVENING entries are used in all totals and reports. Morning data is reference only.
 * 2. Total 1 = sum of amounts where in_core_total === true (CRO + GST + REGISTRATION + EXIM).
 * 3. Total 2 = sum of all section amounts.
 * 4. ACCOUNTS outstanding_jobs_amount is a running balance, resolved by taking
 *    the value on the LAST day of that month that has an evening entry.
 *    ACCOUNTS new_jobs_amount is summed across all completed days.
 */

const { isSunday } = require('../utils/dateUtils');

/**
 * Determines Accounts running balance for a given month or week.
 * Returns the outstanding_jobs_amount from the last day in the set
 * that has an evening entry for ACCOUNTS.
 * 
 * @param {Array} eveningDays - Array of day objects with date and section entries, ordered chronologically.
 * @returns {{ outstanding_jobs_amount: number, outstanding_jobs: number, ongoing_jobs: number }}
 */
function calculateAccountsRunningBalances(eveningDays) {
  let lastOutstandingAmount = 0;
  let lastOutstandingJobs = 0;

  for (const day of eveningDays) {
    if (day.status === 'COMPLETE' && day.accounts) {
      if (day.accounts.outstanding_jobs_amount !== null && day.accounts.outstanding_jobs_amount !== undefined) {
        lastOutstandingAmount = day.accounts.outstanding_jobs_amount;
      }
      if (day.accounts.outstanding_jobs !== null && day.accounts.outstanding_jobs !== undefined) {
        lastOutstandingJobs = day.accounts.outstanding_jobs;
      }
    }
  }

  return {
    outstanding_jobs_amount: lastOutstandingAmount,
    outstanding_jobs: lastOutstandingJobs,
    ongoing_jobs: 0,
  };
}

/**
 * Computes Total 1 and Total 2 for a single day given evening section entries.
 * Total 1 = sum of amounts where in_core_total === true.
 * Total 2 = sum of all section amounts.
 * 
 * @param {Array} sectionEntries - Array of entries for each section.
 * @returns {{ total1: number, total2: number }}
 */
function calculateDayTotals(sectionEntries) {
  let total1 = 0;
  let total2 = 0;

  for (const entry of sectionEntries) {
    const amount = parseFloat(entry.amount || '0');
    if (!isNaN(amount)) {
      total2 += amount;
      if (entry.in_core_total) {
        total1 += amount;
      }
    }
  }

  return {
    total1: Math.round(total1 * 100) / 100,
    total2: Math.round(total2 * 100) / 100,
  };
}

/**
 * Compiles a full calendar month report from raw daily_entries rows.
 * 
 * @param {string} yearMonth - Format 'YYYY-MM'
 * @param {Array} sections - Array of sections ordered by sort_order
 * @param {Array} dbRows - Raw entries rows from database for the month
 * @returns {Object} { month, days, monthTotals }
 */
function compileMonthlyReport(yearMonth, sections, dbRows) {
  const [yearStr, monthStr] = yearMonth.split('-');
  const year = parseInt(yearStr, 10);
  const month = parseInt(monthStr, 10);

  const daysInMonth = new Date(year, month, 0).getDate();

  function toDateString(val) {
    if (typeof val === 'string') {
      return val.substring(0, 10);
    }
    const y = val.getFullYear();
    const m = String(val.getMonth() + 1).padStart(2, '0');
    const d = String(val.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  const entryMap = new Map();
  for (const row of dbRows) {
    const dateStr = toDateString(row.entry_date);

    const key = `${dateStr}_${row.slot}`;
    if (!entryMap.has(key)) {
      entryMap.set(key, new Map());
    }
    entryMap.get(key).set(row.section_id, row);
  }

  const days = [];
  const sectionAmountSums = {};
  const sectionJobSums = {};

  for (const sec of sections) {
    sectionAmountSums[sec.code] = 0;
    sectionJobSums[sec.code] = 0;
  }
  let accountsNewJobsAmountSum = 0;

  // Build each calendar day
  for (let d = 1; d <= daysInMonth; d++) {
    const dayStr = String(d).padStart(2, '0');
    const fullDate = `${yearMonth}-${dayStr}`;

    const eveningKey = `${fullDate}_EVENING`;
    const eveningMap = entryMap.get(eveningKey);

    // A day is COMPLETE if it has evening entries for all sections
    const hasEveningEntry = !!(eveningMap && eveningMap.size > 0);

    const amounts = {};
    const jobs = {};
    let accountsData = {
      new_jobs_amount: 0,
      outstanding_jobs_amount: 0,
      new_jobs: 0,
      outstanding_jobs: 0,
      ongoing_jobs: 0,
    };
    const daySectionList = [];

    for (const sec of sections) {
      const entry = eveningMap ? eveningMap.get(sec.id) : null;
      const amt = entry && entry.amount !== null ? parseFloat(entry.amount) : 0;
      amounts[sec.code] = amt;

      if (sec.count_type === 'SINGLE') {
        const jc = entry && entry.jobs_completed !== null ? entry.jobs_completed : 0;
        jobs[sec.code] = jc;
      } else if (sec.count_type === 'TRIPLE' || sec.code === 'ACCOUNTS') {
        const nja = entry && entry.new_jobs_amount !== null ? parseFloat(entry.new_jobs_amount) : (amt || 0);
        const oja = entry && entry.outstanding_jobs_amount !== null ? parseFloat(entry.outstanding_jobs_amount) : 0;
        accountsData = {
          new_jobs_amount: nja,
          outstanding_jobs_amount: oja,
          new_jobs: 0,
          outstanding_jobs: 0,
          ongoing_jobs: 0,
        };
      }

      daySectionList.push({
        section_id: sec.id,
        code: sec.code,
        in_core_total: sec.in_core_total,
        count_type: sec.count_type,
        amount: amt,
      });
    }

    let total1 = 0;
    let total2 = 0;

    if (hasEveningEntry) {
      const dailyTotals = calculateDayTotals(daySectionList);
      total1 = dailyTotals.total1;
      total2 = dailyTotals.total2;

      // Accumulate monthly sums only from entered evening data
      for (const sec of sections) {
        sectionAmountSums[sec.code] += amounts[sec.code];
        if (sec.count_type === 'SINGLE') {
          sectionJobSums[sec.code] += jobs[sec.code];
        }
      }
      accountsNewJobsAmountSum += accountsData.new_jobs_amount;
    }

    const isSun = isSunday(fullDate);
    const dayStatus = hasEveningEntry ? 'COMPLETE' : (isSun ? 'SUNDAY' : 'PENDING');

    days.push({
      date: fullDate,
      status: dayStatus,
      isSunday: isSun,
      amounts,
      jobs,
      accounts: accountsData,
      total1,
      total2,
    });
  }

  // Calculate weekly totals
  const weeks = [];
  let currentWeekDays = [];

  for (let i = 0; i < days.length; i++) {
    const day = days[i];
    currentWeekDays.push(day);

    const isLastDay = i === days.length - 1;
    if (day.isSunday || isLastDay) {
      let wTotal1 = 0;
      let wTotal2 = 0;
      const wAmounts = {};
      const wJobs = {};
      for (const sec of sections) {
        wAmounts[sec.code] = 0;
        wJobs[sec.code] = 0;
      }
      let wNewJobsAmount = 0;

      for (const wd of currentWeekDays) {
        if (wd.status === 'COMPLETE') {
          wTotal1 += wd.total1;
          wTotal2 += wd.total2;
          for (const sec of sections) {
            wAmounts[sec.code] += wd.amounts[sec.code] || 0;
            if (sec.count_type === 'SINGLE') {
              wJobs[sec.code] += wd.jobs[sec.code] || 0;
            }
          }
          wNewJobsAmount += wd.accounts.new_jobs_amount || 0;
        }
      }

      // Round sums
      wTotal1 = Math.round(wTotal1 * 100) / 100;
      wTotal2 = Math.round(wTotal2 * 100) / 100;
      for (const sec of sections) {
        wAmounts[sec.code] = Math.round(wAmounts[sec.code] * 100) / 100;
      }

      const wAccountsRunning = calculateAccountsRunningBalances(currentWeekDays);

      weeks.push({
        weekNumber: weeks.length + 1,
        label: `Week ${weeks.length + 1}`,
        startDate: currentWeekDays[0].date,
        endDate: currentWeekDays[currentWeekDays.length - 1].date,
        dayCount: currentWeekDays.length,
        totals: {
          total1: wTotal1,
          total2: wTotal2,
          amounts: wAmounts,
          jobs: wJobs,
          accounts: {
            new_jobs_amount: Math.round(wNewJobsAmount * 100) / 100,
            outstanding_jobs_amount: wAccountsRunning.outstanding_jobs_amount,
            new_jobs: 0,
            outstanding_jobs: 0,
            ongoing_jobs: 0,
          },
        },
      });

      currentWeekDays = [];
    }
  }

  // Calculate Accounts running balance for the month
  const accountsRunningBalance = calculateAccountsRunningBalances(days);

  // Calculate grand monthly totals
  let monthTotal1 = 0;
  let monthTotal2 = 0;
  for (const sec of sections) {
    const sum = Math.round(sectionAmountSums[sec.code] * 100) / 100;
    sectionAmountSums[sec.code] = sum;
    monthTotal2 += sum;
    if (sec.in_core_total) {
      monthTotal1 += sum;
    }
  }
  monthTotal1 = Math.round(monthTotal1 * 100) / 100;
  monthTotal2 = Math.round(monthTotal2 * 100) / 100;

  const monthTotals = {
    total1: monthTotal1,
    total2: monthTotal2,
    amounts: sectionAmountSums,
    jobs: sectionJobSums,
    accounts: {
      new_jobs_amount: Math.round(accountsNewJobsAmountSum * 100) / 100,
      outstanding_jobs_amount: accountsRunningBalance.outstanding_jobs_amount,
      new_jobs: 0,
      outstanding_jobs: 0,
      ongoing_jobs: 0,
    },
  };

  return {
    month: yearMonth,
    days,
    weeks,
    monthTotals,
  };
}

module.exports = {
  calculateAccountsRunningBalances,
  calculateDayTotals,
  compileMonthlyReport,
};
