// ────────────────────────────────────────────────────────────────────────────────
// File    : models/Attendance.js
// Purpose : Mongoose schema for employee attendance records
// Used in : attendanceController, face recognition flows
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const mongoose = require('mongoose');

/* ============================================================================
 * 2. Schema Definition
 * ========================================================================== */
const attendanceSchema = new mongoose.Schema({
  // 🔹 Reference to the employee (User)
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },

  // 🔹 Check-in timestamp
  checkInTime: {
    type: Date,
    default: Date.now, // Can also be set explicitly in the controller
    required: true
  },

  // 🔹 Check-out timestamp (optional, added later when user checks out)
  checkOutTime: {
    type: Date
  },

  // 🔹 Geolocation where check-in occurred (if applicable)
  location: {
    latitude: Number,
    longitude: Number
  },

  // 🔹 File path to snapshot image taken during check-in
  snapshotImage: {
    type: String
  },

  // 🔹 Attendance status
  status: {
    type: String,
    enum: ['Present', 'Late', 'Absent', 'On Leave'],
    default: 'Present'
  }

}, { timestamps: true }); // Automatically adds `createdAt` and `updatedAt`

/* ============================================================================
 * 3. Indexes for Optimization
 * ========================================================================== */
// 🔍 Speed up queries by user and date
attendanceSchema.index({ userId: 1, checkInTime: -1 });

/* ============================================================================
 * 4. Model Export
 * ========================================================================== */
// ✅ Prevents OverwriteModelError in development
module.exports = mongoose.models.Attendance || mongoose.model('Attendance', attendanceSchema);
/* ───────────────────────────────────────────────────────────────────────────── */
