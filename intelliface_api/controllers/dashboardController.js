// ────────────────────────────────────────────────────────────────────────────────
// File    : controllers/dashboardController.js
// Purpose : Provides statistics for the admin dashboard (summary + attendance trends)
// Access  : Admin only (protected route)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports & Setup
 * ========================================================================== */
const User = require('../models/User');
const Attendance = require('../models/Attendance');
const moment = require('moment'); // For date manipulation

/* ============================================================================
 * 2. GET /api/dashboard/stats
 * ========================================================================== */
/**
 * @desc    Get dashboard statistics (summary cards + attendance trend data)
 * @route   GET /api/dashboard/stats?trendDays=7
 * @access  Admin
 */
exports.getDashboardStats = async (req, res) => {
  try {
    // ── 1. Summary Card Data ─────────────────────────────────────────────
    const totalEmployees = await User.countDocuments({ role: 'employee' });

    const todayStart = moment().startOf('day').toDate();
    const todayEnd = moment().endOf('day').toDate();

    const todaysAttendanceRecords = await Attendance.find({
      checkInTime: { $gte: todayStart, $lte: todayEnd }
      // status: { $in: ['Present', 'Late'] } // Optional filter
    });

    // Unique user IDs who checked in today
    const uniqueUsersPresentToday = new Set();
    todaysAttendanceRecords.forEach(record => {
      if (record.status === 'Present' || record.status === 'Late') {
        uniqueUsersPresentToday.add(record.userId.toString());
      }
    });

    const totalPresentToday = uniqueUsersPresentToday.size;
    const totalAbsentToday = Math.max(0, totalEmployees - totalPresentToday);

    // ── 2. Attendance Trends Data (Default: 7 Days) ───────────────────────
    const trendDays = parseInt(req.query.trendDays) || 7;
    const trendData = [];
    const dailyPresentCounts = {};

    // Pre-fill counts for each day
    for (let i = 0; i < trendDays; i++) {
      const date = moment().subtract(i, 'days').format('YYYY-MM-DD');
      dailyPresentCounts[date] = 0;
    }

    const trendPeriodStart = moment().subtract(trendDays - 1, 'days').startOf('day').toDate();
    const trendPeriodEnd = moment().endOf('day').toDate();

    const attendanceForTrend = await Attendance.find({
      checkInTime: { $gte: trendPeriodStart, $lte: trendPeriodEnd },
      status: { $in: ['Present', 'Late'] }
    }).populate('userId', 'employeeId'); // Optional: include user info

    // Count check-ins per day
    attendanceForTrend.forEach(record => {
      const dateStr = moment(record.checkInTime).format('YYYY-MM-DD');
      if (dailyPresentCounts.hasOwnProperty(dateStr)) {
        dailyPresentCounts[dateStr]++;
      }
    });

    // Prepare trend data in ascending date order
    for (let i = trendDays - 1; i >= 0; i--) {
      const date = moment().subtract(i, 'days');
      const dateStr = date.format('YYYY-MM-DD');
      trendData.push({
        date: dateStr,
        presentCount: dailyPresentCounts[dateStr] || 0
      });
    }

    // ── 3. Respond with Summary & Trend Data ──────────────────────────────
    res.json({
      summary: {
        totalEmployees,
        totalPresentToday,
        totalAbsentToday,
        // faceScanSuccessRate: 'N/A' // Placeholder if needed
      },
      attendanceTrend: trendData
    });

  } catch (err) {
    console.error('❌ Error in getDashboardStats:', err);
    res.status(500).json({ error: 'Server error while fetching dashboard stats: ' + err.message });
  }
};
/* ───────────────────────────────────────────────────────────────────────────── */
