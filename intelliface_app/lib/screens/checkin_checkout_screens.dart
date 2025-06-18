// ─────────────────────────────────────────────────────────────
// File        : checkin_checkout_screens.dart
// Purpose     : Handles employee check-in and check-out screens
// Feature     : Uses camera-based face recognition and location
// System Role : Connects to backend to log attendance events
// Dependencies: Flutter, Geolocator, FaceScanScreen, AttendanceService
//
// Key Functions:
// - Capture geolocation and camera image
// - Perform face recognition via API
// - Handle check-in and check-out feedback via toast
//
// Used In: Employee mobile app to mark attendance securely
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'face_scan_screen.dart';
import '../services/attendance_service.dart';
import '../utils/app_styles.dart';

/// ─────────────────────────────────────────────────────────────
/// CHECK-IN SCREEN
/// Allows employee to check in using face recognition + location.
/// ─────────────────────────────────────────────────────────────
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isProcessing = false;

  /// Get user's current location with permission handling
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Launch face scan → capture location → send check-in API
  Future<void> _startFaceScanAndCheckIn() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final position = await _determinePosition();

      if (!mounted) return;

      final File? imageFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (context) => const FaceScanScreen()),
      );

      if (imageFile == null) {
        Fluttertoast.showToast(msg: 'Face scan cancelled.');
        setState(() => _isProcessing = false);
        return;
      }

      final attendanceResponse = await AttendanceService().checkIn(
        imageFile: imageFile,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      Fluttertoast.showToast(
        msg: attendanceResponse['message'] as String? ?? 'Checked in successfully!',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );

      if (mounted) Navigator.pop(context, attendanceResponse['attendance']);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Operation Failed: ${e.toString().replaceFirst("Exception: ", "")}",
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// UI for the Check-In screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check In', style: AppTextStyles.poppins(18, Colors.white, FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.cameraRetro, size: 70, color: AppColors.primaryBlue.withOpacity(0.7)),
              const SizedBox(height: 30),
              Text(
                'Face Recognition Check-In',
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins(20, AppColors.textPrimary, FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Position your face clearly in the frame to clock in for your shift.',
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins(15, AppColors.textSecondary, FontWeight.normal, height: 1.4),
              ),
              const SizedBox(height: 45),
              ElevatedButton.icon(
                icon: _isProcessing
                    ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 10), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const FaIcon(FontAwesomeIcons.qrcode, size: 20),
                label: Text('Start Face Scan', style: AppTextStyles.buttonText.copyWith(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _isProcessing ? null : _startFaceScanAndCheckIn,
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// CHECK-OUT SCREEN
/// Allows employee to check out using face recognition only.
/// ─────────────────────────────────────────────────────────────
class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  bool _isProcessing = false;

  /// Launch face scan → send checkout request to backend
  Future<void> _startFaceScanAndCheckOut() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final File? imageFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (context) => const FaceScanScreen()),
      );

      if (imageFile == null) {
        Fluttertoast.showToast(msg: 'Scan cancelled.');
        setState(() => _isProcessing = false);
        return;
      }

      final attendanceResponse = await AttendanceService().checkOut(imageFile: imageFile);

      Fluttertoast.showToast(
        msg: attendanceResponse['message'] ?? 'Checked out successfully!',
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );

      if (mounted) Navigator.pop(context, attendanceResponse['attendance']);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Operation Failed: ${e.toString().replaceFirst("Exception: ", "")}",
        backgroundColor: AppColors.error,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// UI for the Check-Out screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Out', style: AppTextStyles.poppins(18, Colors.white, FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.personWalkingArrowRight, size: 70, color: AppColors.primaryBlue.withOpacity(0.7)),
              const SizedBox(height: 30),
              Text(
                'Face Recognition Check-Out',
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins(20, AppColors.textPrimary, FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Verify your identity to complete your workday and clock out.',
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins(15, AppColors.textSecondary, FontWeight.normal, height: 1.4),
              ),
              const SizedBox(height: 45),
              ElevatedButton.icon(
                icon: _isProcessing
                    ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 10), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const FaIcon(FontAwesomeIcons.qrcode, size: 20),
                label: Text('Start Face Scan', style: AppTextStyles.buttonText.copyWith(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _isProcessing ? null : _startFaceScanAndCheckOut,
              )
            ],
          ),
        ),
      ),
    );
  }
}
