// ────────────────────────────────────────────────────────────────────────────────
// controllers/userController.js
// ────────────────────────────────────────────────────────────────────────────────
// Purpose  : Manage users (mainly employees) by admin
// Endpoints: CRUD operations on /api/users/
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const User = require('../models/User');
const bcrypt = require('bcryptjs');

/* ============================================================================
 * 2. Create a New Employee (Auto-generate employeeId)
 * ========================================================================== */
/**
 * @desc   Create a new employee
 * @route  POST /api/users
 * @access Admin
 */
exports.createEmployee = async (req, res) => {
  try {
    const { fullName, phone, email, username, password, address, department } = req.body;

    // Hash the password before saving
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate unique employee ID
    const count = await User.countDocuments({ role: 'employee' });
    const employeeId = `EMP${(count + 1).toString().padStart(3, '0')}`;

    const user = new User({
      employeeId,
      fullName,
      phone,
      email,
      username,
      password: hashedPassword,
      address,
      role: 'employee',
      department
    });

    await user.save();

    const populated = await user.populate('department', 'name');

    res.status(201).json(populated);
  } catch (err) {
    console.error('❌ createEmployee error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 3. Get All Users
 * ========================================================================== */
/**
 * @desc   Retrieve all users
 * @route  GET /api/users
 * @access Admin
 */
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find()
      .select('-password')                // Exclude password
      .populate('department', 'name');   // Include department name

    res.json(users);
  } catch (err) {
    console.error('❌ getAllUsers error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 4. Get User by ID
 * ========================================================================== */
/**
 * @desc   Get a user by ID
 * @route  GET /api/users/:id
 * @access Admin
 */
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-password')
      .populate('department', 'name');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (err) {
    console.error('❌ getUserById error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 5. Update a User
 * ========================================================================== */
/**
 * @desc   Update user details
 * @route  PUT /api/users/:id
 * @access Admin
 */
exports.updateUser = async (req, res) => {
  try {
    const updates = { ...req.body };

    // Hash password if it's being updated
    if (updates.password) {
      updates.password = await bcrypt.hash(updates.password, 10);
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true }
    ).select('-password')
     .populate('department', 'name');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(updatedUser);
  } catch (err) {
    console.error('❌ updateUser error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* ============================================================================
 * 6. Delete a User
 * ========================================================================== */
/**
 * @desc   Delete a user by ID
 * @route  DELETE /api/users/:id
 * @access Admin
 */
exports.deleteUser = async (req, res) => {
  try {
    const deleted = await User.findByIdAndDelete(req.params.id);

    if (!deleted) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    console.error('❌ deleteUser error:', err);
    res.status(500).json({ error: err.message });
  }
};
/* ───────────────────────────────────────────────────────────────────────────── */
