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
      await mongoose.connect(config.mongodb.uri, { serverSelectionTimeoutMS: 10000 });
      await Promise.all(Object.values(mongoose.models).map((model) => model.init()));
      this.connected = true;
      console.log('✅ MongoDB connected successfully');

      mongoose.connection.on('error', () => {
        console.error('MongoDB connection error');
        this.connected = false;
      });

      mongoose.connection.on('disconnected', () => {
        console.warn('⚠️  MongoDB disconnected');
        this.connected = false;
      });
    } catch (error) {
      console.error('MongoDB connection failed');
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
