// ─────────────────────────────────────────────────────────────────────────────
// File    : app/lib/screens/home_screen.dart
// Purpose : Implements the main home screen of the application.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

// Your project's local imports
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import 'face_scan_screen.dart';
import '../utils/app_styles.dart';

/// The main screen users see after logging in.
/// It displays user information, today's attendance status, and provides
/// the primary actions for checking in and checking out.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Manages the state and logic for the [HomeScreen].
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  /* ============================================================================
   * 1. Properties & State Variables
   * ========================================================================== */

  // --- Animation and Layout ---
  final double appBarHeightFactor = 0.15; // AppBar height as a percentage of screen height.
  final double contentStartOffsetFromAppBarBottom = 10; // Space below the app bar.
  late AnimationController _fadeController, _scaleController;
  late Animation<double> _fadeAnimation, _scaleAnimation;

  // --- User & Attendance Data ---
  DateTime? _checkInTime, _checkOutTime; // Null if action hasn't occurred.
  String _userName = 'User';
  String _userRole = 'Employee';
  String _userDepartmentLocationName = 'Not Assigned';
  String? _userAvatarUrl;

  // --- Loading & UI State ---
  bool _isLoadingUserData = true; // For initial user info fetch.
  bool _isLoadingAttendance = true; // For fetching today's attendance.
  bool _isProcessingAction = false; // Prevents spamming check-in/out buttons.

  /* ============================================================================
   * 2. Lifecycle Methods
   * ========================================================================== */

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for entrance effects.
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), lowerBound: 0.95, upperBound: 1.0)..forward();
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);

    // Fetch all necessary data when the screen is first built.
    _loadInitialData();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources when the widget is removed.
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /* ============================================================================
   * 3. Data Fetching & Handling
   * ========================================================================== */

  /// Orchestrates the initial loading of all required data.
  Future<void> _loadInitialData() async {
    if (!mounted) return; // Ensure widget is still in the tree.
    setState(() { _isLoadingUserData = true; _isLoadingAttendance = true; });
    await _loadUserInfo();
    await _fetchTodaysAttendanceStatus();
    if (mounted) setState(() => _isLoadingUserData = false);
  }

  /// Fetches the current user's profile information from the [AuthService].
  Future<void> _loadUserInfo() async {
    final data = await AuthService.getCurrentUser();
    if (mounted && data != null) {
      setState(() {
        _userName = data['fullName'] ?? 'User';
        _userRole = (data['role'] ?? 'Employee').toString().capitalizeFirstLetter();
        _userAvatarUrl = data['avatarUrl']?.toString();
        _userDepartmentLocationName = data['department']?['location']?['name'] ?? 'Location N/A';
      });
    }
  }

  /// Fetches today's check-in/out times from the [AttendanceService].
  Future<void> _fetchTodaysAttendanceStatus() async {
    if (!mounted) return;
    setState(() => _isLoadingAttendance = true);
    try {
      final data = await AttendanceService.getTodaysAttendance();
      if (mounted) {
        setState(() {
          // Parse string dates from API into local DateTime objects.
          _checkInTime = data?['checkInTime'] != null ? DateTime.tryParse(data!['checkInTime'])?.toLocal() : null;
          _checkOutTime = data?['checkOutTime'] != null ? DateTime.tryParse(data!['checkOutTime'])?.toLocal() : null;
        });
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingAttendance = false);
    }
  }

  /* ============================================================================
   * 4. Core Attendance Logic
   * ========================================================================== */

  /// Handles the entire attendance flow: GPS -> Face Scan -> API Call.
  Future<void> _handleAttendanceAction(String actionLabel) async {
    HapticFeedback.lightImpact(); // Provide physical feedback on tap.
    if (_isProcessingAction) return; // Debounce to prevent multiple requests.
    setState(() => _isProcessingAction = true);

    bool isCheckIn = actionLabel.toLowerCase().contains('check-in');

    // Step 1: Get GPS Location (only required for check-in).
    Position? position;
    if (isCheckIn) {
      position = await _getGpsLocation();
      if (position == null) { // If location fails, abort the process.
        setState(() => _isProcessingAction = false);
        return;
      }
    }

    // Step 2: Navigate to Face Scan screen and wait for the result (image file).
    final File? imageFile = await Navigator.push<File?>(context, MaterialPageRoute(builder: (_) => const FaceScanScreen()));
    if (imageFile == null) { // User cancelled the face scan.
      setState(() => _isProcessingAction = false);
      _showToast('Face scan cancelled.');
      return;
    }

    // Step 3: Call the appropriate combined API endpoint with the captured data.
    try {
      Map<String, dynamic> response;
      if (isCheckIn) {
        response = await AttendanceService().checkIn(
            imageFile: imageFile,
            latitude: position!.latitude,
            longitude: position.longitude
        );
      } else {
        response = await AttendanceService().checkOut(
            imageFile: imageFile
        );
      }

      // Step 4: Update the UI with the fresh data from the API response.
      final attendance = response['attendance'] as Map<String, dynamic>?;
      if (mounted && attendance != null) {
        setState(() {
          _checkInTime = DateTime.tryParse(attendance['checkInTime'] ?? '')?.toLocal();
          _checkOutTime = DateTime.tryParse(attendance['checkOutTime'] ?? '')?.toLocal();
        });
        _showToast(response['message'] ?? 'Action successful!');
      }
    } catch (e) {
      if (mounted) _showToast(e.toString(), isError: true);
    } finally {
      // Ensure the processing flag is always reset.
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  /* ============================================================================
   * 5. Helper & Utility Methods
   * ========================================================================== */

  /// Displays a toast message at the bottom of the screen.
  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message.replaceFirst("Exception: ", ""), // Clean up exception messages.
      backgroundColor: isError ? AppColors.error : AppColors.success,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  /// Formats a DateTime object into a user-friendly time string (e.g., "9:30 AM").
  String _formatTime(DateTime? time) => time == null ? "--:--" : DateFormat.jm().format(time);

  /// Acquires the device's current GPS location, handling permissions.
  Future<Position?> _getGpsLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showToast("Location services are disabled.", isError: true);
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          _showToast("Location permissions were denied.", isError: true);
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showToast("Location permissions permanently denied. Please enable in settings.", isError: true);
        return null;
      }
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      _showToast("Error getting location: $e", isError: true);
      return null;
    }
  }

  /* ============================================================================
   * 6. Build Method & UI Widgets
   * ========================================================================== */

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic sizes based on the screen dimensions.
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final double actualAppBarHeight = safeTop + (size.height * appBarHeightFactor);
    final double contentAreaTopPadding = actualAppBarHeight + contentStartOffsetFromAppBarBottom;

    // Set status bar icons to light to contrast with the blue app bar.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent));

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      // The main layout uses a Stack to overlay the custom app bar on top of the scrollable content.
      body: RefreshIndicator(
        onRefresh: _loadInitialData, // Enables pull-to-refresh functionality.
        color: AppColors.primaryBlue,
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            // Scrollable content area.
            Positioned.fill(
              top: contentAreaTopPadding,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(size.width * 0.05, 0, size.width * 0.05, MediaQuery.of(context).padding.bottom + 20),
                child: _isLoadingUserData
                    ? Center(heightFactor: 3, child: CircularProgressIndicator(color: AppColors.primaryBlue))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScaleTransition(scale: _scaleAnimation, child: FadeTransition(opacity: _fadeAnimation, child: _buildGreetingCard(size))),
                    const SizedBox(height: 25),
                    _buildAttendanceStatusSection(size),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _buildCheckInOutButton(context, 'Check-In'),
                        _buildCheckInOutButton(context, 'Check-Out'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // The custom app bar that sits on top.
            _buildCustomAppBar(size, safeTop, actualAppBarHeight),
          ],
        ),
      ),
    );
  }

  /// Builds the custom blue app bar at the top of the screen.
  Widget _buildCustomAppBar(Size size, double safeTop, double actualHeight) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: actualHeight,
        padding: EdgeInsets.fromLTRB(size.width * 0.05, safeTop + 15, size.width * 0.05, 10),
        decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
            boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.9),
                backgroundImage: _userAvatarUrl != null ? NetworkImage(_userAvatarUrl!) : null,
                child: _userAvatarUrl == null ? FaIcon(FontAwesomeIcons.userTie, color: AppColors.primaryBlue.withOpacity(0.8), size: 24) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hello, ${_userName.split(" ").first}!', style: AppTextStyles.poppins(18, Colors.white, FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 1),
                    Text(_userRole, style: AppTextStyles.poppins(13, Colors.white.withOpacity(0.85), FontWeight.normal), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the red greeting card shown at the top of the content area.
  Widget _buildGreetingCard(Size size) {
    bool isSmallScreen = size.width < 380; // Adjust font size for smaller devices.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.055, vertical: size.width * 0.05),
      decoration: AppDecorations.cardDecoration.copyWith(
          gradient: const LinearGradient(begin: Alignment.bottomRight, end: Alignment.topLeft, colors: [Color(0xFF970F0F), Color(0xFFDB1A1A)]),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Good Morning, ${_userName.split(" ").first}!', style: AppTextStyles.poppins(isSmallScreen ? 17 : 19, Colors.white, FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Your hard work inspires us every day.\nLet’s make it a great one! ✨', style: AppTextStyles.poppins(isSmallScreen ? 11.5 : 12.5, Colors.white.withOpacity(0.9), FontWeight.normal, height: 1.5)),
        ],
      ),
    );
  }

  /// Builds the main card displaying attendance info like location, shift, and times.
  Widget _buildAttendanceStatusSection(Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Status', style: AppTextStyles.cardTitle.copyWith(fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          _buildInfoRow(icon: FontAwesomeIcons.mapPin, label: 'Work Location: ', value: _userDepartmentLocationName),
          const SizedBox(height: 12),
          _buildInfoRow(icon: FontAwesomeIcons.businessTime, label: 'Shift Time: ', value: '09:00 AM - 06:00 PM'),
          const SizedBox(height: 20),
          Divider(thickness: 1, color: AppColors.border.withOpacity(0.7)),
          const SizedBox(height: 16),
          Center(
            child: _isLoadingAttendance
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : Column(
              children: [
                _buildStatusDisplay("Checked In", _checkInTime, AppColors.success),
                const SizedBox(height: 12),
                _buildStatusDisplay("Checked Out", _checkOutTime, AppColors.primaryBlue.withOpacity(0.8), isCheckout: true),
                const SizedBox(height: 16),
                Text(DateFormat('dd MMMM, yyyy').format(DateTime.now()), style: AppTextStyles.poppins(15, AppColors.textSecondary, FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dynamic display for check-in and check-out status and times.
  Widget _buildStatusDisplay(String label, DateTime? time, Color activeColor, {bool isCheckout = false}) {
    bool isActive = time != null;
    String timeString = isActive ? _formatTime(time) : "-- : --";
    String statusLabel = label;
    Color displayColor = isActive ? activeColor : AppColors.textSecondary.withOpacity(0.7);
    FontWeight timeFontWeight = isActive ? FontWeight.bold : FontWeight.normal;

    // Special logic for the check-out display to show "Currently Working" status.
    if (isCheckout) {
      if (_checkInTime != null && _checkOutTime == null) {
        statusLabel = "Currently Working";
        timeString = "Since ${_formatTime(_checkInTime!)}";
        displayColor = AppColors.warning.darken(0.1);
      } else if (_checkOutTime != null) {
        // Label remains "Checked Out"
      } else {
        statusLabel = "Not Checked Out";
      }
    } else { // Logic for check-in display
      if (!isActive) statusLabel = "Not Checked In";
    }

    return Column(
      children: [
        Text(statusLabel, style: AppTextStyles.poppins(15, displayColor, FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text(timeString, style: AppTextStyles.poppins(20, displayColor, timeFontWeight)),
      ],
    );
  }

  /// A helper widget to create a consistent row with an icon, label, and value.
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 2.0), child: FaIcon(icon, color: AppColors.primaryBlue, size: 16)),
      const SizedBox(width: 10),
      Text(label, style: AppTextStyles.poppins(14, AppColors.textSecondary, FontWeight.w600)),
      Expanded(child: Text(value, style: AppTextStyles.poppins(14, AppColors.textPrimary, FontWeight.normal), overflow: TextOverflow.ellipsis)),
    ]);
  }

  /// Builds the Check-In and Check-Out buttons, managing their enabled/disabled state.
  Widget _buildCheckInOutButton(BuildContext context, String actionLabel) {
    bool isCheckInAction = actionLabel.toLowerCase().contains('check-in');

    // Determine the button's logical state based on attendance times.
    bool canCheckIn = _checkInTime == null;
    bool canCheckOut = _checkInTime != null && _checkOutTime == null;

    // A button is disabled if its action cannot logically be performed.
    bool isDisabledByLogic = isCheckInAction ? !canCheckIn : !canCheckOut;
    // A button is also "done" if its action has already been completed today.
    bool isAlreadyDone = isCheckInAction ? (_checkInTime != null) : (_checkOutTime != null);

    // Determine the button's visual appearance.
    String buttonText = actionLabel;
    IconData buttonIcon = isCheckInAction ? FontAwesomeIcons.fingerprint : FontAwesomeIcons.personWalkingArrowRight;
    Color currentButtonBaseColor = isCheckInAction ? AppColors.success : AppColors.error;

    if (isAlreadyDone) {
      buttonText = isCheckInAction ? 'Checked In' : 'Checked Out';
      buttonIcon = FontAwesomeIcons.circleCheck;
      currentButtonBaseColor = AppColors.textSecondary;
    }

    // Determine if this specific button should show a loading indicator.
    bool isCurrentActionLoading = _isProcessingAction && ((isCheckInAction && canCheckIn) || (!isCheckInAction && canCheckOut));

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: ElevatedButton.icon(
          icon: isCurrentActionLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : FaIcon(buttonIcon, size: 18),
          label: Text(buttonText, style: AppTextStyles.buttonText.copyWith(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: (isDisabledByLogic || isAlreadyDone || isCurrentActionLoading) ? currentButtonBaseColor.withOpacity(0.6) : currentButtonBaseColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: (isDisabledByLogic || isAlreadyDone || isCurrentActionLoading) ? 0 : 3,
          ),
          // Button is pressable only if it's not disabled by logic, not already done, and no action is currently processing.
          onPressed: (isDisabledByLogic || isAlreadyDone || _isProcessingAction) ? null : () => _handleAttendanceAction(actionLabel),
        ),
      ),
    );
  }
}

/* ============================================================================
 * 7. Extensions
 * ========================================================================== */

/// An extension on the [String] class for helpful text manipulations.
extension StringExtension on String {
  /// Capitalizes the first letter of a string and lowercases the rest.
  String capitalizeFirstLetter() => isEmpty ? "" : "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}

/// An extension on the [Color] class for helpful color manipulations.
extension ColorExtension on Color {
  /// Darkens a color by a specified amount (0.0 to 1.0).
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
// ─────────────────────────────────────────────────────────────────────────────