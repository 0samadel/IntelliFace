// ────────────────────────────────────────────────────────────────────────────────
// File    : routes/dashboardRoutes.js
// Purpose : Route handler for dashboard analytics and statistics
// Access  : ⚠️ Currently Public (suggest securing with verifyAdmin for production)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

const { getDashboardStats } = require('../controllers/dashboardController');
// const { verifyToken, verifyAdmin } = require('../middleware/authMiddleware'); // Uncomment for security

/* ============================================================================
 * 2. Middleware Protection (Optional)
 * ========================================================================== */
// router.use(verifyToken);       // Enforce authentication
// router.use(verifyAdmin);       // Enforce admin-only access

/* ============================================================================
 * 3. Routes
 * ========================================================================== */

// @route   GET /api/dashboard/stats
// @desc    Fetch dashboard statistics (users, attendance, trends, etc.)
// @access  ⚠️ Currently public, secure this route before production
router.get('/stats', getDashboardStats);

/* ============================================================================
 * 4. Export Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
