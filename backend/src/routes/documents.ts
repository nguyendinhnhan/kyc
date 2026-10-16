import { FastifyRequest, FastifyReply, FastifyInstance } from 'fastify';
import { DocumentModel } from '../models/Document';
import { SubmissionModel } from '../models/Submission';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import fs from 'fs';

export async function uploadDocumentHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;
    
    // Get the file
    const file = await request.file();
    if (!file) {
      return reply.status(400).send({ error: 'No file uploaded' });
    }

    // Get fields from file.fields (Fastify multipart stores them here)
    const fields = (file.fields as any) || {};
    const type = fields.type?.value;
    const documentNumber = fields.documentNumber?.value;

    if (!type || !documentNumber) {
      return reply.status(400).send({ error: 'Missing required fields: type, documentNumber' });
    }

    // Validate document type
    const validTypes = ['passport', 'id_card', 'drivers_license', 'residence_permit'];
    if (!validTypes.includes(type)) {
      return reply.status(400).send({ error: 'Invalid document type' });
    }

    // Read file buffer
    const buffer = await file.toBuffer();

    // Create uploads directory if it doesn't exist
    const uploadsDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // Generate unique filename
    const fileExtension = path.extname(file.filename);
    const uniqueFilename = `${uuidv4()}${fileExtension}`;
    const filePath = path.join(uploadsDir, uniqueFilename);

    // Save file
    fs.writeFileSync(filePath, buffer);

    // Check if document already exists for this user and type
    const existingDocument = await DocumentModel.findOne({ userId, type });
    
    if (existingDocument) {
      // Delete old file
      if (fs.existsSync(existingDocument.filePath)) {
        fs.unlinkSync(existingDocument.filePath);
      }
      
      // Update existing document
      existingDocument.documentNumber = documentNumber;
      existingDocument.filePath = filePath;
      existingDocument.fileName = file.filename;
      existingDocument.mimeType = file.mimetype;
      existingDocument.fileSize = buffer.length;
      existingDocument.uploadedAt = new Date();
      await existingDocument.save();

      // Clear documents from submission rejection details
      await clearRejectionField(userId, 'documents');

      return reply.status(200).send({
        message: 'Document updated successfully',
        document: existingDocument,
      });
    }

    // Create new document
    const document = await DocumentModel.create({
      userId,
      type,
      documentNumber,
      filePath,
      fileName: file.filename,
      mimeType: file.mimetype,
      fileSize: buffer.length,
    });

    // Clear documents from submission rejection details
    await clearRejectionField(userId, 'documents');

    return reply.status(201).send({
      message: 'Document uploaded successfully',
      document,
    });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Internal server error' });
  }
}

export async function getDocumentsHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;

    const documents = await DocumentModel.find({ userId }).select('-filePath');

    return reply.status(200).send({ documents });
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Internal server error' });
  }
}

export async function getDocumentImageHandler(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const userId = (request as any).user.userId;
    const { id } = request.params as { id: string };

    const document = await DocumentModel.findOne({ _id: id, userId });

    if (!document) {
      return reply.status(404).send({ error: 'Document not found' });
    }

    if (!fs.existsSync(document.filePath)) {
      return reply.status(404).send({ error: 'Image file not found' });
    }

    const imageBuffer = fs.readFileSync(document.filePath);
    reply.header('Content-Type', document.mimeType);
    reply.header('Content-Length', imageBuffer.length);
    return reply.status(200).send(imageBuffer);
  } catch (error) {
    request.log.error(error);
    return reply.status(500).send({ error: 'Failed to retrieve document image' });
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

export default async function documentRoutes(fastify: FastifyInstance) {
  fastify.post('/documents', uploadDocumentHandler);
  fastify.get('/documents', getDocumentsHandler);
  fastify.get('/documents/:id/image', getDocumentImageHandler);
}
