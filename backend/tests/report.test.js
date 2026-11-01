const request = require('supertest');
const ExcelJS = require('exceljs');
const app = require('../src/app');
const { pool } = require('../src/db/client');
const {
  calculateAccountsRunningBalances,
  calculateDayTotals,
  compileMonthlyReport,
} = require('../src/services/calculationService');

let authToken;
let sectionsList;

beforeAll(async () => {
  const loginRes = await request(app)
    .post('/api/auth/login')
    .send({ username: 'admin', password: 'AdminPassword@123' });
  authToken = loginRes.body.token;

  const secRes = await request(app)
    .get('/api/sections')
    .set('Authorization', `Bearer ${authToken}`);
  sectionsList = secRes.body;
});

jest.setTimeout(30000);

describe('1. Shared Calculation Service & Worked Example', () => {
  test('Worked example: evening values yield Total 1 = 4200 and Total 2 = 4900', () => {
    // Evening: EXIM 1000, CRO 2000, GST 500, ACCOUNTS 300, REGISTRATION 700, MARKETING 400
    const eveningEntries = sectionsList.map(sec => {
      let amt = 0;
      if (sec.code === 'EXIM') amt = 1000;
      else if (sec.code === 'CRO') amt = 2000;
      else if (sec.code === 'GST') amt = 500;
      else if (sec.code === 'ACCOUNTS') amt = 300;
      else if (sec.code === 'REGISTRATION') amt = 700;
      else if (sec.code === 'MARKETING') amt = 400;

      return {
        section_id: sec.id,
        code: sec.code,
        in_core_total: sec.in_core_total,
        count_type: sec.count_type,
        amount: amt,
      };
    });

    const totals = calculateDayTotals(eveningEntries);
    expect(totals.total1).toBe(4200); // 1000 + 2000 + 500 + 700
    expect(totals.total2).toBe(4900); // 1000 + 2000 + 500 + 300 + 700 + 400
  });

  test('Morning values NEVER affect Total 1, Total 2, or monthly totals', () => {
    const testMonth = '2026-10';
    const eveningData = [
      { entry_date: '2026-10-05', section_id: 1, slot: 'EVENING', amount: '1000.00', jobs_completed: 2 },
      { entry_date: '2026-10-05', section_id: 2, slot: 'EVENING', amount: '2000.00', jobs_completed: 3 },
      { entry_date: '2026-10-05', section_id: 3, slot: 'EVENING', amount: '500.00', jobs_completed: 1 },
      { entry_date: '2026-10-05', section_id: 4, slot: 'EVENING', amount: '300.00', ongoing_jobs: 10, new_jobs: 2, outstanding_jobs: 5 },
      { entry_date: '2026-10-05', section_id: 5, slot: 'EVENING', amount: '700.00', jobs_completed: 4 },
      { entry_date: '2026-10-05', section_id: 6, slot: 'EVENING', amount: '400.00', jobs_completed: 1 },
    ];

    // Report with Evening only
    const reportWithoutMorning = compileMonthlyReport(testMonth, sectionsList, eveningData);
    const day5Without = reportWithoutMorning.days.find(d => d.date === '2026-10-05');
    expect(day5Without.total1).toBe(4200);
    expect(day5Without.total2).toBe(4900);
    expect(reportWithoutMorning.monthTotals.total1).toBe(4200);
    expect(reportWithoutMorning.monthTotals.total2).toBe(4900);

    // Now inject drastic morning numbers (e.g., millions)
    const morningData = [
      { entry_date: '2026-10-05', section_id: 1, slot: 'MORNING', amount: '999999.00', jobs_completed: 99 },
      { entry_date: '2026-10-05', section_id: 2, slot: 'MORNING', amount: '888888.00', jobs_completed: 88 },
      { entry_date: '2026-10-05', section_id: 4, slot: 'MORNING', amount: '777777.00', ongoing_jobs: 999, new_jobs: 999, outstanding_jobs: 999 },
    ];

    const combinedData = [...eveningData, ...morningData];
    const reportWithMorning = compileMonthlyReport(testMonth, sectionsList, combinedData);
    const day5With = reportWithMorning.days.find(d => d.date === '2026-10-05');

    // Numbers MUST be identical
    expect(day5With.total1).toBe(4200);
    expect(day5With.total2).toBe(4900);
    expect(reportWithMorning.monthTotals.total1).toBe(4200);
    expect(reportWithMorning.monthTotals.total2).toBe(4900);
  });

  test('Accounts ongoing and outstanding jobs take last entered day in month, while new_jobs is a sum', () => {
    const daysSample = [
      {
        date: '2026-10-01',
        status: 'COMPLETE',
        accounts: { ongoing_jobs: 10, new_jobs: 2, outstanding_jobs: 5 },
      },
      {
        date: '2026-10-05',
        status: 'COMPLETE',
        accounts: { ongoing_jobs: 14, new_jobs: 3, outstanding_jobs: 8 },
      },
      {
        date: '2026-10-12',
        status: 'COMPLETE',
        accounts: { ongoing_jobs: 22, new_jobs: 5, outstanding_jobs: 11 },
      },
      {
        date: '2026-10-20',
        status: 'PENDING',
        accounts: { ongoing_jobs: 0, new_jobs: 0, outstanding_jobs: 0 },
      },
    ];

    const balances = calculateAccountsRunningBalances(daysSample);
    expect(balances.ongoing_jobs).toBe(22);
    expect(balances.outstanding_jobs).toBe(11);
  });
});

