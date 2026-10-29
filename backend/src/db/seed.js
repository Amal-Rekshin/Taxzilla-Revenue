const bcrypt = require('bcrypt');
const { pool } = require('./client');

const SECTIONS = [
  { code: 'EXIM', name: 'EXIM', in_core_total: true, count_type: 'SINGLE', sort_order: 1 },
  { code: 'CRO', name: 'CRO', in_core_total: true, count_type: 'SINGLE', sort_order: 2 },
  { code: 'GST', name: 'GST', in_core_total: true, count_type: 'SINGLE', sort_order: 3 },
  { code: 'ACCOUNTS', name: 'ACCOUNTS', in_core_total: false, count_type: 'TRIPLE', sort_order: 4 },
  { code: 'REGISTRATION', name: 'REGISTRATION', in_core_total: true, count_type: 'SINGLE', sort_order: 5 },
  { code: 'MARKETING', name: 'MARKETING', in_core_total: false, count_type: 'SINGLE', sort_order: 6 },
];

async function seed() {
  const client = await pool.connect();
  try {
    console.log('[Seed] Seeding database...');
    await client.query('BEGIN');

    // 1. Seed sections
    for (const sec of SECTIONS) {
      await client.query(
        `INSERT INTO sections (code, name, in_core_total, count_type, sort_order)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (code) DO UPDATE
         SET name = EXCLUDED.name,
             in_core_total = EXCLUDED.in_core_total,
             count_type = EXCLUDED.count_type,
             sort_order = EXCLUDED.sort_order;`,
        [sec.code, sec.name, sec.in_core_total, sec.count_type, sec.sort_order]
      );
    }
    console.log(`[Seed] Seeded ${SECTIONS.length} sections successfully.`);

    // 2. Seed admin user
    const adminUser = process.env.ADMIN_USERNAME || 'admin';
    const adminPass = process.env.ADMIN_PASSWORD || 'AdminPassword@123';
    const passwordHash = await bcrypt.hash(adminPass, 10);

    await client.query(
      `INSERT INTO users (username, password_hash)
       VALUES ($1, $2)
       ON CONFLICT (username) DO UPDATE
       SET password_hash = EXCLUDED.password_hash;`,
      [adminUser, passwordHash]
    );
    console.log(`[Seed] Seeded admin user '${adminUser}' successfully.`);

    await client.query('COMMIT');
    console.log('[Seed] Seeding completed.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[Seed] Seeding failed:', err);
    throw err;
  } finally {
    client.release();
  }
}

if (require.main === module) {
  seed()
    .then(() => {
      console.log('[Seed] Done.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('[Seed] Error:', err);
      process.exit(1);
    });
}

module.exports = { seed, SECTIONS };

