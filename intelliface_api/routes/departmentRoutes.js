// ────────────────────────────────────────────────────────────────────────────────
// File    : routes/departmentRoutes.js
// Purpose : Handles API endpoints for Department management
// Access  : ⚠️ Public during development (Protect with verifyAdmin before production)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

const {
  createDepartment,
  getDepartments,
  updateDepartment,
  deleteDepartment
} = require('../controllers/departmentController');

// const { verifyToken, verifyAdmin } = require('../middleware/authMiddleware'); // Uncomment to secure

/* ============================================================================
 * 2. Middleware Protection (Recommended for Production)
 * ========================================================================== */
// router.use(verifyToken);   // Require authentication
// router.use(verifyAdmin);   // Allow only admins

/* ============================================================================
 * 3. Routes
 * ========================================================================== */

// @route   POST /api/departments
// @desc    Create a new department
// @access  ⚠️ Currently open
router.post('/', createDepartment);

// @route   GET /api/departments
// @desc    Get all departments
// @access  ⚠️ Currently open
router.get('/', getDepartments);

// @route   PUT /api/departments/:id
// @desc    Update a department by ID
// @access  ⚠️ Currently open
router.put('/:id', updateDepartment);

// @route   DELETE /api/departments/:id
// @desc    Delete a department by ID
// @access  ⚠️ Currently open
router.delete('/:id', deleteDepartment);

/* ============================================================================
 * 4. Export Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
