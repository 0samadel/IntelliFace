// ─────────────────────────────────────────────────────────────────────────────
// File    : screens/attendance_screen.dart
// Purpose : Displays daily check-in/check-out status and actions for the user.
// Notes   : Uses RefreshIndicator for pull-to-refresh functionality.
// ─────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart'; // For time formatting
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Ensure these paths are correct
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../utils/app_styles.dart'; // Your shared styles

// These are needed if you navigate to separate CheckInScreen/CheckOutScreen
// If HomeScreen's direct FaceScanScreen call is preferred, these might not be used from here.
// import 'checkin_checkout_screens.dart';

/* ============================================================================
 * 2. Screen Widget
 * ========================================================================== */

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  /* --------------------------------------------------------------------------
   * 3. State Variables
   * ------------------------------------------------------------------------ */

  String _userName = "User";
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  bool _isLoading = true;
  bool _isProcessingAction = false; // For button loading state when navigating

  /* --------------------------------------------------------------------------
   * 4. Lifecycle Methods
   * ------------------------------------------------------------------------ */

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* --------------------------------------------------------------------------
   * 5. Data & Business Logic
   * ------------------------------------------------------------------------ */

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadUserInfo();
    await _fetchTodaysAttendanceStatus();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserInfo() async {
    final currentUser = await AuthService.getCurrentUser();
    if (mounted && currentUser != null) {
      setState(() {
        _userName = currentUser['fullName']?.toString() ?? 'User';
      });
    }
  }

  Future<void> _fetchTodaysAttendanceStatus() async {
    // This service call should ideally fetch only the current user's today record
    try {
      final attendanceData = await AttendanceService.getTodaysAttendance();
      if (mounted) {
        if (attendanceData != null) {
          setState(() {
            _checkInTime = attendanceData['checkInTime'] != null
                ? DateTime.tryParse(attendanceData['checkInTime'])?.toLocal()
                : null;
            _checkOutTime = attendanceData['checkOutTime'] != null
                ? DateTime.tryParse(attendanceData['checkOutTime'])?.toLocal()
                : null;
          });
        } else {
          setState(() {
            _checkInTime = null;
            _checkOutTime = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
            msg: "Error fetching attendance: ${e.toString().replaceFirst("Exception: ", "")}",
            backgroundColor: AppColors.error,
            textColor: Colors.white);
      }
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    return DateFormat.jm().format(time); // e.g., 9:30 AM
  }

  Future<void> _navigateToAndRefresh(String routeName) async {
    if (!mounted) return;
    setState(() => _isProcessingAction = true);

    // Navigate and wait for the result (e.g., the attendance record map)
    final dynamic result = await Navigator.pushNamed(context, routeName);

    if (mounted) {
      setState(() => _isProcessingAction = false);
      // If the CheckIn/CheckOut screens pop with data, update immediately.
      // Otherwise, always refresh.
      if (result != null && result is Map<String,dynamic>) {
        // Assuming result is the updated attendance record
        _fetchTodaysAttendanceStatus(); // Refresh to be sure or use result directly
        print("Action completed, result: $result");
      } else {
        // Even if no specific data is returned, refresh the status
        await _fetchTodaysAttendanceStatus();
      }
    }
  }

  /* --------------------------------------------------------------------------
   * 6. Build Method
   * ------------------------------------------------------------------------ */

  @override
  Widget build(BuildContext context) {
    final bool canCheckIn = _checkInTime == null;
    final bool canCheckOut = _checkInTime != null && _checkOutTime == null;

    return Scaffold(
      appBar: AppBar(
        title: Text("Daily Attendance", style: AppTextStyles.poppins(18, Colors.white, FontWeight.w600)),
        // backgroundColor: AppColors.primaryBlue, // Set in main.dart theme
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryBlue,
        backgroundColor: Colors.white,
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(color: AppColors.primaryBlue)
              : SingleChildScrollView( // Ensure content can scroll if screen is small
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.solidUserCircle, size: 70, color: AppColors.primaryBlue.withOpacity(0.8)),
                const SizedBox(height: 16),
                Text(
                  _userName.toUpperCase(),
                  style: AppTextStyles.poppins(24, AppColors.textPrimary, FontWeight.bold, letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Mark your attendance for today",
                  style: AppTextStyles.poppins(15, AppColors.textSecondary, FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildAttendanceStatusTile("Check-In Time", _checkInTime, AppColors.success),
                const SizedBox(height: 12),
                _buildAttendanceStatusTile("Check-Out Time", _checkOutTime, AppColors.primaryBlue.withOpacity(0.8)),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      label: "Check In",
                      icon: FontAwesomeIcons.signInAlt,
                      color: AppColors.success,
                      onPressed: (canCheckIn && !_isProcessingAction) ? () => _navigateToAndRefresh('/check_in_direct') : null,
                      isLoading: _isProcessingAction && canCheckIn,
                    ),
                    _buildActionButton(
                      label: "Check Out",
                      icon: FontAwesomeIcons.signOutAlt,
                      color: AppColors.error, // Using error color for distinctness
                      onPressed: (canCheckOut && !_isProcessingAction) ? () => _navigateToAndRefresh('/check_out_direct') : null,
                      isLoading: _isProcessingAction && canCheckOut,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_checkInTime != null && _checkOutTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      "Attendance for today is complete!",
                      style: AppTextStyles.poppins(15, AppColors.success, FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* --------------------------------------------------------------------------
   * 7. Widget Builders
   * ------------------------------------------------------------------------ */

  Widget _buildAttendanceStatusTile(String title, DateTime? time, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withOpacity(0.5))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.poppins(16, AppColors.textSecondary, FontWeight.w500)),
          Text(
            _formatTime(time),
            style: AppTextStyles.poppins(16, time != null ? activeColor : AppColors.textSecondary, FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed, // Disable if already loading this action OR if onPressed is null
          icon: isLoading
              ? Container(width: 18, height: 18, margin: const EdgeInsets.only(right:8), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : FaIcon(icon, size: 18),
          label: Text(label, style: AppTextStyles.buttonText.copyWith(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed == null ? color.withOpacity(0.5) : color, // Dim if disabled
            padding: const EdgeInsets.symmetric(vertical: 14), // Adjusted padding
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: onPressed == null ? 0 : 2,
          ),
        ),
      ),
    );
  }
}

/* ============================================================================
 * 8. Helper Extensions
 * ========================================================================== */

// Helper extension (if not already in app_styles.dart or a utility file)
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
/* ───────────────────────────────────────────────────────────────────────────── */