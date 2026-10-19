import { FastifyRequest, FastifyReply } from 'fastify';
import { SubmissionModel, IRejectionDetails } from '../models/Submission';
import { PersonalDetails } from '../models/PersonalDetails';
import { DocumentModel } from '../models/Document';
import { SelfieModel } from '../models/Selfie';

export async function listSubmissionsHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const { status, page = '1', limit = '20' } = request.query as any;

    const query: any = {};
    if (status) {
      query.status = status;
    }

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    const [submissions, total] = await Promise.all([
      SubmissionModel.find(query).sort({ createdAt: -1 }).skip(skip).limit(limitNum),
      SubmissionModel.countDocuments(query),
    ]);

    return reply.status(200).send({
      submissions,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to list submissions' });
  }
}

export async function getSubmissionDetailsHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = request.params as { id: string };

    const submission = await SubmissionModel.findById(id);
    if (!submission) {
      return reply.status(404).send({ error: 'Submission not found' });
    }

    const [personalDetails, documents, selfie] = await Promise.all([
      PersonalDetails.findOne({ userId: submission.userId }),
      DocumentModel.find({ userId: submission.userId }),
      SelfieModel.findOne({ userId: submission.userId }),
    ]);

    return reply.status(200).send({
      submission,
      personalDetails,
      documents,
      selfie,
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to get submission details' });
  }
}

export async function approveSubmissionHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = request.params as { id: string };
    const adminId = (request as any).user.userId;
    const { notes } = request.body as { notes?: string };

    const submission = await SubmissionModel.findById(id);
    if (!submission) {
      return reply.status(404).send({ error: 'Submission not found' });
    }

    const updated = await SubmissionModel.findOneAndUpdate(
      { _id: id, status: { $in: ['submitted', 'under_review'] } },
      {
        $set: {
          status: 'approved',
          reviewedAt: new Date(),
          reviewedBy: adminId,
          ...(notes ? { notes } : {}),
        },
        $unset: { rejectionDetails: 1 },
      },
      { new: true }
    );
    if (!updated)
      return reply.status(409).send({ error: 'Only pending applications can be reviewed' });

    return reply.status(200).send({
      message: 'Submission approved successfully',
      submission: updated,
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to approve submission' });
  }
}

export async function rejectSubmissionHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = request.params as { id: string };
    const adminId = (request as any).user.userId;
    const { rejectionDetails, notes } = request.body as {
      rejectionDetails: IRejectionDetails;
      notes?: string;
    };

    // Validate that at least one rejection detail is provided
    const hasDetails =
      rejectionDetails &&
      (rejectionDetails.personalDetails ||
        rejectionDetails.documents ||
        rejectionDetails.selfie ||
        rejectionDetails.generalNotes);

    if (!hasDetails) {
      return reply.status(400).send({
        error: 'At least one rejection detail is required',
      });
    }

    const submission = await SubmissionModel.findById(id);
    if (!submission) {
      return reply.status(404).send({ error: 'Submission not found' });
    }

    const updated = await SubmissionModel.findOneAndUpdate(
      { _id: id, status: { $in: ['submitted', 'under_review'] } },
      {
        $set: {
          status: 'rejected',
          reviewedAt: new Date(),
          reviewedBy: adminId,
          rejectionDetails,
          ...(notes ? { notes } : {}),
        },
      },
      { new: true }
    );
    if (!updated)
      return reply.status(409).send({ error: 'Only pending applications can be reviewed' });

    return reply.status(200).send({
      message: 'Submission rejected successfully',
      submission: updated,
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to reject submission' });
  }
}

export async function getStatsHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const [total, submitted, underReview, approved, rejected] = await Promise.all([
      SubmissionModel.countDocuments(),
      SubmissionModel.countDocuments({ status: 'submitted' }),
      SubmissionModel.countDocuments({ status: 'under_review' }),
      SubmissionModel.countDocuments({ status: 'approved' }),
      SubmissionModel.countDocuments({ status: 'rejected' }),
    ]);

    return reply.status(200).send({
      stats: {
        total,
        submitted,
        underReview,
        approved,
        rejected,
      },
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({ error: 'Failed to get stats' });
  }
}
