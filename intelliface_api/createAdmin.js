// ────────────────────────────────────────────────────────────────────────────────
// Script  : scripts/createAdmin.js      (run with: node scripts/createAdmin.js)
// Purpose : Seed the database with a default super-admin account, if none exists
// Usage   : Only during initial setup or emergency recovery
// ────────────────────────────────────────────────────────────────────────────────

/* ============================================================================
 * 1. Imports & Config
 * ========================================================================== */
require('dotenv').config();                // Load .env first
const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');
const User     = require('../models/User'); // Adjust path if script lives elsewhere

/* ============================================================================
 * 2. Async Seeder Logic
 * ========================================================================== */
async function createAdmin() {
  try {
    // 2A. Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI);
    console.log('🗄️  Connected to MongoDB');

    // 2B. Exit early if an admin already exists
    const existingAdmin = await User.findOne({ username: 'admin' });
    if (existingAdmin) {
      console.log('⚠️  Admin user already exists — no changes made.');
      return process.exit(0);
    }

    // 2C. Hash default password
    const hashedPassword = await bcrypt.hash('admin1234', 10);

    // 2D. Create admin document
    const admin = new User({
      fullName : 'Super Admin',
      email    : 'admin@intelliface.com',
      username : 'admin',
      password : hashedPassword,
      role     : 'admin',
      department: undefined, // Or set to a Department _id if needed
    });

    await admin.save();
    console.log('✅ Admin created  →  username: admin   password: admin1234');
    process.exit(0);

  } catch (err) {
    console.error('❌ Error creating admin:', err.message);
    process.exit(1);
  }
}

/* ============================================================================
 * 3. Run Seeder
 * ========================================================================== */
createAdmin();
/* ───────────────────────────────────────────────────────────────────────────── */
