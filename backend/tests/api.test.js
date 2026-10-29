const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/db/client');
const { getTodayInKolkata } = require('../src/utils/dateUtils');

let authToken;
let sectionsList;

beforeAll(async () => {
  // Login as admin to get auth token
  const res = await request(app)
    .post('/api/auth/login')
    .send({
      username: 'admin',
      password: 'AdminPassword@123',
    });
  expect(res.status).toBe(200);
  expect(res.body).toHaveProperty('token');
  authToken = res.body.token;

  // Retrieve sections
  const secRes = await request(app)
    .get('/api/sections')
    .set('Authorization', `Bearer ${authToken}`);
  expect(secRes.status).toBe(200);
  sectionsList = secRes.body;
});

jest.setTimeout(30000);

describe('1. Authentication API', () => {
  test('POST /api/auth/login rejects invalid password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin', password: 'WrongPassword' });

    expect(res.status).toBe(401);
    expect(res.body).toHaveProperty('error');
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  test('POST /api/auth/login rejects missing fields', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin' });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('Protected routes reject requests without Authorization header', async () => {
    const res = await request(app).get('/api/sections');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });
});

describe('2. Sections API', () => {
  test('GET /api/sections returns 6 sections ordered by sort_order', async () => {
    const res = await request(app)
      .get('/api/sections')
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(6);

    const codes = res.body.map(s => s.code);
    expect(codes).toEqual(['EXIM', 'CRO', 'GST', 'ACCOUNTS', 'REGISTRATION', 'MARKETING']);

    const accounts = res.body.find(s => s.code === 'ACCOUNTS');
    expect(accounts.count_type).toBe('TRIPLE');
    expect(accounts.in_core_total).toBe(false);

    const exim = res.body.find(s => s.code === 'EXIM');
    expect(exim.count_type).toBe('SINGLE');
    expect(exim.in_core_total).toBe(true);
  });
});

