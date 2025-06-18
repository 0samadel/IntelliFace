// ────────────────────────────────────────────────────────────────────────────────
// controllers/locationController.js
// ────────────────────────────────────────────────────────────────────────────────
// Purpose  : Manage work locations (used for geofencing check-in areas)
// Endpoints: POST, GET, PUT, DELETE /api/locations/
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const Location = require('../models/Location');

/* ============================================================================
 * 2. Create a new location
 * ========================================================================== */
/**
 * @desc   Create a new location
 * @route  POST /api/locations
 * @access Admin
 */
exports.createLocation = async (req, res) => {
  try {
    const location = new Location(req.body);
    await location.save();

    res.status(201).json(location);
  } catch (err) {
    console.error('❌ createLocation error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 3. Get all locations
 * ========================================================================== */
/**
 * @desc   Retrieve all available locations
 * @route  GET /api/locations
 * @access Admin
 */
exports.getLocations = async (req, res) => {
  try {
    const locations = await Location.find();
    res.json(locations);
  } catch (err) {
    console.error('❌ getLocations error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 4. Update a location
 * ========================================================================== */
/**
 * @desc   Update an existing location by ID
 * @route  PUT /api/locations/:id
 * @access Admin
 */
exports.updateLocation = async (req, res) => {
  try {
    const updated = await Location.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true } // return updated document
    );

    res.json(updated);
  } catch (err) {
    console.error('❌ updateLocation error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 5. Delete a location
 * ========================================================================== */
/**
 * @desc   Delete a location by ID
 * @route  DELETE /api/locations/:id
 * @access Admin
 */
exports.deleteLocation = async (req, res) => {
  try {
    await Location.findByIdAndDelete(req.params.id);
    res.json({ message: 'Location deleted successfully' });
  } catch (err) {
    console.error('❌ deleteLocation error:', err);
    res.status(500).json({ error: err.message });
  }
};
/* ───────────────────────────────────────────────────────────────────────────── */
