import { afterEach, describe, it, expect, vi } from 'vitest';
afterEach(() => {
  vi.unstubAllEnvs();
  vi.resetModules();
});
describe('production configuration', () => {
  it('refuses to start with missing signing secrets', async () => {
    vi.stubEnv('NODE_ENV', 'production');
    vi.stubEnv('JWT_SECRET', '');
    vi.stubEnv('JWT_REFRESH_SECRET', '');
    vi.resetModules();
    await expect(import('../src/config')).rejects.toThrow(/secret/i);
  });
});
