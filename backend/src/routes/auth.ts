import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { createSession, rotateSession, verifyRefresh } from '../services/session';
import { Session } from '../models/Session';
import { User } from '../models/User';
import { RegisterInput, LoginInput, RefreshInput, LogoutInput } from '../schemas/auth';
import { authenticate } from '../middleware/auth';

export async function registerHandler(
  request: FastifyRequest<{ Body: RegisterInput }>,
  reply: FastifyReply
) {
  try {
    const { email, password, fullName } = request.body;

    // Create new user
    const user = new User({
      email: email.toLowerCase(),
      password,
      fullName,
    });

    await user.save();

    // Return user without password
    return reply.status(201).send({
      message: 'User registered successfully',
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');

    // Handle duplicate key error
    if (error && typeof error === 'object' && 'code' in error && error.code === 11000) {
      return reply.status(409).send({
        error: 'Email already registered',
      });
    }

    // Handle validation errors
    if (error && typeof error === 'object' && 'name' in error && error.name === 'ValidationError') {
      return reply.status(400).send({
        error: 'Validation failed',
      });
    }

    return reply.status(500).send({
      error: 'Internal server error',
    });
  }
}

export async function loginHandler(
  request: FastifyRequest<{ Body: LoginInput }>,
  reply: FastifyReply
) {
  try {
    const { email, password } = request.body;

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return reply.status(401).send({
        error: 'Invalid email or password',
      });
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return reply.status(401).send({
        error: 'Invalid email or password',
      });
    }

    const { accessToken, refreshToken } = await createSession(request.server, user);

    return reply.status(200).send({
      message: 'Login successful',
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        role: user.role || 'user',
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({
      error: 'Internal server error',
    });
  }
}

export async function refreshTokenHandler(
  request: FastifyRequest<{ Body: RefreshInput }>,
  reply: FastifyReply
) {
  try {
    const { refreshToken } = request.body;

    const decoded = verifyRefresh(refreshToken);
    if (!decoded) return reply.status(401).send({ error: 'Invalid refresh token' });

    // Find the user
    const user = await User.findById(decoded.userId);
    if (!user) {
      return reply.status(401).send({
        error: 'Invalid refresh token',
      });
    }

    const rotated = await rotateSession(request.server, user, refreshToken, decoded.sessionId);
    if (!rotated) return reply.status(401).send({ error: 'Invalid refresh token' });
    return reply.status(200).send({
      message: 'Token refreshed successfully',
      accessToken: rotated.accessToken,
      refreshToken: rotated.refreshToken,
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({
      error: 'Internal server error',
    });
  }
}

export async function logoutHandler(
  request: FastifyRequest<{ Body: LogoutInput }>,
  reply: FastifyReply
) {
  try {
    const current = request.user as unknown as { userId: string; sessionId: string };
    const decoded = verifyRefresh(request.body.refreshToken);
    if (!decoded || decoded.userId !== current.userId || decoded.sessionId !== current.sessionId) {
      return reply.status(401).send({ error: 'Invalid refresh token' });
    }
    // Revoke the entire matching session, including access tokens and concurrent rotations.
    await Session.deleteOne({ _id: current.sessionId, userId: current.userId });
    return reply.status(200).send({
      message: 'Logged out successfully',
    });
  } catch (error) {
    request.log.error({ code: 'OPERATION_FAILED' }, 'Request failed');
    return reply.status(500).send({
      error: 'Internal server error',
    });
  }
}

export default async function authRoutes(fastify: FastifyInstance) {
  fastify.post('/register', registerHandler);
  fastify.post('/login', loginHandler);
  fastify.post('/refresh', refreshTokenHandler);
  fastify.post('/logout', {
    preHandler: authenticate,
    handler: logoutHandler,
  });
}
