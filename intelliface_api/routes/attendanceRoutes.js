// ────────────────────────────────────────────────────────────────────────────────
// File    : routes/attendanceRoutes.js (FINALIZED and CORRECTED)
// Purpose : Routes for handling attendance actions (check-in, check-out, view, delete)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

const attendanceController = require('../controllers/attendanceController');
const { verifyToken, verifyAdmin } = require('../middleware/authMiddleware');
const upload = require('../middleware/faceUploadMiddleware'); // ✅ IMPORTED UPLOAD MIDDLEWARE

/* ============================================================================
 * 2. Routes
 * ========================================================================== */

// ─── Employee Actions (Token required) ───────────────────────────────────────

/**
 * @route   POST /api/attendance
 * @desc    Handles employee check-in.
 * @access  Private (Employee)
 */
router.post(
  '/', // ✅ CORRECTED: Route is now the base URL, matching the Flutter service
  verifyToken,
  upload.single('face'), // ✅ ADDED: Multer middleware to process the file
  attendanceController.checkIn
);

/**
 * @route   PUT /api/attendance/checkout
 * @desc    Handles employee check-out.
 * @access  Private (Employee)
 */
router.put( // ✅ CORRECTED: Method is now PUT for updating
  '/checkout', 
  verifyToken, 
  upload.single('face'), // ✅ ADDED: Multer middleware for verification
  attendanceController.checkOut
);

/**
 * @route   GET /api/attendance/me/today
 * @desc    Gets today's attendance for the logged-in user.
 * @access  Private (Employee)
 */
router.get(
  '/me/today', 
  verifyToken, 
  attendanceController.getTodaysAttendanceForUser
);


// ─── Admin Actions (Token + Admin Role required) ─────────────────────────────

/**
 * @route   GET /api/attendance
 * @desc    Gets all attendance records.
 * @access  Private (Admin)
 */
router.get(
  '/', 
  verifyToken, 
  verifyAdmin, 
  attendanceController.getAllAttendance
);

/**
 * @route   DELETE /api/attendance/:id
 * @desc    Deletes a specific attendance record.
 * @access  Private (Admin)
 */
router.delete(
  '/:id', 
  verifyToken, 
  verifyAdmin, 
  attendanceController.deleteAttendance
);

/* ============================================================================
 * 3. Export Router
 * ========================================================================== */
module.exports = router;