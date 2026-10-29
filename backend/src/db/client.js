const { Pool } = require('pg');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const connectionString = process.env.DATABASE_URL;

let poolConfig = {
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
};

if (connectionString) {
  poolConfig.connectionString = connectionString;
  if (
    connectionString.includes('sslmode=require') ||
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

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
