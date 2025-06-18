// ────────────────────────────────────────────────────────────────────────────────
// File    : models/Todo.model.js
// Purpose : Mongoose schema for user to-do items
// Used in : todoController
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const mongoose = require('mongoose');

/* ============================================================================
 * 2. Schema Definition
 * ========================================================================== */
const TodoSchema = new mongoose.Schema({
  // 🔹 Reference to the user who created the todo
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  // 🔹 Task title (required)
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
  },

  // 🔹 Optional task description
  description: {
    type: String,
    trim: true,
  },

  // 🔹 Optional due date (used for filtering)
  dueDate: {
    type: Date,
  },

  // 🔹 Completion status
  isCompleted: {
    type: Boolean,
    default: false,
  }

}, { timestamps: true }); // Adds createdAt and updatedAt

/* ============================================================================
 * 3. Indexes for Efficient Queries
 * ========================================================================== */
TodoSchema.index({ user: 1, dueDate: 1 }); // For filtering todos by date
TodoSchema.index({ user: 1, isCompleted: 1, createdAt: -1 }); // For paginated views by completion status

/* ============================================================================
 * 4. Export Model
 * ========================================================================== */
module.exports = mongoose.models.Todo || mongoose.model('Todo', TodoSchema);
/* ───────────────────────────────────────────────────────────────────────────── */
