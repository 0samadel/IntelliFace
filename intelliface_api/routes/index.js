// ───────────────────────────────────────────────────────────────
// File    : routes/index.js
// Purpose : Central API router to group all modular routes
// Notes   : Used in server.js as app.use('/api', routes)
// ───────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const express = require('express');
const router = express.Router();

// 🚀 Modular route imports
const authRoutes       = require('./authRoutes');
const userRoutes       = require('./userRoutes');
const departmentRoutes = require('./departmentRoutes');
const attendanceRoutes = require('./attendanceRoutes');
const dashboardRoutes  = require('./dashboardRoutes');
const locationRoutes   = require('./locationRoutes');
const faceRoutes       = require('./faceRoutes'); // 👈 NEW: Face recognition routes

/* ============================================================================
 * 2. Route Mapping
 * ========================================================================== */
// Public or protected depending on middleware setup inside each route
router.use('/auth', authRoutes);               // → /api/auth/*
router.use('/users', userRoutes);              // → /api/users/*
router.use('/departments', departmentRoutes);  // → /api/departments/*
router.use('/attendance', attendanceRoutes);   // → /api/attendance/*
router.use('/dashboard', dashboardRoutes);     // → /api/dashboard/*
router.use('/locations', locationRoutes);      // → /api/locations/*
router.use('/face', faceRoutes);               // → /api/face/*

/* ============================================================================
 * 3. Export Centralized Router
 * ========================================================================== */
module.exports = router;
/* ───────────────────────────────────────────────────────────────────────────── */
