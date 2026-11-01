const { pool } = require('../db/client');

async function getHealth(req, res) {
  const startTime = Date.now();
  let dbStatus = 'connected';
  let dbLatencyMs = 0;

  try {
    const dbStart = Date.now();
    await pool.query('SELECT 1');
    dbLatencyMs = Date.now() - dbStart;
  } catch (err) {
    dbStatus = 'disconnected';
    console.error('[Health] DB ping failed:', err.message);
  }

  const isHealthy = dbStatus === 'connected';
  const totalLatencyMs = Date.now() - startTime;

  console.log(`[Health] Health check ping received - Status: ${isHealthy ? 'OK' : 'DEGRADED'}, DB: ${dbStatus} (${dbLatencyMs}ms), Total: ${totalLatencyMs}ms`);

  const responseData = {
    status: isHealthy ? 'ok' : 'degraded',
    service: 'RevPulse Backend API',
    environment: process.env.NODE_ENV || 'development',
    uptime: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    database: {
      status: dbStatus,
      latencyMs: dbLatencyMs,
    },
    latencyMs: totalLatencyMs,
  };

  res.status(isHealthy ? 200 : 503).json(responseData);
}

module.exports = {
  getHealth,
};

