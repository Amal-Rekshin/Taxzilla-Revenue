const express = require('express');
const { getMonthlyReport, exportMonthlyReport } = require('../controllers/reportController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.get('/monthly', requireAuth, getMonthlyReport);
router.get('/monthly/export', requireAuth, exportMonthlyReport);

module.exports = router;

