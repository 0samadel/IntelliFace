// ────────────────────────────────────────────────────────────────────────────────
// controllers/departmentController.js
// ────────────────────────────────────────────────────────────────────────────────
// Purpose  : Manage Department CRUD operations
// Endpoints: POST, GET, PUT, DELETE /api/departments/
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const Department = require('../models/Department');

/* ============================================================================
 * 2. Create a new department
 * ========================================================================== */
/**
 * @desc   Create a new department
 * @route  POST /api/departments
 * @access Admin
 */
exports.createDepartment = async (req, res) => {
  try {
    const { name, location } = req.body;

    // Create and save new department
    const department = new Department({ name, location });
    await department.save();

    // Populate location field with name only
    const populated = await department.populate('location', 'name');

    res.status(201).json(populated);
  } catch (err) {
    console.error('❌ createDepartment error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 3. Get all departments
 * ========================================================================== */
/**
 * @desc   Fetch all departments
 * @route  GET /api/departments
 * @access Admin
 */
exports.getDepartments = async (req, res) => {
  try {
    // Populate each department's location field
    const departments = await Department.find().populate('location', 'name');

    res.json(departments);
  } catch (err) {
    console.error('❌ getDepartments error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 4. Update a department
 * ========================================================================== */
/**
 * @desc   Update department details
 * @route  PUT /api/departments/:id
 * @access Admin
 */
exports.updateDepartment = async (req, res) => {
  try {
    const { name, location } = req.body;

    // Find department by ID and update
    const updated = await Department.findByIdAndUpdate(
      req.params.id,
      { name, location },
      { new: true } // Return updated doc
    ).populate('location', 'name');

    res.json(updated);
  } catch (err) {
    console.error('❌ updateDepartment error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 5. Delete a department
 * ========================================================================== */
/**
 * @desc   Delete a department by ID
 * @route  DELETE /api/departments/:id
 * @access Admin
 */
exports.deleteDepartment = async (req, res) => {
  try {
    await Department.findByIdAndDelete(req.params.id);
    res.json({ message: 'Department deleted' });
  } catch (err) {
    console.error('❌ deleteDepartment error:', err);
    res.status(500).json({ error: err.message });
  }
};
/* ───────────────────────────────────────────────────────────────────────────── */
