// ────────────────────────────────────────────────────────────────────────────────
// File    : controllers/faceController.js
// Purpose : Controller logic for face enrollment and verification.
// ────────────────────────────────────────────────────────────────────────────────

const axios = require('axios');
const FormData = require('form-data');
const User = require('../models/User');

const PYTHON_SERVICE_URL = 'https://face-rec-service-1.onrender.com';
const AXIOS_TIMEOUT = 90000; // 90 seconds

/**
 * @controller  enrollFace
 * @desc        Handles face enrollment for the Admin Panel.
 */
exports.enrollFace = async (req, res, next) => {
  try {
    const { userId } = req.params;
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided.' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }
    
    const form = new FormData();
    // Use the buffer from memoryStorage and provide a placeholder filename.
    form.append('face', req.file.buffer, { filename: req.file.originalname });

    const pyResponse = await axios.post(`${PYTHON_SERVICE_URL}/generate-embedding`, form, {
      timeout: AXIOS_TIMEOUT,
    });

    const { embedding } = pyResponse.data;
    if (!embedding) {
      return res.status(400).json({ message: 'No face detected in the image.' });
    }

    user.faceEmbeddings = embedding;
    await user.save();
    res.status(200).json({ message: 'Face enrolled successfully.' });

  } catch (error) {
    console.error('Enroll Face Controller Error:', error.response?.data || error.message);
    next(error); // Pass error to the next error-handling middleware
  }
};

/**
 * @controller  verifyFace
 * @desc        Handles face verification for the Employee App attendance check.
 */
exports.verifyFace = async (req, res, next) => {
    try {
        const userId = req.user.userId; // Get user ID from the JWT token
        if (!req.file) {
            return res.status(400).json({ message: 'No image file provided for verification.' });
        }

        const user = await User.findById(userId).select('+faceEmbeddings');
        if (!user || !user.faceEmbeddings?.length) {
            return res.status(404).json({ message: 'Your face is not enrolled. Please contact an administrator.' });
        }

        const form = new FormData();
        form.append('face', req.file.buffer, { filename: req.file.originalname });
        form.append('stored_embedding', JSON.stringify(user.faceEmbeddings));

        const pyResponse = await axios.post(`${PYTHON_SERVICE_URL}/compare-faces`, form, {
            timeout: AXIOS_TIMEOUT
        });
        
        if (pyResponse.data.is_match) {
            return res.json({ verified: true, message: 'Face verified successfully.' });
        } else {
            return res.status(401).json({ verified: false, message: 'Face did not match.' });
        }

    } catch(error) {
        console.error('Verify Face Controller Error:', error.response?.data || error.message);
        next(error);
    }
};