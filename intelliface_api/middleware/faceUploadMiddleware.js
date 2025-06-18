// ────────────────────────────────────────────────────────────────────────────────
// File    : middleware/faceUploadMiddleware.js
// Purpose : Configures Multer to handle image uploads by storing them in memory
//           as Buffer objects, which is efficient and reliable for cloud services.
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports
 * ========================================================================== */
const multer = require('multer');

/* ============================================================================
 * 2. Configure Multer Storage (In-Memory)
 * ========================================================================== */
// memoryStorage tells Multer to store the file as a Buffer in `req.file.buffer`.
// This avoids writing temporary files to the disk, which is ideal for
// serverless or containerized environments like OnRender.
const storage = multer.memoryStorage();


/* ============================================================================
 * 3. File Filter (Accept only images)
 * ========================================================================== */
const fileFilter = (req, file, cb) => {
  // Check if the file's MIME type starts with 'image/'
  if (file.mimetype.startsWith('image/')) {
    // If it's an image, accept the file.
    cb(null, true);
  } else {
    // If it's not an image, create a specific error and reject the file.
    // This error can be caught by Express error-handling middleware.
    const err = new Error('File is not an image! Please upload only images.');
    err.status = 400; // Bad Request
    cb(err, false);
  }
};


/* ============================================================================
 * 4. Create and Configure Multer Upload Instance
 * ========================================================================== */
const upload = multer({
  storage: storage,       // Use the in-memory storage configuration.
  limits: {
    fileSize: 10 * 1024 * 1024 // Set a generous 10MB file size limit.
  },
  fileFilter: fileFilter    // Use the image-only file filter.
});


/* ============================================================================
 * 5. Export Middleware
 * ========================================================================== */
module.exports = upload;