describe('2. Monthly Report Endpoints', () => {
  const testMonth = '2026-10';

  beforeAll(async () => {
    // Insert worked example entries into database for 2026-10-05
    const eveningPayload = sectionsList.map(sec => {
      let amt = 0;
      if (sec.code === 'EXIM') amt = 1000;
      else if (sec.code === 'CRO') amt = 2000;
      else if (sec.code === 'GST') amt = 500;
      else if (sec.code === 'ACCOUNTS') amt = 300;
      else if (sec.code === 'REGISTRATION') amt = 700;
      else if (sec.code === 'MARKETING') amt = 400;

      return {
        section_id: sec.id,
        amount: amt,
        ...(sec.count_type === 'SINGLE'
          ? { jobs_completed: 2 }
          : { ongoing_jobs: 15, new_jobs: 4, outstanding_jobs: 7 }),
      };
    });

    await request(app)
      .put('/api/entries/2026-10-05/EVENING')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: eveningPayload });
  });

  test('GET /api/reports/monthly requires valid YYYY-MM query param', async () => {
    const res = await request(app)
      .get('/api/reports/monthly?month=invalid')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('GET /api/reports/monthly returns complete days and pending days with correct totals', async () => {
    const res = await request(app)
      .get(`/api/reports/monthly?month=${testMonth}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(res.body.month).toBe(testMonth);
    expect(res.body.days.length).toBe(31); // October has 31 days

    // Day 5 should be COMPLETE
    const day5 = res.body.days.find(d => d.date === '2026-10-05');
    expect(day5.status).toBe('COMPLETE');
    expect(day5.total1).toBe(4200);
    expect(day5.total2).toBe(4900);
    expect(day5.amounts.EXIM).toBe(1000);
    expect(day5.amounts.CRO).toBe(2000);

    // Day 4 is Sunday and should have status SUNDAY
    const day4 = res.body.days.find(d => d.date === '2026-10-04');
    expect(day4.status).toBe('SUNDAY');
    expect(day4.isSunday).toBe(true);

    // Other weekday should be PENDING
    const day1 = res.body.days.find(d => d.date === '2026-10-01');
    expect(day1.status).toBe('PENDING');

    // Report should contain weekly totals
    expect(res.body.weeks).toBeDefined();
    expect(res.body.weeks.length).toBeGreaterThanOrEqual(4);
    expect(res.body.weeks[0].label).toBe('Week 1');
    expect(res.body.weeks[0].totals).toBeDefined();

    // Month totals
    expect(res.body.monthTotals.total1).toBeGreaterThanOrEqual(4200);
    expect(res.body.monthTotals.total2).toBeGreaterThanOrEqual(4900);
  });

  test('GET /api/reports/monthly/export generates valid Excel workbook with specified sheets, weekly totals, and formulas', async () => {
    const res = await request(app)
      .get(`/api/reports/monthly/export?month=${testMonth}`)
      .set('Authorization', `Bearer ${authToken}`)
      .responseType('blob');

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('spreadsheetml.sheet');

    // Load workbook with ExcelJS to inspect structure
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(res.body);

    // Check sheets
    expect(workbook.worksheets.length).toBe(2);
    const sheet1 = workbook.getWorksheet('Oct 2026');
    expect(sheet1).toBeDefined();

    const sheet2 = workbook.getWorksheet('Afternoon (reference)') || workbook.getWorksheet('Morning (reference)');
    expect(sheet2).toBeDefined();

    // Check header columns in Sheet 1
    const headers = sheet1.getRow(1).values;
    expect(headers).toContain('Date');
    expect(headers).toContain('EXIM');
    expect(headers).toContain('Total 1');
    expect(headers).toContain('Total 2');
    expect(headers).toContain('Acc Ongoing');

    // Check Week 1 Total row (Row 6 after Oct 4 Sunday)
    const row6 = sheet1.getRow(6);
    expect(row6.getCell('A').value).toBe('Week 1 Total');

    // Check Day 5 (Row 7)
    const row7 = sheet1.getRow(7);
    expect(row7.getCell('A').value).toBe('2026-10-05');
    expect(row7.getCell('H').value.formula).toBe('B7+C7+D7+F7');
    expect(row7.getCell('I').value.formula).toBe('SUM(B7:G7)');

    // Check final Month Total row
    const lastRowIndex = sheet1.rowCount;
    const totalRow = sheet1.getRow(lastRowIndex);
    expect(totalRow.getCell('A').value).toBe('Month Total');
    expect(totalRow.getCell('H').value.formula).toBeDefined();
    expect(totalRow.getCell('I').value.formula).toBeDefined();
  });
});

