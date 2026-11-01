const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/db/client');

let authToken;
let sectionsList;
const targetDate = '2026-09-10';

beforeAll(async () => {
  const loginRes = await request(app)
    .post('/api/auth/login')
    .send({ username: 'admin', password: 'AdminPassword@123' });
  authToken = loginRes.body.token;

  const secRes = await request(app)
    .get('/api/sections')
    .set('Authorization', `Bearer ${authToken}`);
  sectionsList = secRes.body;

  // Clean test targetDate entries to ensure test isolation
  await pool.query('DELETE FROM entry_audit WHERE entry_date = $1', [targetDate]);
  await pool.query('DELETE FROM daily_entries WHERE entry_date = $1', [targetDate]);
});

jest.setTimeout(30000);

describe('Phase 6: Audit, History & Dashboard API Tests', () => {
  const targetDate = '2026-09-10';

  test('PUT /api/entries creates an audit row when modifying existing entries', async () => {
    // 1. Initial insert of entries for 2026-09-10
    const initialPayload = sectionsList.map(sec => ({
      section_id: sec.id,
      amount: 1000.00,
      ...(sec.count_type === 'SINGLE'
        ? { jobs_completed: 5 }
        : { ongoing_jobs: 10, new_jobs: 2, outstanding_jobs: 6 }),
    }));

    await request(app)
      .put(`/api/entries/${targetDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: initialPayload });

    // Verify initial audit rows count for this date/slot is 0
    const histBeforeRes = await request(app)
      .get(`/api/entries/${targetDate}/EVENING/history`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(histBeforeRes.status).toBe(200);
    expect(histBeforeRes.body.length).toBe(0);

    // 2. Perform an EDIT on 2026-09-10 (change EXIM amount to 2500 and jobs to 12)
    const eximSec = sectionsList.find(s => s.code === 'EXIM');
    const updatedPayload = sectionsList.map(sec => {
      if (sec.code === 'EXIM') {
        return {
          section_id: sec.id,
          amount: 2500.00,
          jobs_completed: 12,
        };
      }
      return {
        section_id: sec.id,
        amount: 1000.00,
        ...(sec.count_type === 'SINGLE'
          ? { jobs_completed: 5 }
          : { ongoing_jobs: 10, new_jobs: 2, outstanding_jobs: 6 }),
      };
    });

    const updateRes = await request(app)
      .put(`/api/entries/${targetDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: updatedPayload });
    expect(updateRes.status).toBe(200);

    // 3. Verify audit row was generated via both specific slot and day-level history endpoint
    const histAfterRes = await request(app)
      .get(`/api/entries/${targetDate}/EVENING/history`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(histAfterRes.status).toBe(200);
    expect(histAfterRes.body.length).toBeGreaterThanOrEqual(1);

    // Also verify GET /api/entries/:date/history returns all day audits
    const dayHistRes = await request(app)
      .get(`/api/entries/${targetDate}/history`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(dayHistRes.status).toBe(200);
    expect(dayHistRes.body.length).toBeGreaterThanOrEqual(1);

    const auditItem = histAfterRes.body.find(a => a.section_id === eximSec.id);
    expect(auditItem).toBeDefined();
    expect(auditItem.section_code).toBe('EXIM');
    expect(auditItem.changed_by_username).toBe('admin');
    expect(auditItem.old_values.amount).toBe('1000.00');
    expect(auditItem.old_values.jobs_completed).toBe(5);
    expect(auditItem.new_values.amount).toBe('2500.00');
    expect(auditItem.new_values.jobs_completed).toBe(12);
  });

  test('GET /api/entries returns month-wise history and respects filters (all, pending, edited)', async () => {
    // Test filter=all
    const allRes = await request(app)
      .get('/api/entries?month=2026-09&filter=all')
      .set('Authorization', `Bearer ${authToken}`);

    expect(allRes.status).toBe(200);
    expect(allRes.body.entries.length).toBe(30); // September has 30 days
    // Ascending chronological order (day 1 to last day)
    expect(allRes.body.entries[0].date).toBe('2026-09-01');
    expect(allRes.body.entries[allRes.body.entries.length - 1].date).toBe('2026-09-30');

    // Test filter=edited (must include 2026-09-10)
    const editedRes = await request(app)
      .get('/api/entries?month=2026-09&filter=edited')
      .set('Authorization', `Bearer ${authToken}`);

    expect(editedRes.status).toBe(200);
    expect(editedRes.body.entries.length).toBeGreaterThanOrEqual(1);
    const day10 = editedRes.body.entries.find(e => e.date === targetDate);
    expect(day10).toBeDefined();
    expect(day10.isEdited).toBe(true);
    expect(day10.lastUpdatedBy).toBe('admin');

    // Test filter=pending
    const pendingRes = await request(app)
      .get('/api/entries?month=2026-09&filter=pending')
      .set('Authorization', `Bearer ${authToken}`);

    expect(pendingRes.status).toBe(200);
    expect(pendingRes.body.entries.every(e => e.isPending === true)).toBe(true);
    // Day 10 should not be in pending since evening entry was made
    expect(pendingRes.body.entries.some(e => e.date === targetDate)).toBe(false);
  });

  test('GET /api/dashboard returns correct dashboard aggregations, trend, and previous-month comparison', async () => {
    const res = await request(app)
      .get('/api/dashboard?month=2026-10')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    const data = res.body;

    // Structure checks
    expect(data.month).toBe('2026-10');
    expect(data).toHaveProperty('totals');
    expect(data.totals).toHaveProperty('total1');
    expect(data.totals).toHaveProperty('total2');

    // Section breakdown
    expect(data.sectionBreakdown.length).toBe(6);
    expect(data.sectionBreakdown[0]).toHaveProperty('percentageShare');

    // Accounts card
    expect(data.accounts).toHaveProperty('ongoing');
    expect(data.accounts).toHaveProperty('newJobs');
    expect(data.accounts).toHaveProperty('outstanding');

    // Daily trend
    expect(data.dailyTrend.length).toBe(31); // October has 31 days
    expect(data.dailyTrend[0]).toHaveProperty('total1');
    expect(data.dailyTrend[0]).toHaveProperty('total2');

    // Today status
    expect(data.today).toHaveProperty('date');
    expect(data.today).toHaveProperty('morningDone');
    expect(data.today).toHaveProperty('eveningDone');

    // Pending days count
    expect(typeof data.pendingDays).toBe('number');

    // Previous month comparison
    expect(data.previousMonth.month).toBe('2026-09');
    expect(data.previousMonth).toHaveProperty('total1');
    expect(data.previousMonth).toHaveProperty('total2');
    expect(data.previousMonth).toHaveProperty('diffTotal1');
    expect(data.previousMonth).toHaveProperty('diffTotal2');
  });
});

