// ────────────────────────────────────────────────────────────────────────────────
// File    : routes/locationRoutes.js
// Purpose : Manages CRUD operations for location entities
// Access  : ⚠️ Public in development (Secure with verifyAdmin before deployment)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

const {
  createLocation,
  getLocations,
  updateLocation,
  deleteLocation
} = require('../contarollers/locationController');

// const { verifyToken, verifyAdmin } = require('../middleware/authMiddleware'); // For production

/* ============================================================================
 * 2. Middleware Protection (Uncomment before production)
 * ========================================================================== */
// router.use(verifyToken);   // Require authentication
// router.use(verifyAdmin);   // Restrict access to admins only

/* ============================================================================
 * 3. Routes
 * ========================================================================== */

// @route   POST /api/locations
// @desc    Create a new location
// @access  ⚠️ Currently public
router.post('/', createLocation);

// @route   GET /api/locations
// @desc    Get all locations
// @access  ⚠️ Currently public
router.get('/', getLocations);

// @route   PUT /api/locations/:id
// @desc    Update location by ID
// @access  ⚠️ Currently public
router.put('/:id', updateLocation);

// @route   DELETE /api/locations/:id
// @desc    Delete location by ID
// @access  ⚠️ Currently public
router.delete('/:id', deleteLocation);

/* ============================================================================
 * 4. Export Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
