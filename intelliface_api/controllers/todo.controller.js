// ────────────────────────────────────────────────────────────────────────────────
// File    : controllers/todo.controller.js
// Purpose : Handles CRUD operations for user-specific to-do items
// Access  : Private (requires JWT auth middleware)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const Todo = require('../models/Todo.model');
const User = require('../models/User');

/* ============================================================================
 * 2. Create a New To-Do
 * ========================================================================== */
/**
 * @desc    Create a new to-do item
 * @route   POST /api/todos
 * @access  Private
 */
exports.createTodo = async (req, res) => {
  console.log("📥 createTodo - Incoming:", {
    user: req.user,
    body: req.body
  });

  try {
    const { title, description, dueDate } = req.body;
    const userIdFromToken = req.user.userId;

    if (!userIdFromToken) {
      return res.status(401).json({ success: false, message: 'User not authenticated.' });
    }

    if (!title) {
      return res.status(400).json({ success: false, message: 'Title is required' });
    }

    const todoData = {
      user: userIdFromToken,
      title: title.trim()
    };

    if (description !== undefined) {
      todoData.description = description.trim();
    }

    if (dueDate) {
      const parsedDate = new Date(dueDate);
      if (isNaN(parsedDate)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid dueDate format. Use ISO 8601.'
        });
      }
      todoData.dueDate = parsedDate;
    }

    const todo = await Todo.create(todoData);
    console.log("✅ Todo created:", todo);
    res.status(201).json({ success: true, data: todo });

  } catch (error) {
    console.error("❌ createTodo Error:", error);
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(val => val.message);
      return res.status(400).json({ success: false, message: messages.join(', ') });
    }
    res.status(500).json({ success: false, message: 'Server error while creating to-do.' });
  }
};

/* ============================================================================
 * 3. Get All To-Dos for the Authenticated User
 * ========================================================================== */
/**
 * @desc    Get all to-do items for the logged-in user (with pagination/filter)
 * @route   GET /api/todos
 * @access  Private
 */
exports.getUserTodos = async (req, res) => {
  console.log("📥 getUserTodos - User:", req.user, "Query:", req.query);
  try {
    const userId = req.user.userId;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'User not authenticated.' });
    }

    const query = { user: userId };

    // Filter by date
    if (req.query.date) {
      const selectedDate = new Date(req.query.date);
      if (isNaN(selectedDate)) {
        return res.status(400).json({ success: false, message: 'Invalid date format.' });
      }
      const start = new Date(Date.UTC(selectedDate.getUTCFullYear(), selectedDate.getUTCMonth(), selectedDate.getUTCDate()));
      const end = new Date(start); end.setUTCDate(start.getUTCDate() + 1);
      query.dueDate = { $gte: start, $lt: end };
    }

    // Filter by completion
    if (req.query.completed !== undefined) {
      if (['true', 'false'].includes(req.query.completed)) {
        query.isCompleted = req.query.completed === 'true';
      } else {
        return res.status(400).json({ success: false, message: "Invalid 'completed' query parameter." });
      }
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const todos = await Todo.find(query)
      .sort({ isCompleted: 1, createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Todo.countDocuments(query);

    res.status(200).json({
      success: true,
      count: todos.length,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalItems: total
      },
      data: todos
    });

  } catch (error) {
    console.error("❌ getUserTodos Error:", error);
    res.status(500).json({ success: false, message: 'Server error while fetching to-dos.' });
  }
};

/* ============================================================================
 * 4. Get Single To-Do by ID
 * ========================================================================== */
/**
 * @desc    Get a single to-do item
 * @route   GET /api/todos/:id
 * @access  Private
 */
exports.getTodoById = async (req, res) => {
  try {
    const todo = await Todo.findById(req.params.id);
    if (!todo) return res.status(404).json({ success: false, message: 'To-Do item not found.' });

    if (todo.user.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Not authorized to access this to-do.' });
    }

    res.status(200).json({ success: true, data: todo });
  } catch (error) {
    console.error("❌ getTodoById Error:", error);
    if (error.name === 'CastError') {
      return res.status(400).json({ success: false, message: 'Invalid To-Do ID format.' });
    }
    res.status(500).json({ success: false, message: 'Server error while fetching to-do.' });
  }
};

/* ============================================================================
 * 5. Update a To-Do
 * ========================================================================== */
/**
 * @desc    Update a to-do item
 * @route   PUT /api/todos/:id
 * @access  Private
 */
exports.updateTodo = async (req, res) => {
  try {
    let todo = await Todo.findById(req.params.id);
    if (!todo) return res.status(404).json({ success: false, message: 'To-Do item not found.' });

    if (todo.user.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Not authorized to update this to-do.' });
    }

    const { title, description, dueDate, isCompleted } = req.body;

    if (title !== undefined) todo.title = title.trim();
    if (description !== undefined) todo.description = description.trim();
    if (dueDate !== undefined) {
      if (!dueDate) {
        todo.dueDate = null;
      } else {
        const parsed = new Date(dueDate);
        if (isNaN(parsed)) {
          return res.status(400).json({ success: false, message: 'Invalid dueDate format.' });
        }
        todo.dueDate = parsed;
      }
    }
    if (isCompleted !== undefined) todo.isCompleted = Boolean(isCompleted);

    const updatedTodo = await todo.save();
    res.status(200).json({ success: true, data: updatedTodo });

  } catch (error) {
    console.error("❌ updateTodo Error:", error);
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(val => val.message);
      return res.status(400).json({ success: false, message: messages.join(', ') });
    }
    if (error.name === 'CastError') {
      return res.status(400).json({ success: false, message: 'Invalid To-Do ID format.' });
    }
    res.status(500).json({ success: false, message: 'Server error while updating to-do.' });
  }
};

/* ============================================================================
 * 6. Delete a To-Do
 * ========================================================================== */
/**
 * @desc    Delete a to-do item
 * @route   DELETE /api/todos/:id
 * @access  Private
 */
exports.deleteTodo = async (req, res) => {
  try {
    const todo = await Todo.findById(req.params.id);
    if (!todo) return res.status(404).json({ success: false, message: 'To-Do item not found.' });

    if (todo.user.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this to-do.' });
    }

    await todo.deleteOne();
    res.status(200).json({ success: true, message: 'To-Do item deleted successfully.' });

  } catch (error) {
    console.error("❌ deleteTodo Error:", error);
    if (error.name === 'CastError') {
      return res.status(400).json({ success: false, message: 'Invalid To-Do ID format.' });
    }
    res.status(500).json({ success: false, message: 'Server error while deleting to-do.' });
  }
};
/* ───────────────────────────────────────────────────────────────────────────── */
