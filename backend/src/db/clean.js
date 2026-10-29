const { pool } = require('./client');

async function cleanEntries() {
  const client = await pool.connect();
  try {
    console.log('[Clean] Removing all daily revenue entries and audit logs...');
    await client.query('TRUNCATE TABLE entry_audit, daily_entries RESTART IDENTITY CASCADE;');
    console.log('[Clean] Successfully removed all entries and audit logs.');
  } catch (err) {
    console.error('[Clean] Error cleaning entries:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  cleanEntries()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}

module.exports = { cleanEntries };

