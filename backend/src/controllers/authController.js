const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { query } = require('../db/client');
const { UnauthorizedError } = require('../utils/errors');
const { loginSchema } = require('../validators/authValidator');

async function login(req, res, next) {
  try {
    const parseResult = loginSchema.safeParse(req.body);
    if (!parseResult.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: parseResult.error.errors.map(e => e.message).join(', '),
        },
      });
    }

    const { username, password } = parseResult.data;
    const { rows } = await query(
      'SELECT id, username, password_hash FROM users WHERE username = $1',
      [username]
    );

    if (rows.length === 0) {
      return next(UnauthorizedError('Invalid username or password'));
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return next(UnauthorizedError('Invalid username or password'));
    }

    const token = jwt.sign(
      { id: user.id, username: user.username },
      process.env.JWT_SECRET || 'super_secret_jwt_key_revenue_tracker_2026',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({ token });
  } catch (err) {
    next(err);
  }
}

module.exports = { login };

