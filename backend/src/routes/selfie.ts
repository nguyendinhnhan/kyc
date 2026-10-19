import { FastifyRequest, FastifyReply } from 'fastify';
import { SelfieModel } from '../models/Selfie';
import { clearRejectionField } from '../services/workflow';
import { InvalidImage, storeImage, removeReplacedImage, readImage } from '../services/imageStorage';

export async function uploadSelfieHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;

    // Get the file from multipart request
    const file = await request.file();

    if (!file) {
      return reply.status(400).send({ error: 'No file uploaded' });
    }

    const buffer = await file.toBuffer();
    const stored = await storeImage(buffer);
    const previous = await SelfieModel.findOneAndUpdate(
      { userId },
      {
        $set: { ...stored, status: 'pending' },
        $setOnInsert: { userId },
      },
      { upsert: true, new: false, runValidators: true }
    );
    const selfie = await SelfieModel.findOne({ userId }).select('-filePath');
    if (!(await removeReplacedImage(previous?.filePath))) {
      request.log.warn({ code: 'IMAGE_CLEANUP_PENDING' }, 'Image cleanup pending');
    }

    // Clear selfie from submission rejection details
    await clearRejectionField(userId, 'selfie');

    return reply.status(201).send({
      message: 'Selfie uploaded successfully',
      selfie,
    });
  } catch (error) {
    if (error instanceof InvalidImage) return reply.status(400).send({ error: error.message });
    if (error && typeof error === 'object' && 'statusCode' in error && error.statusCode === 413) {
      return reply.status(413).send({ error: 'Image exceeds 10 MiB' });
    }
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to upload selfie' });
  }
}

export async function getSelfieHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;

    const selfie = await SelfieModel.findOne({ userId }).select('-filePath');

    return reply.status(200).send({
      selfie,
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to retrieve selfie' });
  }
}

export async function getSelfieImageHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = (request as any).user.userId;

    const selfie = await SelfieModel.findOne({ userId });

    if (!selfie) {
      return reply.status(404).send({ error: 'Selfie not found' });
    }

    const imageBuffer = await readImage(selfie.filePath).catch(() => null);
    if (!imageBuffer) return reply.status(404).send({ error: 'Image file not found' });
    reply.header('Cache-Control', 'no-store');
    reply.header('X-Content-Type-Options', 'nosniff');
    reply.header('Content-Type', selfie.mimeType);
    reply.header('Content-Length', imageBuffer.length);
    return reply.status(200).send(imageBuffer);
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to retrieve selfie image' });
  }
}
