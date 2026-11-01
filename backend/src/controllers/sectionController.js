const { query } = require('../db/client');

async function getSections(req, res, next) {
  try {
    const { rows } = await query(
      'SELECT id, code, name, in_core_total, count_type, sort_order FROM sections ORDER BY sort_order ASC'
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
}

module.exports = { getSections };

