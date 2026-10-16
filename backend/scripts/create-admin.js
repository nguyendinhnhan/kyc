#!/usr/bin/env node

/**
 * Script to create an admin user
 * Usage: node scripts/create-admin.js <email> <password>
 * Example: node scripts/create-admin.js admin@kyc.com Admin123!
 */

const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
require('dotenv').config();

// User schema (same as in src/models/User.ts)
const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email address'],
    },
    password: {
      type: String,
      required: true,
      minlength: 8,
    },
    fullName: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },
  },
  {
    timestamps: true,
  }
);

const User = mongoose.model('User', userSchema);

async function createAdmin() {
  const args = process.argv.slice(2);

  if (args.length !== 2) {
    console.error('Usage: node scripts/create-admin.js <email> <password>');
    console.error('Example: node scripts/create-admin.js admin@kyc.com Admin123!');
    process.exit(1);
  }

  const [email, password] = args;

  // Validate password length
  if (password.length < 8) {
    console.error('Error: Password must be at least 8 characters long');
    process.exit(1);
  }

  try {
    // Connect to MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/kyc';
    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('✓ Connected to MongoDB');

    // Check if user already exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      console.log(`\n⚠ User with email ${email} already exists`);
      
      // Update to admin if not already
      if (existingUser.role !== 'admin') {
        existingUser.role = 'admin';
        await existingUser.save();
        console.log(`✓ Updated user ${email} to admin role`);
      } else {
        console.log(`✓ User is already an admin`);
      }
      
      process.exit(0);
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create admin user
    const adminUser = new User({
      email: email.toLowerCase(),
      password: hashedPassword,
      fullName: 'Admin User',
      role: 'admin',
    });

    await adminUser.save();

    console.log('\n✓ Admin user created successfully!');
    console.log('\nAdmin credentials:');
    console.log(`  Email: ${email}`);
    console.log(`  Password: ${password}`);
    console.log(`  Role: admin`);
    console.log('\nYou can now login with these credentials in Postman.');

    process.exit(0);
  } catch (error) {
    console.error('\n✗ Error creating admin user:');
    console.error(error.message);
    process.exit(1);
  }
}

createAdmin();
