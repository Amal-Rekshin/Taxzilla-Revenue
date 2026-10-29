const jwt = require('jsonwebtoken');
const { UnauthorizedError } = require('../utils/errors');

function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(UnauthorizedError('Missing or malformed Authorization header'));
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_jwt_key_revenue_tracker_2026');
    req.user = decoded; // { id, username }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(UnauthorizedError('Token has expired'));
    }
    return next(UnauthorizedError('Invalid token'));
  }
}

module.exports = { requireAuth };

