const express = require('express');
const { getEntriesByDate, putEntries } = require('../controllers/entryController');
const { getEntriesHistoryList, getEntryAuditHistory } = require('../controllers/historyController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// List entries with month & filter: GET /api/entries?month=YYYY-MM&filter=all|pending|edited
router.get('/', requireAuth, getEntriesHistoryList);

// Audit history for a specific day (all slots or filtered by ?slot=): GET /api/entries/:date/history
router.get('/:date/history', requireAuth, getEntryAuditHistory);

// Audit history for a specific day and slot: GET /api/entries/:date/:slot/history
router.get('/:date/:slot/history', requireAuth, getEntryAuditHistory);

// Single day entries detail: GET /api/entries/:date
router.get('/:date', requireAuth, getEntriesByDate);

// Transactional upsert with audit write: PUT /api/entries/:date/:slot
router.put('/:date/:slot', requireAuth, putEntries);

module.exports = router;
