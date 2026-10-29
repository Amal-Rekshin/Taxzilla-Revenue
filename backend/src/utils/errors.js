class AppError extends Error {
  constructor(message, statusCode = 400, code = 'BAD_REQUEST') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = {
  AppError,
  ValidationError: (msg) => new AppError(msg, 400, 'VALIDATION_ERROR'),
  NotFoundError: (msg = 'Resource not found') => new AppError(msg, 404, 'NOT_FOUND'),
  UnauthorizedError: (msg = 'Unauthorized') => new AppError(msg, 401, 'UNAUTHORIZED'),
  ForbiddenError: (msg = 'Forbidden') => new AppError(msg, 403, 'FORBIDDEN'),
};

