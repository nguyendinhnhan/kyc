import { FastifyRequest, FastifyReply } from 'fastify';
import { SelfieModel } from '../models/Selfie';
import { SubmissionModel } from '../models/Submission';
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

export async function uploadSelfieHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;

    // Get the file from multipart request
    const file = await request.file();
    
    if (!file) {
      return reply.status(400).send({ error: 'No file uploaded' });
    }

    // Validate file type
    const mimeType = file.mimetype;
    if (!['image/jpeg', 'image/png', 'image/jpg'].includes(mimeType)) {
      return reply.status(400).send({ error: 'File must be an image (JPEG, PNG, or JPG)' });
    }

    // Create uploads directory if it doesn't exist
    const uploadsDir = path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // Read file buffer
    const buffer = await file.toBuffer();

    // Determine file extension
    let fileExtension = '.jpg';
    if (mimeType === 'image/png') {
      fileExtension = '.png';
    }

    // Save file with unique name
    const uniqueFilename = `${uuidv4()}${fileExtension}`;
    const filePath = path.join(uploadsDir, uniqueFilename);
    fs.writeFileSync(filePath, buffer);

    // Update or create selfie record (upsert)
    const selfie = await SelfieModel.findOneAndUpdate(
      { userId },
      {
        userId,
        filePath,
        fileName: file.filename,
        mimeType,
        fileSize: buffer.length,
        uploadedAt: new Date(),
        status: 'pending',
      },
      {
        new: true,
        upsert: true,
      }
    );

    // Clear selfie from submission rejection details
    await clearRejectionField(userId, 'selfie');

    return reply.status(201).send({
      message: 'Selfie uploaded successfully',
      selfie,
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Failed to upload selfie' });
  }
}

export async function getSelfieHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;

    const selfie = await SelfieModel.findOne({ userId });

    return reply.status(200).send({
      selfie,
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Failed to retrieve selfie' });
  }
}

export async function getSelfieImageHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;

    const selfie = await SelfieModel.findOne({ userId });

    if (!selfie) {
      return reply.status(404).send({ error: 'Selfie not found' });
    }

    if (!fs.existsSync(selfie.filePath)) {
      return reply.status(404).send({ error: 'Image file not found' });
    }

    const imageBuffer = fs.readFileSync(selfie.filePath);
    reply.header('Content-Type', selfie.mimeType);
    reply.header('Content-Length', imageBuffer.length);
    return reply.status(200).send(imageBuffer);
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Failed to retrieve selfie image' });
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
    console.error('Error clearing rejection field:', error);
  }
}
