import mongoose from 'mongoose';
import { config } from '../config';

export class Database {
  private static instance: Database;
  private connected = false;

  private constructor() {}

  static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  async connect(): Promise<void> {
    if (this.connected) {
      return;
    }

    try {
      await mongoose.connect(config.mongodb.uri);
      this.connected = true;
      console.log('✅ MongoDB connected successfully');

      mongoose.connection.on('error', (error) => {
        console.error('❌ MongoDB connection error:', error);
        this.connected = false;
      });

      mongoose.connection.on('disconnected', () => {
        console.warn('⚠️  MongoDB disconnected');
        this.connected = false;
      });
    } catch (error) {
      console.error('❌ Failed to connect to MongoDB:', error);
      throw error;
    }
  }

  async disconnect(): Promise<void> {
    if (!this.connected) {
      return;
    }

    await mongoose.disconnect();
    this.connected = false;
    console.log('🔌 MongoDB disconnected');
  }

  isConnected(): boolean {
    return this.connected;
  }
}

export const database = Database.getInstance();
