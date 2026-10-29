const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const apiRoutes = require('./routes');
const { getHealth } = require('./controllers/healthController');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

// Direct root health check (e.g. for cloud providers / load balancers)
app.get('/health', getHealth);

// Disable HTTP caching for API responses to prevent stale browser caches
app.use('/api', (req, res, next) => {
  res.set({
    'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
    'Surrogate-Control': 'no-store',
  });
  next();
});

// API base router
app.use('/api', apiRoutes);

// Catch 404
app.use((req, res, next) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.originalUrl} not found`,
    },
  });
});

// Centralized error handler
app.use(errorHandler);

module.exports = app;

