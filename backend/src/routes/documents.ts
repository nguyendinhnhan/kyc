import { FastifyRequest, FastifyReply, FastifyInstance } from 'fastify';
import { DocumentModel } from '../models/Document';
import { clearRejectionField } from '../services/workflow';
import { InvalidImage, storeImage, removeReplacedImage, readImage } from '../services/imageStorage';

export async function uploadDocumentHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;

    // Get the file
    const file = await request.file();
    if (!file) {
      return reply.status(400).send({ error: 'No file uploaded' });
    }

    const buffer = await file.toBuffer();

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

    const stored = await storeImage(buffer);
    const previous = await DocumentModel.findOneAndUpdate(
      { userId, type },
      {
        $set: { ...stored, documentNumber, status: 'pending' },
        $setOnInsert: { userId, type },
      },
      { upsert: true, new: false, runValidators: true }
    );
    const document = await DocumentModel.findOne({ userId, type }).select('-filePath');
    if (!(await removeReplacedImage(previous?.filePath))) {
      request.log.warn({ code: 'IMAGE_CLEANUP_PENDING' }, 'Image cleanup pending');
    }
    await clearRejectionField(userId, 'documents');
    return reply.status(previous ? 200 : 201).send({
      message: previous ? 'Document updated successfully' : 'Document uploaded successfully',
      document,
    });
  } catch (error) {
    if (error instanceof InvalidImage) return reply.status(400).send({ error: error.message });
    if (error && typeof error === 'object' && 'statusCode' in error && error.statusCode === 413) {
      return reply.status(413).send({ error: 'Image exceeds 10 MiB' });
    }
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Internal server error' });
  }
}

export async function getDocumentsHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;

    const documents = await DocumentModel.find({ userId }).select('-filePath');

    return reply.status(200).send({ documents });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Internal server error' });
  }
}

export async function getDocumentImageHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;
    const { id } = request.params as { id: string };

    const document = await DocumentModel.findOne({ _id: id, userId });

    if (!document) {
      return reply.status(404).send({ error: 'Document not found' });
    }

    const imageBuffer = await readImage(document.filePath).catch(() => null);
    if (!imageBuffer) return reply.status(404).send({ error: 'Image file not found' });
    reply.header('Cache-Control', 'no-store');
    reply.header('X-Content-Type-Options', 'nosniff');
    reply.header('Content-Type', document.mimeType);
    reply.header('Content-Length', imageBuffer.length);
    return reply.status(200).send(imageBuffer);
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to retrieve document image' });
  }
}

export default async function documentRoutes(fastify: FastifyInstance) {
  fastify.post('/documents', uploadDocumentHandler);
  fastify.get('/documents', getDocumentsHandler);
  fastify.get('/documents/:id/image', getDocumentImageHandler);
}
