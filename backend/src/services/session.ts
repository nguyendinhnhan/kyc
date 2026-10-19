import { createHash, randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import { FastifyInstance } from 'fastify';
import { config } from '../config';
import { Session } from '../models/Session';
import { IUser } from '../models/User';

export const tokenHash = (token: string) => createHash('sha256').update(token).digest('hex');

function tokens(app: FastifyInstance, user: IUser, sessionId: string) {
  const claims = { userId: String(user._id), role: user.role || 'user', sessionId };
  const accessToken = app.jwt.sign(claims, { expiresIn: config.jwt.accessExpiresIn });
  const refreshToken = jwt.sign({ ...claims, type: 'refresh' }, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpiresIn as jwt.SignOptions['expiresIn'],
    jwtid: randomUUID(),
  });
  const decoded = jwt.decode(refreshToken) as jwt.JwtPayload;
  return { accessToken, refreshToken, expiresAt: new Date(decoded.exp! * 1000) };
}

export async function createSession(app: FastifyInstance, user: IUser) {
  const sessionId = randomUUID();
  const result = tokens(app, user, sessionId);
  await Session.create({
    _id: sessionId,
    userId: user._id,
    refreshHash: tokenHash(result.refreshToken),
    expiresAt: result.expiresAt,
  });
  return { accessToken: result.accessToken, refreshToken: result.refreshToken };
}

export function verifyRefresh(token: string) {
  try {
    const claims = jwt.verify(token, config.jwt.refreshSecret, { algorithms: ['HS256'] });
    if (
      typeof claims === 'string' ||
      claims.type !== 'refresh' ||
      typeof claims.sessionId !== 'string' ||
      typeof claims.userId !== 'string'
    )
      return null;
    return claims;
  } catch {
    return null;
  }
}

export async function rotateSession(
  app: FastifyInstance,
  user: IUser,
  token: string,
  sessionId: string
) {
  const result = tokens(app, user, sessionId);
  const consumed = await Session.findOneAndUpdate(
    {
      _id: sessionId,
      userId: user._id,
      refreshHash: tokenHash(token),
      expiresAt: { $gt: new Date() },
    },
    {
      $set: { refreshHash: tokenHash(result.refreshToken), expiresAt: result.expiresAt },
    }
  );
  return consumed ? { accessToken: result.accessToken, refreshToken: result.refreshToken } : null;
}
