import { Schema, model, Document, Types } from 'mongoose';

export interface ISelfie extends Document {
  userId: Types.ObjectId;
  filePath: string;
  fileName: string;
  mimeType: string;
  fileSize: number;
  uploadedAt: Date;
  status: 'pending' | 'approved' | 'rejected';
}

const selfieSchema = new Schema<ISelfie>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true, // One selfie per user
    },
    filePath: {
      type: String,
      required: true,
    },
    fileName: {
      type: String,
      required: true,
    },
    mimeType: {
      type: String,
      required: true,
      enum: ['image/jpeg', 'image/png', 'image/jpg'],
    },
    fileSize: {
      type: Number,
      required: true,
      min: 0,
    },
    uploadedAt: {
      type: Date,
      default: Date.now,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, result) {
        delete (result as Partial<typeof result>).filePath;
        return result;
      },
    },
  }
);

export const SelfieModel = model<ISelfie>('Selfie', selfieSchema);
