// ────────────────────────────────────────────────────────────────────────────────
// middleware/authMiddleware.js
// ────────────────────────────────────────────────────────────────────────────────
// Purpose  : Authenticate JWT tokens and enforce role-based access (admin)
// Applied  : As middleware on protected routes
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports & Config
 * ========================================================================== */
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

/* ============================================================================
 * 2. Middleware: verifyToken
 * ========================================================================== */
/**
 * @desc   Verifies JWT token and attaches decoded user data to req.user
 * @usage  Add as middleware on routes that require login
 */
const verifyToken = (req, res, next) => {
  console.log("🔐 verifyToken middleware hit →", req.originalUrl);

  const authHeader = req.headers.authorization;
  console.log("📥 Authorization Header:", authHeader);

  // Ensure secret is configured
  if (!JWT_SECRET) {
    console.error("❌ JWT_SECRET is not set in .env");
    return res.status(500).json({ success: false, message: 'Server misconfiguration: JWT_SECRET missing.' });
  }

  // Check for Bearer token format
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Access token is missing or malformed.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    // Decode token and attach payload to req.user
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    console.log("✅ Token verified → user:", req.user);
    next();
  } catch (err) {
    console.error("❌ Token verification failed:", err.message);
    return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
  }
};

/* ============================================================================
 * 3. Middleware: verifyAdmin
 * ========================================================================== */
/**
 * @desc   Ensures the authenticated user has admin role
 * @usage  Chain after verifyToken on admin-only routes
 */
const verifyAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ success: false, message: 'Admin access required.' });
  }
  next();
};

/* ============================================================================
 * 4. Exports
 * ========================================================================== */
module.exports = {
  verifyToken,
  verifyAdmin
};
/* ───────────────────────────────────────────────────────────────────────────── */
