// ────────────────────────────────────────────────────────────────────────────────
// File    : routes/authRoutes.js
// Purpose : Handles authentication (register and login)
// Access  : Public (login), Protected or Public (register depending on use case)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

const authController = require('../controllers/authController'); // Make sure it exports { register, login }

/* ============================================================================
 * 2. Verification Logs (Dev only)
 * ========================================================================== */
if (typeof authController.register !== 'function') {
  console.error("❌ FATAL: authController.register is not a function!");
} else {
  console.log("✅ authRoutes: register handler loaded.");
}

if (typeof authController.login !== 'function') {
  console.error("❌ FATAL: authController.login is not a function!");
} else {
  console.log("✅ authRoutes: login handler loaded.");
}

/* ============================================================================
 * 3. Routes
 * ========================================================================== */

// @route   POST /api/auth/register
// @desc    Register new user (could be admin-created or self-register based on rules)
// @access  Public (or protected by admin if needed)
router.post('/register', authController.register);

// @route   POST /api/auth/login
// @desc    Authenticate user and return JWT
// @access  Public
router.post('/login', authController.login);

/* ============================================================================
 * 4. Export Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
