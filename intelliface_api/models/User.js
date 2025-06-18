// ────────────────────────────────────────────────────────────────────────────────
// File    : models/User.js
// Purpose : Mongoose schema for users (admin & employees)
// Used in : Auth, Profile, User Management, Attendance, Face Recognition
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

/* ============================================================================
 * 2. Schema Definition
 * ========================================================================== */
const userSchema = new mongoose.Schema({
  // Unique ID auto-generated for employees
  employeeId: {
    type: String,
    unique: true,
    sparse: true, // Allows null for admins
  },

  fullName: {
    type: String,
    required: [true, 'Full name is required'],
    trim: true,
  },

  phone: {
    type: String,
    trim: true,
  },

  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/.+\@.+\..+/, 'Please enter a valid email address'],
  },

  username: {
    type: String,
    required: [true, 'Username is required'],
    unique: true,
    lowercase: true,
    trim: true,
  },

  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false, // Never return in queries
  },

  address: {
    type: String,
    trim: true,
  },

  role: {
    type: String,
    enum: ['admin', 'employee'],
    default: 'employee',
  },

  department: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Department',
  },

  profilePicture: {
    type: String, // File path or URL
  },

  isActive: {
    type: Boolean,
    default: true,
  },

  // 🧠 For face recognition - typically not exposed to client
  faceEmbeddings: {
    type: [[Number]], // 2D array for multiple embeddings
    default: [],
    select: false,
  }

}, { timestamps: true }); // Automatically adds createdAt & updatedAt

/* ============================================================================
 * 3. Middleware
 * ========================================================================== */
// Hash password before saving (only if changed)
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

/* ============================================================================
 * 4. Instance Methods
 * ========================================================================== */
// Compare plain password with hashed password
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

/* ============================================================================
 * 5. Export Model
 * ========================================================================== */
module.exports = mongoose.model('User', userSchema);
/* ───────────────────────────────────────────────────────────────────────────── */
