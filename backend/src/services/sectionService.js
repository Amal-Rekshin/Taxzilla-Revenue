const { query } = require('../db/client');

let cachedSections = null;
let lastFetch = 0;
const CACHE_TTL = 60000; // 1 minute cache

async function getAllSections() {
  const now = Date.now();
  if (cachedSections && (now - lastFetch < CACHE_TTL)) {
    return cachedSections;
  }
  const { rows } = await query(
    'SELECT id, code, name, in_core_total, count_type, sort_order FROM sections ORDER BY sort_order ASC'
  );
  cachedSections = rows;
  lastFetch = now;
  return rows;
}

function clearSectionCache() {
  cachedSections = null;
  lastFetch = 0;
}

module.exports = {
  getAllSections,
  clearSectionCache,
};

