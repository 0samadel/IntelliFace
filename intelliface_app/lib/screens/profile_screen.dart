// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/profile_screen.dart
// Purpose : Displays user profile information and provides options like logout.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:ui'; // For ImageFilter used in the logout dialog.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // For picking images from gallery/camera.
import 'package:image_cropper/image_cropper.dart'; // For cropping the selected image.
import 'package:intelliface/utils/app_styles.dart';
import 'package:intelliface/services/profile_service.dart';
import 'package:intelliface/services/auth_service.dart';
import 'package:intelliface/models/user_model.dart';
import 'package:intelliface/core/constants/api_constants.dart';

/// The Profile Screen, which shows detailed user information, allows profile
/// picture updates, and provides access to settings and the logout function.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Manages the state and logic for the [ProfileScreen].
class _ProfileScreenState extends State<ProfileScreen> {
  /* ============================================================================
   * 1. Properties & State Variables
   * ========================================================================== */

  // --- Services & Data ---
  final ProfileService _profileService = ProfileService();
  User? _currentUser;

  // --- UI & Loading State ---
  bool _isLoading = true; // For the initial profile fetch.
  String? _errorMessage; // To display an error message if fetching fails.
  bool _isUploadingPhoto = false; // To show a loader on the avatar when uploading.

  // --- Utilities ---
  final ImagePicker _picker = ImagePicker(); // Instance of the image picker utility.

  /* ============================================================================
   * 2. Lifecycle Methods
   * ========================================================================== */

  @override
  void initState() {
    super.initState();
    _fetchProfile(); // Fetch user data when the screen is first initialized.
  }

  /* ============================================================================
   * 3. Data Fetching & Handling
   * ========================================================================== */

