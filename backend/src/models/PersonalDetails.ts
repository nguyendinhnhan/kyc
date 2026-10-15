import { Schema, model, Document, Types } from 'mongoose';

export interface IPersonalDetails extends Document {
  userId: Types.ObjectId;
  dateOfBirth: Date;
  nationality: string;
  phone: string;
  address: {
    street: string;
    city: string;
    state: string;
    postalCode: string;
    country: string;
  };
  createdAt: Date;
  updatedAt: Date;
}

const personalDetailsSchema = new Schema<IPersonalDetails>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },
    dateOfBirth: {
      type: Date,
      required: true,
    },
    nationality: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
      match: [/^\+?[\d\s-]{10,}$/, 'Please provide a valid phone number'],
    },
    address: {
      street: {
        type: String,
        required: true,
        trim: true,
        minlength: 2,
      },
      city: {
        type: String,
        required: true,
        trim: true,
        minlength: 2,
      },
      state: {
        type: String,
        required: true,
        trim: true,
        minlength: 2,
      },
      postalCode: {
        type: String,
        required: true,
        trim: true,
      },
      country: {
        type: String,
        required: true,
        trim: true,
        minlength: 2,
      },
    },
  },
  {
    timestamps: true,
  }
);

export const PersonalDetails = model<IPersonalDetails>(
  'PersonalDetails',
  personalDetailsSchema
);
