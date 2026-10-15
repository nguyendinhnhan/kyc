import { FastifyRequest, FastifyReply } from 'fastify';

export async function authenticate(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const authHeader = request.headers.authorization;
    
    if (!authHeader) {
      return reply.status(401).send({
        error: 'No authorization header provided',
      });
    }

    const [scheme, token] = authHeader.split(' ');
    
    if (scheme !== 'Bearer' || !token) {
      return reply.status(401).send({
        error: 'Invalid authorization format. Expected: Bearer <token>',
      });
    }

    // Verify the token
    try {
      const decoded = (request.server as any).jwt.verify(token);
      
      // Check if it's an access token (not a refresh token)
      if (decoded.type === 'refresh') {
        return reply.status(401).send({
          error: 'Access token required, refresh token provided',
        });
      }
      
      // Attach user info to request
      (request as any).user = decoded;
    } catch (error) {
      return reply.status(401).send({
        error: 'Invalid or expired token',
      });
    }
  } catch (error) {
    request.log.error(error);
    return reply.status(401).send({
      error: 'Authentication failed',
    });
  }
}
