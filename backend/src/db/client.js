const dns = require('dns');
if (dns.setDefaultResultOrder) {
  dns.setDefaultResultOrder('ipv4first');
}

const { Pool } = require('pg');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const connectionString = process.env.DATABASE_URL;

let poolConfig = {
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 15000,
};

if (connectionString) {
  poolConfig.connectionString = connectionString;
  if (
    connectionString.includes('sslmode=require') ||
    connectionString.includes('sslmode=verify-full') ||
    connectionString.includes('neon.tech') ||
    process.env.NODE_ENV === 'production'
  ) {
    poolConfig.ssl = {
      rejectUnauthorized: false,
    };
  }
} else {
  poolConfig = {
    ...poolConfig,
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USER || 'revenue_user',
    password: process.env.DB_PASSWORD || 'revenue_secret',
    database: process.env.DB_NAME || 'revenue_tracker',
  };
}

const pool = new Pool(poolConfig);

// Handle idle client errors gracefully to prevent crashing
pool.on('error', (err) => {
  console.warn('[DB Pool] Idle client connection issue:', err.message);
});

/**
 * Execute query with automatic retry for transient network / DNS glitches
 */
async function query(text, params, maxRetries = 2) {
  let attempt = 0;
  while (true) {
    try {
      return await pool.query(text, params);
    } catch (err) {
      attempt++;
      const isTransient =
        err.code === 'ECONNRESET' ||
        err.code === 'ENOTFOUND' ||
        err.code === 'ETIMEDOUT' ||
        err.code === 'EAI_AGAIN' ||
        (err.message && err.message.includes('getaddrinfo'));

      if (attempt <= maxRetries && isTransient) {
        console.warn(`[DB Query] Transient connection error (${err.code || err.message}), retrying attempt ${attempt}/${maxRetries}...`);
        await new Promise((resolve) => setTimeout(resolve, 600 * attempt));
        continue;
      }
      throw err;
    }
  }
}

module.exports = {
  pool,
  query,
};
