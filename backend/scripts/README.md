# Backend Scripts

This directory contains utility scripts for the KYC backend.

## Available Scripts

### create-admin.js

Create an admin user for testing admin endpoints.

**Usage:**
```bash
node scripts/create-admin.js <email> <password>
```

**Example:**
```bash
node scripts/create-admin.js admin@kyc.com Admin123!
```

**What it does:**
- Connects to MongoDB
- Creates a new user with admin role
- If user already exists, updates their role to admin
- Hashes password using bcrypt

**Output:**
```
✓ Connected to MongoDB
✓ Admin user created successfully!

Admin credentials:
  Email: admin@kyc.com
  Password: Admin123!
  Role: admin

You can now login with these credentials in Postman.
```

**Notes:**
- Password must be at least 8 characters
- Email is case-insensitive (stored as lowercase)
- If the user already exists, it will be updated to admin role
- Uses the `MONGODB_URI` from `.env` file

### clean-db.js

Clean the database by removing all documents from all collections.

**Usage:**
```bash
node scripts/clean-db.js
```

**What it does:**
- Connects to MongoDB
- Deletes all documents from all collections
- Shows count of deleted documents per collection
- Provides next steps guidance

**Output:**
```
🗑️  Cleaning database...

✓ Connected to MongoDB

✓ Cleared users (3 documents)
✓ Cleared submissions (5 documents)
✓ Cleared documents (2 documents)
- Skipped selfies (empty)

✅ Database cleaned successfully!
   Total documents removed: 10

💡 Next steps:
   1. Create admin user: node scripts/create-admin.js admin@kyc.com Admin123!
   2. Register test user via Postman
   3. Test the complete KYC flow
```

**⚠️ Warning:**
- This will delete ALL data in the database
- Cannot be undone
- Use with caution in production environments

**When to use:**
- Starting fresh testing
- Removing test data
- Resetting development environment

## Creating Additional Scripts

When creating new scripts:
1. Use CommonJS modules (require/module.exports) for Node.js compatibility
2. Load environment variables with `require('dotenv').config()`
3. Include usage instructions in comments
4. Add proper error handling and exit codes
5. Document the script in this README
