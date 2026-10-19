import { FastifyRequest, FastifyReply } from 'fastify';
import { SubmissionModel } from '../models/Submission';
import { PersonalDetails } from '../models/PersonalDetails';
import { DocumentModel } from '../models/Document';
import { SelfieModel } from '../models/Selfie';

export async function submitKYCHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;

    // Check if personal details exist
    const personalDetails = await PersonalDetails.findOne({ userId });
    if (!personalDetails) {
      return reply.status(400).send({
        error: 'Personal details are required before submission',
      });
    }

    // Check if at least one document exists
    const documents = await DocumentModel.find({ userId });
    if (!documents || documents.length === 0) {
      return reply.status(400).send({
        error: 'At least one document is required before submission',
      });
    }

    // Check if selfie exists
    const selfie = await SelfieModel.findOne({ userId });
    if (!selfie) {
      return reply.status(400).send({
        error: 'Selfie is required before submission',
      });
    }

    const key = request.headers['idempotency-key'];
    if (key !== undefined && (typeof key !== 'string' || !/^[a-zA-Z0-9_-]{8,128}$/.test(key))) {
      return reply.status(400).send({ error: 'Invalid idempotency key' });
    }
    // Unique userId prevents concurrent first submissions creating separate records.
    try {
      await SubmissionModel.updateOne(
        { userId },
        { $setOnInsert: { userId, status: 'draft' } },
        { upsert: true }
      );
    } catch (error) {
      if (!(error && typeof error === 'object' && 'code' in error && error.code === 11000))
        throw error;
    }
    let submission = await SubmissionModel.findOne({ userId }).select('+attemptKeys');
    if (key && submission!.attemptKeys.includes(key)) {
      const result = submission!.toObject();
      delete (result as Partial<typeof result>).attemptKeys;
      return reply.status(200).send({ message: 'KYC submitted successfully', submission: result });
    }
    if (submission!.status === 'submitted' || submission!.status === 'under_review') {
      if (key) {
        const acknowledged = await SubmissionModel.findOneAndUpdate(
          { userId, status: { $in: ['submitted', 'under_review'] } },
          {
            $addToSet: { attemptKeys: key },
          },
          { new: true }
        );
        if (!acknowledged)
          return reply
            .status(409)
            .send({ error: 'Submission status changed; reload before continuing' });
        return reply
          .status(200)
          .send({ message: 'KYC submitted successfully', submission: acknowledged });
      }
      const result = submission!.toObject();
      delete (result as Partial<typeof result>).attemptKeys;
      return reply.status(200).send({ message: 'KYC submitted successfully', submission: result });
    }
    if (submission!.status === 'approved')
      return reply.status(409).send({ error: 'Approved applications cannot be resubmitted' });
    submission = await SubmissionModel.findOneAndUpdate(
      {
        userId,
        status: { $in: ['draft', 'rejected'] },
        ...(key ? { attemptKeys: { $ne: key } } : {}),
      },
      {
        $set: { status: 'submitted', submittedAt: new Date() },
        $unset: { rejectionDetails: 1, reviewedAt: 1, reviewedBy: 1, notes: 1 },
        ...(key ? { $addToSet: { attemptKeys: key } } : {}),
      },
      { new: true }
    );
    if (!submission) {
      submission = await SubmissionModel.findOne({ userId });
      if (!submission || !['submitted', 'under_review'].includes(submission.status)) {
        return reply
          .status(409)
          .send({ error: 'Submission status changed; reload before continuing' });
      }
    }

    return reply.status(200).send({
      message: 'KYC submitted successfully',
      submission,
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to submit KYC' });
  }
}

export async function getSubmissionHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;

    const submission = await SubmissionModel.findOne({ userId });

    return reply.status(200).send({
      submission: submission || null,
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to retrieve submission' });
  }
}

export async function resetSubmissionHandler(request: FastifyRequest, reply: FastifyReply) {
  return submitKYCHandler(request, reply);
}