  /// Fetches the user's profile data from the server.
  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _profileService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
      print("ProfileScreen _fetchProfile Error: $e");
    }
  }

  /// Constructs the full absolute URL for an image from its relative server path.
  String? getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    // If it's already a full URL, return it as is.
    if (relativePath.startsWith('http')) return relativePath;
    // Otherwise, prepend the server's base URL.
    return "${ApiConstants.serverBaseUrl}/$relativePath";
  }

  /* ============================================================================
   * 4. Profile Photo Update Logic
   * ========================================================================== */

  /// Initiates the image picking and cropping flow.
  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      // Step 1: Pick an image using the image_picker package.
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress to reduce file size.
        maxWidth: 800,
      );
      if (pickedFile == null) return; // User cancelled the picker.

      // Step 2: Crop the selected image to a square aspect ratio.
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 75,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: AppColors.primaryBlue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return; // User cancelled the cropper.

      // Step 3: Upload the final cropped image file.
      await _handleProfilePhotoUpdate(File(croppedFile.path));

    } catch (e) {
      print("Error picking/processing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Displays a bottom sheet with options to choose from the gallery or camera.
  void _showPhotoOptionsDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext bc) {
          return Container(
            decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0))),
            child: SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                      leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBlue),
                      title: Text('Photo Library', style: AppTextStyles.bodyText1),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _pickAndProcessImage(ImageSource.gallery);
                      }),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryBlue),
                    title: Text('Take Photo', style: AppTextStyles.bodyText1),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _pickAndProcessImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
  }

  /// Handles the API call to upload the new profile photo.
  Future<void> _handleProfilePhotoUpdate(File imageFile) async {
    if (!mounted) return;
    setState(() => _isUploadingPhoto = true);

    try {
      // Call the service to upload the image file.
      User updatedUser = await _profileService.updateMyProfile(
        profileImageFile: imageFile,
      );
      if (mounted) {
        setState(() {
          // Update the local user model with the new data from the server.
          _currentUser = updatedUser;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /* ============================================================================
   * 5. Build Method & UI Widgets
   * ========================================================================== */

  @override
  Widget build(BuildContext context) {
    // Controls the style of the system status bar (e.g., time, battery icons).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        color: AppColors.primaryBlue,
        child: SafeArea(
          bottom: false,
          child: Scaffold(
            backgroundColor: AppColors.pageBackground,
            // Conditionally display UI based on loading/error state.
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _errorMessage != null
                ? Center( // Error UI
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 60),
                    const SizedBox(height: 20),
                    Text("Error Loading Profile", style: AppTextStyles.cardTitle.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    Text(_errorMessage!, style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text("Retry", style: AppTextStyles.buttonText.copyWith(fontSize: 15)),
                      onPressed: _fetchProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                    )
                  ],
                ),
              ),
            )
                : _currentUser == null
                ? Center( // No Data UI
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off_outlined, color: Colors.grey, size: 60),
                    const SizedBox(height: 16),
                    Text("No profile data found.", style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    TextButton(onPressed: _fetchProfile, child: const Text("Tap to retry"))
                  ],
                )
            )
                : RefreshIndicator( // Main content with pull-to-refresh
              onRefresh: _fetchProfile,
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.cardBackground,
              child: Column(
                children: [
                  _buildProfileHeader(context, _currentUser!),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            _buildProgressCard(context),
                            const SizedBox(height: 24),
                            _buildOptionSection(context),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the top blue header section containing the user's avatar and name.
  Widget _buildProfileHeader(BuildContext context, User user) {
    final String? displayImageUrl = getFullImageUrl(user.profilePicture);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row( // AppBar-like row for navigation and title.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pushReplacementNamed(context, '/homescreen'),
                tooltip: "Back to Home",
              ),
              Text("Profile", style: AppTextStyles.poppins(20, Colors.white, FontWeight.bold)),
              const SizedBox(width: 48), // Placeholder to balance the back button.
            ],
          ),
          const SizedBox(height: 20),
          // Stack allows overlaying the edit button on the avatar.
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Hero(
                tag: 'profileImage',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightBlue.withOpacity(0.8), width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.lightBlue.withOpacity(0.3),
                    backgroundImage: displayImageUrl != null
                        ? NetworkImage(displayImageUrl)
                        : const AssetImage('assets/icon.png') as ImageProvider,
                  ),
                ),
              ),
              // The circular button for changing the photo.
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: AppColors.lightBlue,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isUploadingPhoto ? null : () => _showPhotoOptionsDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      // Show a loading indicator while uploading.
                      child: _isUploadingPhoto
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                          : const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Hello", style: AppTextStyles.profileHeaderGreeting),
          const SizedBox(height: 4),
          Text(user.fullName.toUpperCase(), style: AppTextStyles.profileHeaderName),
          if (user.department?.name != null && user.department!.name!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(user.department!.name!, style: AppTextStyles.poppins(14, Colors.white.withOpacity(0.85), FontWeight.w500)),
          ]
        ],
      ),
    );
  }

  /// Builds the "Check your progress" card. (Placeholder functionality)
  Widget _buildProgressCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Check your\nprogress", style: AppTextStyles.poppins(17, AppColors.primaryBlue, FontWeight.w700).copyWith(height: 1.3)),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.15),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.5), width: 1.5),
              ),
              child: const Icon(Icons.show_chart_rounded, color: AppColors.primaryBlue, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of menu options (Settings, Logout, etc.).
  Widget _buildOptionSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildOptionTile(context, "Saved", Icons.bookmark_border_rounded, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved tapped (Not Implemented)")));
          }),
          _buildOptionTile(context, "Settings", Icons.settings_outlined, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings tapped (Not Implemented)")));
          }),
          _buildOptionTile(context, "Support", Icons.headset_mic_outlined, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Support tapped (Not Implemented)")));
          }),
          _buildOptionTile(context, "About Us", Icons.info_outline_rounded, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("About Us tapped (Not Implemented)")));
          }),
          const SizedBox(height: 10),
          _buildOptionTile(
            context,
            "Logout",
            Icons.logout_rounded,
                () => _showLogoutDialog(context),
            textColor: AppColors.logoutColor,
            iconColor: AppColors.logoutColor,
          ),
        ],
      ),
    );
  }

  /// A reusable widget for a single menu option tile.
  Widget _buildOptionTile(BuildContext context, String title, IconData icon, VoidCallback onTap, {Color? textColor, Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: AppDecorations.profileOptionTileDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: AppColors.primaryBlue.withOpacity(0.1),
          highlightColor: AppColors.primaryBlue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor ?? AppColors.iconDefault),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.profileOptionTitle.copyWith(color: textColor ?? AppTextStyles.profileOptionTitle.color),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows an animated, blurred dialog to confirm user logout.
  void _showLogoutDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Logout Dialog",
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation1, curve: Curves.easeInOut),
            child: Material(
              type: MaterialType.transparency,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.exit_to_app_rounded, color: AppColors.logoutColor, size: 40),
                        const SizedBox(height: 16),
                        Text("Logout", style: AppTextStyles.cardTitle.copyWith(fontSize: 20)),
                        const SizedBox(height: 10),
                        Text("Are you sure you want to log out?", textAlign: TextAlign.center, style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () async {
                            await AuthService.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/loginscreen', (route) => false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.logoutColor,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: Text("Logout", style: AppTextStyles.buttonText.copyWith(fontSize: 15)),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Cancel", style: AppTextStyles.poppins(15, AppColors.textSecondary, FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────