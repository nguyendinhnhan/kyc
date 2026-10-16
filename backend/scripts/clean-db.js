#!/usr/bin/env node

/**
 * Script to clean the database and uploaded files
 * Usage: node scripts/clean-db.js
 * 
 * This will delete all data from all collections and remove all uploaded files.
 * Use with caution!
 */

const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function cleanDatabase() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/kyc';
    console.log('🗑️  Cleaning database...\n');
    
    await mongoose.connect(mongoUri);
    console.log('✓ Connected to MongoDB\n');
    
    const db = mongoose.connection.db;
    const collectionList = await db.listCollections().toArray();
    let totalDocuments = 0;
    
    if (collectionList.length === 0) {
      console.log('No collections found in database.');
    } else {
      for (const collectionInfo of collectionList) {
        const collection = db.collection(collectionInfo.name);
        const count = await collection.countDocuments();
        totalDocuments += count;
        
        if (count > 0) {
          await collection.deleteMany({});
          console.log(`✓ Cleared ${collectionInfo.name} (${count} documents)`);
        } else {
          console.log(`- Skipped ${collectionInfo.name} (empty)`);
        }
      }
    }
    
    console.log(`\n✅ Database cleaned successfully!`);
    console.log(`   Total documents removed: ${totalDocuments}`);
    
    await mongoose.disconnect();
    
    // Clean uploaded files
    console.log('\n🗑️  Cleaning uploaded files...\n');
    const uploadsDir = path.join(__dirname, '..', 'uploads');
    
    if (!fs.existsSync(uploadsDir)) {
      console.log('No uploads directory found.');
    } else {
      const files = fs.readdirSync(uploadsDir);
      let deletedCount = 0;
      let totalSize = 0;
      
      for (const file of files) {
        const filePath = path.join(uploadsDir, file);
        const stats = fs.statSync(filePath);
        
        if (stats.isFile()) {
          totalSize += stats.size;
          fs.unlinkSync(filePath);
          deletedCount++;
        }
      }
      
      console.log(`✅ Uploads cleaned successfully!`);
      console.log(`   Files deleted: ${deletedCount}`);
      console.log(`   Space freed: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);
    }
    
    console.log('\n💡 Next steps:');
    console.log('   1. Create admin user: node scripts/create-admin.js admin@kyc.com Admin123!');
    console.log('   2. Register test user via Postman');
    console.log('   3. Test the complete KYC flow');
    
  } catch (error) {
    console.error('\n❌ Error cleaning:');
    console.error(error.message);
    process.exit(1);
  }
}

cleanDatabase();
