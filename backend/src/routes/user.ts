import { FastifyRequest, FastifyReply, FastifyInstance } from 'fastify';
import { PersonalDetails } from '../models/PersonalDetails';
import { PersonalDetailsInput } from '../schemas/personalDetails';
import { SubmissionModel } from '../models/Submission';

export async function savePersonalDetailsHandler(
  request: FastifyRequest<{ Body: PersonalDetailsInput }>,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;
    const personalDetailsData = request.body;

    // Check if personal details already exist
    let personalDetails = await PersonalDetails.findOne({ userId });

    if (personalDetails) {
      // Update existing
      personalDetails = await PersonalDetails.findOneAndUpdate(
        { userId },
        {
          dateOfBirth: new Date(personalDetailsData.dateOfBirth),
          nationality: personalDetailsData.nationality,
          phone: personalDetailsData.phone,
          address: personalDetailsData.address,
        },
        { new: true }
      );

      // Clear personalDetails from submission rejection details
      await clearRejectionField(userId, 'personalDetails');

      return reply.status(200).send({
        message: 'Personal details updated successfully',
        personalDetails,
      });
    } else {
      // Create new
      personalDetails = await PersonalDetails.create({
        userId,
        dateOfBirth: new Date(personalDetailsData.dateOfBirth),
        nationality: personalDetailsData.nationality,
        phone: personalDetailsData.phone,
        address: personalDetailsData.address,
      });

      return reply.status(201).send({
        message: 'Personal details saved successfully',
        personalDetails,
      });
    }
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Internal server error' });
  }
}

export async function getPersonalDetailsHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;

    const personalDetails = await PersonalDetails.findOne({ userId });

    if (!personalDetails) {
      return reply.status(404).send({ error: 'Personal details not found' });
    }

    return reply.status(200).send({ personalDetails });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Internal server error' });
  }
}

// Helper function to clear a specific field from rejection details
async function clearRejectionField(
  userId: string,
  field: 'personalDetails' | 'documents' | 'selfie'
) {
  try {
    const submission = await SubmissionModel.findOne({ userId });
    
    if (submission && submission.rejectionDetails) {
      // Clear the specific field
      if (field === 'personalDetails') {
        submission.rejectionDetails.personalDetails = undefined;
      } else if (field === 'documents') {
        submission.rejectionDetails.documents = undefined;
      } else if (field === 'selfie') {
        submission.rejectionDetails.selfie = undefined;
      }
      
      // Check if all rejection fields are now empty
      const hasAnyErrors = 
        submission.rejectionDetails.personalDetails ||
        submission.rejectionDetails.documents ||
        submission.rejectionDetails.selfie;
      
      // If no errors remain, reset the submission to draft
      if (!hasAnyErrors) {
        submission.status = 'draft';
        submission.rejectionDetails = undefined;
        submission.reviewedAt = undefined;
      }
      
      await submission.save();
    }
  } catch (error) {
    // Silently handle - rejection clearing is best-effort
  }
}

export default async function userRoutes(fastify: FastifyInstance) {
  fastify.post('/personal-details', savePersonalDetailsHandler);
  fastify.get('/personal-details', getPersonalDetailsHandler);
}
