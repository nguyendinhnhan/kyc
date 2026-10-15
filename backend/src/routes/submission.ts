import { FastifyRequest, FastifyReply } from 'fastify';
import { SubmissionModel } from '../models/Submission';
import { PersonalDetails } from '../models/PersonalDetails';
import { DocumentModel } from '../models/Document';
import { SelfieModel } from '../models/Selfie';

export async function submitKYCHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;

    // Check if personal details exist
    const personalDetails = await PersonalDetails.findOne({ userId });
    if (!personalDetails) {
      return reply.status(400).send({ 
        error: 'Personal details are required before submission' 
      });
    }

    // Check if at least one document exists
    const documents = await DocumentModel.find({ userId });
    if (!documents || documents.length === 0) {
      return reply.status(400).send({ 
        error: 'At least one document is required before submission' 
      });
    }

    // Check if selfie exists
    const selfie = await SelfieModel.findOne({ userId });
    if (!selfie) {
      return reply.status(400).send({ 
        error: 'Selfie is required before submission' 
      });
    }

    // Create or update submission
    const submission = await SubmissionModel.findOneAndUpdate(
      { userId },
      {
        userId,
        status: 'submitted',
        submittedAt: new Date(),
      },
      {
        new: true,
        upsert: true,
      }
    );

    return reply.status(200).send({
      message: 'KYC submitted successfully',
      submission,
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Failed to submit KYC' });
  }
}

export async function getSubmissionHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;

    const submission = await SubmissionModel.findOne({ userId });

    return reply.status(200).send({
      submission: submission || null,
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Failed to retrieve submission' });
  }
}
