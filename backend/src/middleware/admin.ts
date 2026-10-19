import { FastifyRequest, FastifyReply } from 'fastify';

export async function requireAdmin(request: FastifyRequest, reply: FastifyReply) {
  try {
    const user = (request as any).user;

    if (!user) {
      return reply.status(401).send({
        error: 'Authentication required',
      });
    }

    if (user.role !== 'admin') {
      return reply.status(403).send({
        error: 'Forbidden: Admin access required',
      });
    }
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(403).send({
      error: 'Forbidden: Admin access required',
    });
  }
}
