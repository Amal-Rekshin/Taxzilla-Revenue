const express = require('express');
const authRoutes = require('./authRoutes');
const sectionRoutes = require('./sectionRoutes');
const entryRoutes = require('./entryRoutes');
const reportRoutes = require('./reportRoutes');
const dashboardRoutes = require('./dashboardRoutes');
const { getHealth } = require('../controllers/healthController');

const router = express.Router();

// Health check endpoint for /api/health
router.get('/health', getHealth);

router.use('/auth', authRoutes);
router.use('/sections', sectionRoutes);
router.use('/entries', entryRoutes);
router.use('/reports', reportRoutes);
router.use('/dashboard', dashboardRoutes);

module.exports = router;