describe('3. Entries API & Business Rules Validation', () => {
  const testDate = '2026-10-15';

  function buildValidPayload() {
    return sectionsList.map(sec => {
      if (sec.count_type === 'SINGLE') {
        return {
          section_id: sec.id,
          amount: 1000.50,
          jobs_completed: 5,
        };
      } else {
        return {
          section_id: sec.id,
          amount: 2500.00,
          ongoing_jobs: 10,
          new_jobs: 3,
          outstanding_jobs: 7,
        };
      }
    });
  }

  test('PUT /api/entries/:date/:slot rejects future dates in Asia/Kolkata', async () => {
    const res = await request(app)
      .put('/api/entries/2099-12-31/EVENING')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: buildValidPayload() });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toMatch(/future/i);
  });

  test('PUT /api/entries/:date/:slot rejects invalid slot name', async () => {
    const res = await request(app)
      .put(`/api/entries/${testDate}/NIGHT`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: buildValidPayload() });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toMatch(/slot/i);
  });

  test('PUT /api/entries/:date/:slot rejects TRIPLE section sending jobs_completed', async () => {
    const payload = buildValidPayload();
    const accountsIdx = payload.findIndex(p => {
      const sec = sectionsList.find(s => s.id === p.section_id);
      return sec.count_type === 'TRIPLE';
    });

    payload[accountsIdx].jobs_completed = 2; // Illegal for TRIPLE

    const res = await request(app)
      .put(`/api/entries/${testDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: payload });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toMatch(/TRIPLE count_type and must not send jobs_completed/i);
  });

  test('PUT /api/entries/:date/:slot rejects TRIPLE section missing one of triple counts', async () => {
    const payload = buildValidPayload();
    const accountsIdx = payload.findIndex(p => {
      const sec = sectionsList.find(s => s.id === p.section_id);
      return sec.count_type === 'TRIPLE';
    });

    delete payload[accountsIdx].outstanding_jobs;

    const res = await request(app)
      .put(`/api/entries/${testDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: payload });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toMatch(/requires ongoing_jobs, new_jobs, and outstanding_jobs/i);
  });

  test('PUT /api/entries/:date/:slot rejects SINGLE section missing jobs_completed', async () => {
    const payload = buildValidPayload();
    const eximIdx = payload.findIndex(p => {
      const sec = sectionsList.find(s => s.id === p.section_id);
      return sec.count_type === 'SINGLE';
    });

    delete payload[eximIdx].jobs_completed;

    const res = await request(app)
      .put(`/api/entries/${testDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: payload });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toMatch(/requires jobs_completed/i);
  });

  test('PUT /api/entries/:date/:slot rejects SINGLE section sending triple counts', async () => {
    const payload = buildValidPayload();
    const eximIdx = payload.findIndex(p => {
      const sec = sectionsList.find(s => s.id === p.section_id);
      return sec.count_type === 'SINGLE';
    });

    payload[eximIdx].ongoing_jobs = 4; // Illegal for SINGLE

    const res = await request(app)
      .put(`/api/entries/${testDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: payload });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(res.body.error.message).toMatch(/SINGLE count_type and must not send ongoing_jobs/i);
  });

  test('PUT /api/entries/:date/:slot rejects negative amounts', async () => {
    const payload = buildValidPayload();
    payload[0].amount = -50.00;

    const res = await request(app)
      .put(`/api/entries/${testDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: payload });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('PUT /api/entries/:date/:slot successfully saves both MORNING and EVENING entries in transactions', async () => {
    // 1. Save Morning
    const morningPayload = sectionsList.map(sec => ({
      section_id: sec.id,
      amount: 500.00,
      ...(sec.count_type === 'SINGLE'
        ? { jobs_completed: 2 }
        : { ongoing_jobs: 5, new_jobs: 1, outstanding_jobs: 4 }),
    }));

    const mRes = await request(app)
      .put(`/api/entries/${testDate}/MORNING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: morningPayload });

    expect(mRes.status).toBe(200);
    expect(mRes.body.entries.length).toBe(6);

    // 2. Save Evening
    const eveningPayload = sectionsList.map(sec => ({
      section_id: sec.id,
      amount: 1500.00,
      ...(sec.count_type === 'SINGLE'
        ? { jobs_completed: 6 }
        : { ongoing_jobs: 8, new_jobs: 3, outstanding_jobs: 5 }),
    }));

    const eRes = await request(app)
      .put(`/api/entries/${testDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: eveningPayload });

    expect(eRes.status).toBe(200);
    expect(eRes.body.entries.length).toBe(6);

    // 3. Retrieve entries via GET /api/entries/:date
    const getRes = await request(app)
      .get(`/api/entries/${testDate}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(getRes.status).toBe(200);
    expect(getRes.body.date).toBe(testDate);
    expect(getRes.body.morning.length).toBe(6);
    expect(getRes.body.evening.length).toBe(6);

    // Verify morning values are preserved
    const morningExim = getRes.body.morning.find(s => s.code === 'EXIM');
    expect(parseFloat(morningExim.amount)).toBe(500.00);
    expect(morningExim.jobs_completed).toBe(2);

    // Verify evening values are preserved
    const eveningExim = getRes.body.evening.find(s => s.code === 'EXIM');
    expect(parseFloat(eveningExim.amount)).toBe(1500.00);
    expect(eveningExim.jobs_completed).toBe(6);

    // Verify Accounts triple counts
    const eveningAccounts = getRes.body.evening.find(s => s.code === 'ACCOUNTS');
    expect(parseFloat(eveningAccounts.amount)).toBe(1500.00);
    expect(eveningAccounts.ongoing_jobs).toBe(8);
    expect(eveningAccounts.new_jobs).toBe(3);
    expect(eveningAccounts.outstanding_jobs).toBe(5);
  });

  test('PUT /api/entries/:date/:slot updates existing entries idempotently', async () => {
    const updatedPayload = sectionsList.map(sec => ({
      section_id: sec.id,
      amount: 2000.00,
      ...(sec.count_type === 'SINGLE'
        ? { jobs_completed: 10 }
        : { ongoing_jobs: 12, new_jobs: 4, outstanding_jobs: 8 }),
    }));

    const updateRes = await request(app)
      .put(`/api/entries/${testDate}/EVENING`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ entries: updatedPayload });

    expect(updateRes.status).toBe(200);

    const getRes = await request(app)
      .get(`/api/entries/${testDate}`)
      .set('Authorization', `Bearer ${authToken}`);

    const eveningExim = getRes.body.evening.find(s => s.code === 'EXIM');
    expect(parseFloat(eveningExim.amount)).toBe(2000.00);
    expect(eveningExim.jobs_completed).toBe(10);
  });
});

