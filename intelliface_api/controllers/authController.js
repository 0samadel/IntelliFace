// ────────────────────────────────────────────────────────────────────────────────
// File    : controllers/authController.js
// Purpose : Handles user registration and login (Admin/Employee)
// Access  : Public (open routes for register/login)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports & Config
 * ========================================================================== */
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Ensure JWT secret is set
if (!process.env.JWT_SECRET) {
  console.error("❌ FATAL ERROR: JWT_SECRET is not defined. Tokens cannot be signed.");
  // Optionally halt server
  // process.exit(1);
}

/* ============================================================================
 * 2. Register a New User
 * ========================================================================== */
/**
 * @desc    Register a new user (Admin or Employee)
 * @route   POST /api/auth/register
 * @access  Public
 */
exports.register = async (req, res) => {
  console.log("📥 REGISTER ATTEMPT - Request Body:", req.body);

  try {
    const {
      fullName, email, username, password, role,
      department, employeeId, phone, address
    } = req.body;

    // ── Validate Required Fields ───────────────────────────────
    if (!fullName || !email || !username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Full name, email, username, and password are required.'
      });
    }

    // ── Check for Existing Email/Username ─────────────────────
    const existingUser = await User.findOne({
      $or: [
        { email: email.toLowerCase() },
        { username: username.toLowerCase() }
      ]
    });

    if (existingUser) {
      let conflictField = '';
      if (existingUser.email === email.toLowerCase()) conflictField = 'email';
      if (existingUser.username === username.toLowerCase()) {
        conflictField = conflictField ? 'email and username' : 'username';
      }

      console.log(`⚠️ REGISTER CONFLICT - Conflict with ${conflictField}`);
      return res.status(400).json({
        success: false,
        message: `User with this ${conflictField} already exists.`
      });
    }

    // ── Generate Employee/Admin ID ─────────────────────────────
    let finalEmployeeId = employeeId;

    if ((!role || role === 'employee') && !employeeId) {
      const count = await User.countDocuments({ role: 'employee' });
      finalEmployeeId = `EMP${(count + 1).toString().padStart(4, '0')}`;
    } else if (role === 'admin' && !employeeId) {
      const adminCount = await User.countDocuments({ role: 'admin' });
      finalEmployeeId = `ADM${(adminCount + 1).toString().padStart(3, '0')}`;
    }

    // ── Create and Save User ──────────────────────────────────
    const user = new User({
      fullName,
      email: email.toLowerCase(),
      username: username.toLowerCase(),
      password, // hashed by pre-save middleware
      role: role || 'employee',
      department: department || null,
      employeeId: finalEmployeeId,
      phone: phone || null,
      address: address || null,
    });

    await user.save();

    console.log(`✅ REGISTER SUCCESS - Username: ${user.username}, Role: ${user.role}`);

    const userToReturn = user.toObject();
    delete userToReturn.password;

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: userToReturn
    });

  } catch (err) {
    console.error("❌ REGISTER ERROR:", err);

    if (err.code === 11000) {
      const dupField = Object.keys(err.keyValue || {})[0] || "unique field";
      return res.status(400).json({
        success: false,
        message: `An account with this ${dupField} already exists.`
      });
    }

    if (err.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: err.message });
    }

    res.status(500).json({
      success: false,
      error: 'Server error during registration. ' + err.message
    });
  }
};

/* ============================================================================
 * 3. Login an Existing User
 * ========================================================================== */
/**
 * @desc    Authenticate a user and issue a JWT
 * @route   POST /api/auth/login
 * @access  Public
 */
exports.login = async (req, res) => {
  console.log("📥 LOGIN ATTEMPT - Request Body:", req.body);

  try {
    const { username, password: plainPassword } = req.body;

    // ── Validate Input ─────────────────────────────────────────
    if (!username || !plainPassword) {
      console.log("⚠️ LOGIN ERROR: Missing username or password.");
      return res.status(400).json({
        success: false,
        message: 'Username and password are required.'
      });
    }

    // ── Find User by Username ─────────────────────────────────
    const user = await User.findOne({ username: username.toLowerCase() })
      .select('+password') // explicitly include password
      .populate('department', 'name');

    if (!user) {
      console.log(`❌ LOGIN FAILED - No user found: "${username.toLowerCase()}"`);
      return res.status(401).json({ success: false, message: 'Invalid username or password.' });
    }

    // ── Check Password ────────────────────────────────────────
    const isMatch = await user.comparePassword(plainPassword);
    if (!isMatch) {
      console.log(`❌ LOGIN FAILED - Incorrect password for: "${user.username}"`);
      return res.status(401).json({ success: false, message: 'Invalid username or password.' });
    }

    console.log(`✅ LOGIN SUCCESS - User: ${user.username}`);

    // ── Create Token Payload ──────────────────────────────────
    const tokenPayload = {
      userId: user._id.toString(),
      role: user.role,
      username: user.username,
      fullName: user.fullName,
    };

    if (user.department && user.department._id) {
      tokenPayload.departmentId = user.department._id.toString();
      tokenPayload.departmentName = user.department.name;
    }

    // ── Generate JWT ──────────────────────────────────────────
    const token = jwt.sign(
      tokenPayload,
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    const userToReturn = user.toObject();
    delete userToReturn.password;

    // ── Return Auth Response ──────────────────────────────────
    return res.status(200).json({
      success: true,
      token,
      user: userToReturn,
      message: 'Login successful'
    });

  } catch (err) {
    console.error("❌ LOGIN ERROR:", err);
    res.status(500).json({
      success: false,
      error: 'Server error during login. Please try again later.'
    });
  }
};
/* ───────────────────────────────────────────────────────────────────────────── */
