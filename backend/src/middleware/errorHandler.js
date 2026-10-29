function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  const statusCode = err.statusCode || (err.status ? err.status : 500);
  const code = err.code || (statusCode === 500 ? 'INTERNAL_SERVER_ERROR' : 'ERROR');
  const message = err.message || 'An unexpected error occurred';

  if (statusCode >= 500) {
    console.error(`[Error] ${code}: ${message}`, err.stack);
  }

  res.status(statusCode).json({
    error: {
      code,
      message,
    },
  });
}

module.exports = errorHandler;

