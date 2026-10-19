import { FastifyRequest, FastifyReply } from 'fastify';
import { SubmissionModel } from '../models/Submission';

// Editing clears only the corrected section; a deliberate submission is still required.
export async function clearRejectionField(
  userId: string,
  field: 'personalDetails' | 'documents' | 'selfie'
) {
  await SubmissionModel.updateOne(
    { userId, status: 'rejected' },
    {
      $unset: { [`rejectionDetails.${field}`]: 1 },
    }
  );
}

export async function requireEditable(request: FastifyRequest, reply: FastifyReply) {
  const { userId } = request.user as unknown as { userId: string };
  const submission = await SubmissionModel.findOne({ userId });
  if (submission && !['draft', 'rejected'].includes(submission.status)) {
    return reply
      .status(409)
      .send({ error: 'This application cannot be edited in its current status' });
  }
}
