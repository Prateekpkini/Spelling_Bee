const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret';

/**
 * Middleware: Verify JWT token from Authorization header.
 * Attaches decoded user payload to req.user.
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // "Bearer <token>"

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
}

/**
 * Middleware: Require Super Admin role.
 * Must be used AFTER authenticateToken.
 */
function requireSuperAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'Super Admin access required' });
  }
  next();
}

/**
 * Middleware: Require Examiner role (or Super Admin).
 * Must be used AFTER authenticateToken.
 */
function requireExaminer(req, res, next) {
  if (!req.user || (req.user.role !== 'examiner' && req.user.role !== 'superadmin')) {
    return res.status(403).json({ error: 'Examiner access required' });
  }
  next();
}

module.exports = { authenticateToken, requireSuperAdmin, requireExaminer };
