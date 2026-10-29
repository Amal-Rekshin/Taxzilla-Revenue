const fs = require('fs');
const path = require('path');
const { pool } = require('./client');

async function runMigrations() {
  const client = await pool.connect();
  try {
    console.log('[Migration] Starting database migration check...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        version VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMPTZ DEFAULT now()
      );
    `);

    const migrationsDir = path.join(__dirname, 'migrations');
    const files = fs.readdirSync(migrationsDir).filter(f => f.endsWith('.sql')).sort();

    const { rows } = await client.query('SELECT version FROM schema_migrations');
    const applied = new Set(rows.map(r => r.version));

    for (const file of files) {
      if (!applied.has(file)) {
        console.log(`[Migration] Applying ${file}...`);
        const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
        await client.query('BEGIN');
        try {
          await client.query(sql);
          await client.query('INSERT INTO schema_migrations (version) VALUES ($1)', [file]);
          await client.query('COMMIT');
          console.log(`[Migration] Successfully applied ${file}`);
        } catch (err) {
          await client.query('ROLLBACK');
          console.error(`[Migration] Failed applying ${file}:`, err);
          throw err;
        }
      } else {
        console.log(`[Migration] Already applied: ${file}`);
      }
    }
    console.log('[Migration] All migrations are up to date.');
  } finally {
    client.release();
  }
}

if (require.main === module) {
  runMigrations()
    .then(() => {
      console.log('[Migration] Completed successfully.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('[Migration] Failed:', err);
      process.exit(1);
    });
}

module.exports = { runMigrations };

