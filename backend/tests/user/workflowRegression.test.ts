import { beforeAll, beforeEach, afterAll, describe, it, expect } from 'vitest';
import { buildApp } from '../../src/server';
import { database } from '../../src/plugins/database';
import { User } from '../../src/models/User';
import { SubmissionModel } from '../../src/models/Submission';
import { PersonalDetails } from '../../src/models/PersonalDetails';
import { DocumentModel } from '../../src/models/Document';
import { SelfieModel } from '../../src/models/Selfie';
import type { FastifyInstance } from 'fastify';

describe('submission invariants', () => {
  let app: FastifyInstance, token: string, userId: string;
  beforeAll(async () => {
    app = await buildApp();
  });
  afterAll(async () => {
    await app.close();
    await database.disconnect();
  });
  beforeEach(async () => {
    for (const m of [User, SubmissionModel, PersonalDetails, DocumentModel, SelfieModel])
      await (m as any).deleteMany({});
    await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: {
        email: 'workflow@example.com',
        password: 'synthetic-password',
        fullName: 'Synthetic User',
      },
    });
    const login = (
      await app.inject({
        method: 'POST',
        url: '/auth/login',
        payload: { email: 'workflow@example.com', password: 'synthetic-password' },
      })
    ).json();
    token = login.accessToken;
    userId = login.user.id;
    await PersonalDetails.create({
      userId,
      dateOfBirth: new Date('1990-01-01'),
      nationality: 'US',
      phone: '+1234567890',
      address: {
        street: 'Synthetic Street',
        city: 'City',
        state: 'State',
        postalCode: '12345',
        country: 'US',
      },
    });
    await DocumentModel.create({
      userId,
      type: 'passport',
      documentNumber: 'SYNTHETIC',
      filePath: '/synthetic/document',
      fileName: 'synthetic.png',
      mimeType: 'image/png',
      fileSize: 1,
    });
    await SelfieModel.create({
      userId,
      filePath: '/synthetic/selfie',
      fileName: 'synthetic.png',
      mimeType: 'image/png',
      fileSize: 1,
    });
  });
  const submit = (key: string) =>
    app.inject({
      method: 'POST',
      url: '/user/submit',
      headers: { authorization: `Bearer ${token}`, 'idempotency-key': key },
    });
  it('does not move an approved submission back to submitted', async () => {
    await SubmissionModel.create({ userId, status: 'approved' });
    expect((await submit('approved-attempt')).statusCode).toBe(409);
    expect((await SubmissionModel.findOne({ userId }))!.status).toBe('approved');
  });
  it('deduplicates concurrent submissions and replays a lost response without changing its timestamp', async () => {
    const responses = await Promise.all([submit('same-attempt'), submit('same-attempt')]);
    expect(responses.map((r) => r.statusCode)).toEqual([200, 200]);
    const first = responses[0].json().submission;
    await new Promise((r) => setTimeout(r, 20));
    const replay = (await submit('same-attempt')).json().submission;
    expect(replay._id).toBe(first._id);
    expect(replay.submittedAt).toBe(first.submittedAt);
    expect(await SubmissionModel.countDocuments({ userId })).toBe(1);
  });
  it('rejects edits while approved', async () => {
    await SubmissionModel.create({ userId, status: 'approved' });
    const response = await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        dateOfBirth: '1990-01-01',
        nationality: 'US',
        phone: '+1234567890',
        address: {
          street: 'Changed Street',
          city: 'City',
          state: 'State',
          postalCode: '12345',
          country: 'US',
        },
      },
    });
    expect(response.statusCode).toBe(409);
    expect((await PersonalDetails.findOne({ userId }))!.address.street).toBe('Synthetic Street');
  });
  it('keeps a rejection until the user explicitly resubmits', async () => {
    await SubmissionModel.create({
      userId,
      status: 'rejected',
      rejectionDetails: {
        personalDetails: { phone: 'Please correct' },
        generalNotes: 'Please review all information',
      },
    });
    const original = await PersonalDetails.findOne({ userId });
    await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: { authorization: `Bearer ${token}` },
      payload: {
        dateOfBirth: '1990-01-01',
        nationality: original!.nationality,
        phone: '+1234567891',
        address: original!.address,
      },
    });
    const edited = await SubmissionModel.findOne({ userId });
    expect(edited!.status).toBe('rejected');
    expect(edited!.rejectionDetails?.generalNotes).toBe('Please review all information');
    expect((await submit('resubmit-attempt')).statusCode).toBe(200);
    expect(
      (await SubmissionModel.findOne({ userId }))!.rejectionDetails?.generalNotes
    ).toBeUndefined();
  });
  it('allows only one concurrent administrative decision and preserves the winner', async () => {
    await User.findByIdAndUpdate(userId, { role: 'admin' });
    const admin = (
      await app.inject({
        method: 'POST',
        url: '/auth/login',
        payload: { email: 'workflow@example.com', password: 'synthetic-password' },
      })
    ).json().accessToken;
    const record = await SubmissionModel.create({ userId, status: 'submitted' });
    const responses = await Promise.all([
      app.inject({
        method: 'POST',
        url: `/admin/submissions/${record._id}/approve`,
        headers: { authorization: `Bearer ${admin}` },
        payload: {},
      }),
      app.inject({
        method: 'POST',
        url: `/admin/submissions/${record._id}/reject`,
        headers: { authorization: `Bearer ${admin}` },
        payload: { rejectionDetails: { generalNotes: 'Synthetic review' } },
      }),
    ]);
    expect(responses.map((r) => r.statusCode).sort()).toEqual([200, 409]);
  });

  it('an acknowledged key cannot resubmit an application after a reviewer rejects it', async () => {
    expect((await submit('initial-attempt')).statusCode).toBe(200);
    expect((await submit('second-delayed-attempt')).statusCode).toBe(200);
    await SubmissionModel.updateOne(
      { userId },
      { $set: { status: 'rejected', rejectionDetails: { generalNotes: 'Synthetic review' } } }
    );
    expect((await submit('second-delayed-attempt')).json().submission.status).toBe('rejected');
    expect((await SubmissionModel.findOne({ userId }))!.status).toBe('rejected');
    expect((await submit('explicit-new-attempt')).json().submission.status).toBe('submitted');
  });
});
