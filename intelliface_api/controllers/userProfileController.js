// ────────────────────────────────────────────────────────────────────────────────
// controllers/userProfileController.js
// ────────────────────────────────────────────────────────────────────────────────
// Purpose  : Manage the logged-in user's own profile (GET & UPDATE)
// Endpoints: /api/profile/me
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const User = require('../models/User');
const fs = require('fs');
const path = require('path');

/* ============================================================================
 * 2. Get Logged-in User's Profile
 * ========================================================================== */
/**
 * @desc   Get current logged-in user's profile
 * @route  GET /api/profile/me
 * @access Private
 */
exports.getMyProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.userId).populate('department', 'name');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Convert Mongoose doc to plain object and sanitize output
    const userProfile = user.toObject();
    delete userProfile.password;
    delete userProfile.faceEmbeddings;

    res.status(200).json({ success: true, data: userProfile });

  } catch (error) {
    console.error('❌ Error fetching user profile:', error);
    next(error);
  }
};

/* ============================================================================
 * 3. Update Logged-in User's Profile
 * ========================================================================== */
/**
 * @desc   Update current logged-in user's profile
 * @route  PUT /api/profile/me
 * @access Private
 */
exports.updateMyProfile = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { fullName, phone, email, username, address } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // ─────────────────────────────
    // ✅ Basic field updates
    // ─────────────────────────────
    if (fullName) user.fullName = fullName;
    if (phone) user.phone = phone;
    if (address) user.address = address;

    // ─────────────────────────────
    // ✅ Unique email check
    // ─────────────────────────────
    if (email && email !== user.email) {
      const emailExists = await User.findOne({ email, _id: { $ne: userId } });
      if (emailExists) {
        return res.status(400).json({ success: false, message: 'Email already in use by another account.' });
      }
      user.email = email;
    }

    // ─────────────────────────────
    // ✅ Unique username check
    // ─────────────────────────────
    if (username && username !== user.username) {
      const usernameExists = await User.findOne({ username, _id: { $ne: userId } });
      if (usernameExists) {
        return res.status(400).json({ success: false, message: 'Username already taken.' });
      }
      user.username = username;
    }

    // ─────────────────────────────
    // ✅ Handle profile picture upload (if any)
    // ─────────────────────────────
    if (req.file) {
      // Delete old profile picture if it exists and is stored locally
      if (user.profilePicture && user.profilePicture.startsWith('uploads/')) {
        const oldPicPath = path.join(__dirname, '..', user.profilePicture);
        if (fs.existsSync(oldPicPath)) {
          try {
            fs.unlinkSync(oldPicPath);
            console.log('🗑️ Old profile picture deleted:', oldPicPath);
          } catch (unlinkErr) {
            console.error('⚠️ Error deleting old profile picture:', unlinkErr);
          }
        }
      }

      // Save new image path (normalize for cross-platform)
      user.profilePicture = req.file.path.replace(/\\/g, "/");
    }

    // ─────────────────────────────
    // ✅ Save and sanitize response
    // ─────────────────────────────
    const updatedUser = await user.save();
    const userProfile = updatedUser.toObject();
    delete userProfile.password;
    delete userProfile.faceEmbeddings;

    res.status(200).json({
      success: true,
      data: userProfile,
      message: 'Profile updated successfully',
    });

  } catch (error) {
    console.error('❌ Error updating profile:', error);

    if (error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: error.message });
    }

    next(error); // Pass to Express error handler
  }
};
/* ───────────────────────────────────────────────────────────────────────────── */
