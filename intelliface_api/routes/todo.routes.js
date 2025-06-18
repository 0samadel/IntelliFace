// ─────────────────────────────────────────────────────────────────────────────
// File    : routes/todo.routes.js
// Purpose : Handle personal to-do list CRUD operations per user
// Access  : Private (All routes require valid JWT)
// ─────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

const {
  createTodo,
  getUserTodos,
  getTodoById,
  updateTodo,
  deleteTodo
} = require('../controllers/todo.controller');

const auth = require('../middleware/authMiddleware'); // Contains verifyToken

/* ============================================================================
 * 2. Middleware Check (Startup Safety)
 * ========================================================================== */
if (typeof auth.verifyToken !== 'function') {
  console.error('❌ ERROR: verifyToken is not a function. Check authMiddleware.js export!');
}

/* ============================================================================
 * 3. Protected Routes (Requires Authentication)
 * ========================================================================== */
router.use(auth.verifyToken); // 🔐 All routes require valid JWT

// @route   POST /api/todos
// @desc    Create a new todo
// @access  Private
// 
// @route   GET /api/todos
// @desc    Get all todos for logged-in user
// @access  Private
router.route('/')
  .post(createTodo)
  .get(getUserTodos);

// @route   GET /api/todos/:id
// @desc    Get single todo by ID
// @access  Private
//
// @route   PUT /api/todos/:id
// @desc    Update a todo by ID
// @access  Private
//
// @route   DELETE /api/todos/:id
// @desc    Delete a todo by ID
// @access  Private
router.route('/:id')
  .get(getTodoById)
  .put(updateTodo)
  .delete(deleteTodo);

/* ============================================================================
 * 4. Export Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
