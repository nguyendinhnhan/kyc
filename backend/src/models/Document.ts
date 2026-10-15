import { Schema, model, Document, Types } from 'mongoose';

export interface IDocument extends Document {
  userId: Types.ObjectId;
  type: 'passport' | 'id_card' | 'drivers_license' | 'residence_permit';
  documentNumber: string;
  filePath: string;
  fileName: string;
  mimeType: string;
  fileSize: number;
  uploadedAt: Date;
  status: 'pending' | 'approved' | 'rejected';
  createdAt: Date;
  updatedAt: Date;
}

const documentSchema = new Schema<IDocument>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      required: true,
      enum: ['passport', 'id_card', 'drivers_license', 'residence_permit'],
    },
    documentNumber: {
      type: String,
      required: true,
      trim: true,
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
    },
    fileSize: {
      type: Number,
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },
    uploadedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Index for querying by userId and type
documentSchema.index({ userId: 1, type: 1 }, { unique: true });

export const DocumentModel = model<IDocument>('Document', documentSchema);
