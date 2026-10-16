import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { User } from '../models/User';
import { RegisterInput, LoginInput, RefreshInput, LogoutInput } from '../schemas/auth';
import { authenticate } from '../middleware/auth';

export async function registerHandler(
  request: FastifyRequest<{ Body: RegisterInput }>,
  reply: FastifyReply
) {
  try {

    console.log('Registering user:', request.body);
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
    request.log.error(error);
    
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
        details: error.message,
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

    // Generate JWT tokens
    const accessToken = (request.server as any).jwt.sign(
      { userId: user._id, email: user.email, role: user.role || 'user' },
      { expiresIn: '15m' }
    );

    const refreshToken = (request.server as any).jwt.sign(
      { userId: user._id, email: user.email, role: user.role || 'user', type: 'refresh' },
      { expiresIn: '7d' }
    );

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
    request.log.error(error);
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

    // Verify the refresh token
    let decoded: any;
    try {
      decoded = (request.server as any).jwt.verify(refreshToken);
    } catch (error) {
      return reply.status(401).send({
        error: 'Invalid refresh token',
      });
    }

    // Check if it's a refresh token (has type: 'refresh')
    if (!decoded || decoded.type !== 'refresh') {
      return reply.status(401).send({
        error: 'Invalid refresh token',
      });
    }

    // Find the user
    const user = await User.findById(decoded.userId);
    if (!user) {
      return reply.status(401).send({
        error: 'Invalid refresh token',
      });
    }

    // Generate new tokens
    const newAccessToken = (request.server as any).jwt.sign(
      { userId: user._id, email: user.email, role: user.role || 'user' },
      { expiresIn: '15m' }
    );

    const newRefreshToken = (request.server as any).jwt.sign(
      { userId: user._id, email: user.email, role: user.role || 'user', type: 'refresh' },
      { expiresIn: '7d' }
    );

    return reply.status(200).send({
      message: 'Token refreshed successfully',
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    request.log.error(error);
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
    // Authentication middleware will verify the access token
    // If we reach here, the token is valid
    
    const { refreshToken } = request.body;
    
    // In a production environment, you would:
    // 1. Add the refresh token to a blacklist
    // 2. Store the blacklist in Redis or database
    // 3. Set TTL equal to token expiration
    
    // For this implementation, we'll just acknowledge the logout
    // since tokens will expire naturally
    
    return reply.status(200).send({
      message: 'Logged out successfully',
    });
  } catch (error) {
    request.log.error(error);
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
