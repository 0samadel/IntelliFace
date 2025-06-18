// ────────────────────────────────────────────────────────────────────────────────
// File    : middleware/uploadMiddleware.js
// Purpose : Handles file uploads using Multer (profile images with validation)
// Access  : Used by routes that require image uploads (e.g., profile picture upload)
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports & Constants
 * ========================================================================== */
const multer = require('multer');
const path = require('path');
const fs = require('fs'); // Used to ensure upload directories exist

// Subfolder for profile images: uploads/profiles/
const UPLOADS_PROFILE_FOLDER = path.join('uploads', 'profiles');
const fullUploadPath = path.join(__dirname, '..', UPLOADS_PROFILE_FOLDER);

/* ============================================================================
 * 2. Ensure Upload Directory Exists
 * ========================================================================== */
if (!fs.existsSync(fullUploadPath)) {
  try {
    fs.mkdirSync(fullUploadPath, { recursive: true }); // Creates uploads/profiles/ if not present
    console.log(`✅ Uploads directory created: ${fullUploadPath}`);
  } catch (err) {
    console.error(`❌ Error creating uploads directory ${fullUploadPath}:`, err);
    // Optional: throw err to stop app on startup failure
  }
}

/* ============================================================================
 * 3. Configure Multer Storage
 * ========================================================================== */
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, UPLOADS_PROFILE_FOLDER); // Relative to project root
  },
  filename: function (req, file, cb) {
    const userIdPart = req.user && req.user.userId ? req.user.userId : 'unknownUser';
    const uniqueSuffix = `${userIdPart}-${Date.now()}${path.extname(file.originalname)}`;
    cb(null, `${file.fieldname}-${uniqueSuffix}`);
  }
});

/* ============================================================================
 * 4. File Type Validation (Only Images)
 * ========================================================================== */
const fileFilter = (req, file, cb) => {
  const allowedExtensions = /\.(jpg|jpeg|png|gif|webp)$/i;
  if (!file.originalname.match(allowedExtensions)) {
    req.fileValidationError = 'Only image files are allowed!'; // Used later for response
    return cb(null, false); // Reject silently
  }
  cb(null, true); // Accept file
};

/* ============================================================================
 * 5. Multer Upload Config (5MB Limit)
 * ========================================================================== */
const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: fileFilter
});

/* ============================================================================
 * 6. Middleware Wrapper (Custom Error Handling)
 * ========================================================================== */
/**
 * Returns an Express middleware that handles single image uploads with custom error handling.
 *
 * @param {string} fieldName - Name of the form-data field (e.g., 'profileImage')
 * @returns {Function} Express middleware
 */
const handleMulterUpload = (fieldName) => (req, res, next) => {
  const uploader = upload.single(fieldName);

  uploader(req, res, function (err) {
    if (req.fileValidationError) {
      return res.status(400).json({ success: false, message: req.fileValidationError });
    }

    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: `File too large. Max size is ${upload.limits.fileSize / (1024 * 1024)}MB.`
        });
      }
      return res.status(400).json({ success: false, message: `Multer error: ${err.message}` });
    }

    if (err) {
      return res.status(500).json({ success: false, message: `File upload error: ${err.message}` });
    }

    // Proceed if no errors
    next();
  });
};

/* ============================================================================
 * 7. Export Middleware
 * ========================================================================== */
module.exports = handleMulterUpload;
/* ───────────────────────────────────────────────────────────────────────────── */
