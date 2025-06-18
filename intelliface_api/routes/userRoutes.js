// ─────────────────────────────────────────────────────────────────────────────
// File    : routes/userRoutes.js
// Purpose : Handle CRUD operations for users (admin and employees)
// Access  : Can be protected by role-based middleware (currently disabled)
// ─────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

const {
  createEmployee,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser
} = require('../controllers/userController');

// const { verifyAdmin } = require('../middleware/authMiddleware'); // 🔐 Optional for production

/* ============================================================================
 * 2. Route Definitions
 * ========================================================================== */

// @route   POST /api/users/employee
// @desc    Create a new employee
// @access  (Should be Admin protected)
router.post('/employee', createEmployee);

// @route   GET /api/users/
// @desc    Get all users
// @access  (Should be Admin protected)
router.get('/', getAllUsers);

// @route   GET /api/users/:id
// @desc    Get a specific user by ID
// @access  (Should be Admin protected)
router.get('/:id', getUserById);

// @route   PUT /api/users/:id
// @desc    Update a user by ID
// @access  (Should be Admin protected)
router.put('/:id', updateUser);

// @route   DELETE /api/users/:id
// @desc    Delete a user by ID
// @access  (Should be Admin protected)
router.delete('/:id', deleteUser);

/* ============================================================================
 * 3. Export Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
