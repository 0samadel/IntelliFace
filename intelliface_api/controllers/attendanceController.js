// ────────────────────────────────────────────────────────────────────────────────
// File    : controllers/attendanceController.js (FINALIZED)
// Purpose : Handles check-in/out logic by first verifying the face via the
//           face verification service, then handling attendance logic.
// ────────────────────────────────────────────────────────────────────────────────

const Attendance = require('../models/Attendance');
const User = require('../models/User');
const Location = require('../models/Location');
const moment = require('moment');
const axios = require('axios');
const FormData = require('form-data');

const PYTHON_SERVICE_URL = 'https://face-rec-service-1.onrender.com';
const AXIOS_TIMEOUT = 90000;

function getDistanceInMeters(lat1, lon1, lat2, lon2) {
    const R = 6371000;
    const toRad = (deg) => deg * Math.PI / 180;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

// ================== CHECK-IN ==================
exports.checkIn = async (req, res, next) => {
    const { latitude, longitude } = req.body;
    const userId = req.user.userId;

    if (!req.file || !latitude || !longitude) {
        return res.status(400).json({ message: 'Face image, latitude, and longitude are required.' });
    }

    try {
        const user = await User.findById(userId).select('+faceEmbeddings').populate({
            path: 'department',
            populate: { path: 'location' }
        });

        if (!user || !user.faceEmbeddings?.length) {
            return res.status(404).json({ message: 'User not found or face is not enrolled.' });
        }

        const embedding = Array.isArray(user.faceEmbeddings) && user.faceEmbeddings.length > 0
            ? user.faceEmbeddings[0]
            : null;

        if (!embedding) {
            return res.status(400).json({ message: 'User face embedding is invalid.' });
        }

        const form = new FormData();
        form.append('face', req.file.buffer, { filename: req.file.originalname });
        form.append('stored_embedding', JSON.stringify(embedding));

        const pyResponse = await axios.post(`${PYTHON_SERVICE_URL}/compare-faces`, form, {
            timeout: AXIOS_TIMEOUT
        });

        if (!pyResponse.data.is_match) {
            return res.status(401).json({ message: 'Face verification failed.' });
        }

        if (!user.department?.location) {
            return res.status(400).json({ message: 'You are not assigned to a department with a location.' });
        }

       const officeLocation = user.department.location;
       const distance = getDistanceInMeters(latitude, longitude, officeLocation.latitude, officeLocation.longitude);
       if (distance > officeLocation.radius) {
         return res.status(403).json({ message: `Check-in denied. You are outside the work radius.` });
      }

        const todayStart = moment().startOf('day').toDate();
        const todayEnd = moment().endOf('day').toDate();
        const existingRecord = await Attendance.findOne({ userId, checkInTime: { $gte: todayStart, $lte: todayEnd } });
        if (existingRecord) {
            return res.status(400).json({ message: 'You have already checked in today.' });
        }

        const checkInTime = moment();
        const onTimeDeadline = moment().startOf('day').hour(9).minute(0).second(0);
        const status = checkInTime.isAfter(onTimeDeadline) ? 'Late' : 'Present';

        const attendance = new Attendance({
            userId,
            checkInTime: checkInTime.toDate(),
            status,
            location: { latitude, longitude }
        });

        await attendance.save();

        const newRecord = await Attendance.findById(attendance._id).populate('userId', 'fullName employeeId');
        res.status(201).json({ message: `Checked in successfully as ${status}!`, attendance: newRecord });

    } catch (error) {
        console.error('Check-in Controller Error:', error.response?.data || error.message);
        const message = error.response?.data?.message || "Check-in process failed.";
        const status = error.response?.status || 500;
        res.status(status).json({
            message,
            error: error.response?.data || error.message || "Unknown error"
        });
    }
};

// ================== CHECK-OUT ==================
exports.checkOut = async (req, res, next) => {
    const userId = req.user.userId;
    if (!req.file) {
        return res.status(400).json({ message: 'Face image is required for check-out.' });
    }

    try {
        const user = await User.findById(userId).select('+faceEmbeddings');
        if (!user || !user.faceEmbeddings?.length) {
            return res.status(404).json({ message: 'User not found or face not enrolled.' });
        }

        const embedding = Array.isArray(user.faceEmbeddings) && user.faceEmbeddings.length > 0
            ? user.faceEmbeddings[0]
            : null;

        if (!embedding) {
            return res.status(400).json({ message: 'User face embedding is invalid.' });
        }

        const form = new FormData();
        form.append('face', req.file.buffer, { filename: req.file.originalname });
        form.append('stored_embedding', JSON.stringify(embedding));

        const pyResponse = await axios.post(`${PYTHON_SERVICE_URL}/compare-faces`, form, {
            timeout: AXIOS_TIMEOUT
        });

        if (!pyResponse.data.is_match) {
            return res.status(401).json({ message: 'Face verification failed for check-out.' });
        }

        const todayStart = moment().startOf('day').toDate();
        const todayEnd = moment().endOf('day').toDate();
        const attendanceRecord = await Attendance.findOne({ userId, checkInTime: { $gte: todayStart, $lte: todayEnd } });

        if (!attendanceRecord) {
            return res.status(404).json({ message: 'No check-in record found for today.' });
        }
        if (attendanceRecord.checkOutTime) {
            return res.status(400).json({ message: 'You have already checked out today.' });
        }

        attendanceRecord.checkOutTime = new Date();
        await attendanceRecord.save();

        const updatedRecord = await Attendance.findById(attendanceRecord._id).populate('userId', 'fullName employeeId');
        res.status(200).json({ message: 'Checked out successfully!', attendance: updatedRecord });

    } catch (error) {
        console.error('Check-out Controller Error:', error.response?.data || error.message);
        const message = error.response?.data?.message || "Check-out process failed.";
        const status = error.response?.status || 500;
        res.status(status).json({
            message,
            error: error.response?.data || error.message || "Unknown error"
        });
    }
};

// ================== ADMIN FUNCTIONS ==================
exports.getAllAttendance = async (req, res) => {
    try {
        const records = await Attendance.find().sort({ checkInTime: -1 }).populate('userId', 'fullName username employeeId');
        res.json(records);
    } catch (err) {
        res.status(500).json({ message: 'Server error: ' + err.message });
    }
};

exports.deleteAttendance = async (req, res) => {
    try {
        const deletedRecord = await Attendance.findByIdAndDelete(req.params.id);
        if (!deletedRecord) {
            return res.status(404).json({ message: 'Attendance record not found.' });
        }
        res.json({ message: 'Attendance record deleted successfully.' });
    } catch (err) {
        res.status(500).json({ message: 'Server error: ' + err.message });
    }
};

exports.getTodaysAttendanceForUser = async (req, res) => {
    try {
        const userIdFromToken = req.user.userId;
        const todayStart = moment().startOf('day').toDate();
        const todayEnd = moment().endOf('day').toDate();
        const attendanceRecord = await Attendance.findOne({
            userId: userIdFromToken,
            checkInTime: { $gte: todayStart, $lte: todayEnd }
        }).populate('userId', 'fullName employeeId');

        res.status(200).json(attendanceRecord); // Send record or null
    } catch (err) {
        res.status(500).json({ message: 'Server error while fetching today\'s attendance.' });
    }
};
