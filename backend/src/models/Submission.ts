import { Schema, model, Document, Types } from 'mongoose';

export interface IRejectionDetails {
  personalDetails?: {
    dateOfBirth?: string;
    nationality?: string;
    phone?: string;
    address?: string;
  };
  documents?: {
    imageQuality?: string;
    documentNumber?: string;
    expirationDate?: string;
  };
  selfie?: {
    imageQuality?: string;
    faceMatch?: string;
  };
  generalNotes?: string;
}

export interface ISubmission extends Document {
  userId: Types.ObjectId;
  status: 'draft' | 'submitted' | 'under_review' | 'approved' | 'rejected';
  submittedAt?: Date;
  attemptKeys: string[];
  reviewedAt?: Date;
  reviewedBy?: Types.ObjectId;
  notes?: string;
  rejectionDetails?: IRejectionDetails;
}

const submissionSchema = new Schema<ISubmission>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true, // One submission per user
    },
    status: {
      type: String,
      enum: ['draft', 'submitted', 'under_review', 'approved', 'rejected'],
      default: 'draft',
    },
    attemptKeys: { type: [String], default: [], select: false },
    submittedAt: {
      type: Date,
    },
    reviewedAt: {
      type: Date,
    },
    reviewedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
    notes: {
      type: String,
    },
    rejectionDetails: {
      personalDetails: {
        dateOfBirth: String,
        nationality: String,
        phone: String,
        address: String,
      },
      documents: {
        imageQuality: String,
        documentNumber: String,
        expirationDate: String,
      },
      selfie: {
        imageQuality: String,
        faceMatch: String,
      },
      generalNotes: String,
    },
  },
  {
    timestamps: true,
  }
);

export const SubmissionModel = model<ISubmission>('Submission', submissionSchema);
