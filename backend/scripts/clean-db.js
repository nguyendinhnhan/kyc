#!/usr/bin/env node

/**
 * Script to clean the database
 * Usage: node scripts/clean-db.js
 * 
 * This will delete all data from all collections in the database.
 * Use with caution!
 */

const mongoose = require('mongoose');
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
    console.log('\n💡 Next steps:');
    console.log('   1. Create admin user: node scripts/create-admin.js admin@kyc.com Admin123!');
    console.log('   2. Register test user via Postman');
    console.log('   3. Test the complete KYC flow');
    
  } catch (error) {
    console.error('\n❌ Error cleaning database:');
    console.error(error.message);
    process.exit(1);
  }
}

cleanDatabase();
