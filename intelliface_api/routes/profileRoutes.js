// ─────────────────────────────────────────────────────────────────────────────
// File    : routes/profileRoutes.js
// Purpose : Handles authenticated user profile retrieval and updates
// Access  : Private (Requires valid JWT via verifyToken middleware)
// ─────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const { getMyProfile, updateMyProfile } = require('../controllers/userProfileController');
const { verifyToken } = require('../middleware/authMiddleware');
const handleMulterUpload = require('../middleware/uploadMiddleware'); // Handles profile image upload

const router = express.Router();

/* ============================================================================
 * 2. Middleware
 * ========================================================================== */
router.use(verifyToken); // 🔒 All routes below require authenticated user

/* ============================================================================
 * 3. Routes
 * ========================================================================== */

// @route   GET /api/profile/me
// @desc    Get current user's profile info
// @access  Private (token required)

// @route   PUT /api/profile/me
// @desc    Update user's profile (with optional image upload)
// @access  Private (token required)

router.route('/me')
  .get(getMyProfile)
  .put(handleMulterUpload('profileImage'), updateMyProfile);

/* ============================================================================
 * 4. Export Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
