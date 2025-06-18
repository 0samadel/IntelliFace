// ────────────────────────────────────────────────────────────────────────────────
// File    : routes/faceRoutes.js
// Purpose : Defines API endpoints for all face-related actions.
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

// Import controller functions that contain the route logic
const faceController = require('../controllers/faceController');

// Import middleware
const { verifyToken, verifyAdmin } = require('../middleware/authMiddleware');
const upload = require('../middleware/faceUploadMiddleware');

/* ============================================================================
 * 2. Route Definitions
 * ========================================================================== */

/**
 * @route   POST /api/faces/enroll/:userId
 * @desc    Enroll a new face for a specific user.
 * @access  Private (Admin Only)
 */
router.post(
  '/enroll/:userId',
  verifyToken,          // Ensures a user is logged in
  verifyAdmin,          // Ensures the user has an 'admin' role
  upload.single('face'),  // Multer middleware to handle the file upload from the form
  faceController.enrollFace // The controller function that does the work
);

/**
 * @route   POST /api/faces/verify
 * @desc    Verify the face of the logged-in user for an attendance check.
 * @access  Private (Employee or Admin)
 */
router.post(
  '/verify',
  verifyToken,          // Ensures a user is logged in
  upload.single('face'),  // Multer middleware to handle the file upload
  faceController.verifyFace // The controller function that does the work
);


/* ============================================================================
 * 3. Export Router
 * ========================================================================== */
module.exports = router;