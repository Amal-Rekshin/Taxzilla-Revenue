const express = require('express');
const { getSections } = require('../controllers/sectionController');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.get('/', requireAuth, getSections);

module.exports = router;

