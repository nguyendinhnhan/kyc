import { Schema, model } from 'mongoose';

const schema = new Schema({
  _id: { type: String, required: true },
  userId: { type: Schema.Types.ObjectId, required: true, index: true },
  refreshHash: { type: String, required: true, select: false },
  expiresAt: { type: Date, required: true, expires: 0 },
});
export const Session = model('Session', schema);
