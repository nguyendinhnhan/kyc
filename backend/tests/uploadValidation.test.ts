import { describe, it, expect, vi, afterEach } from 'vitest';
import fs from 'node:fs';
import { uploadDocumentHandler } from '../src/routes/documents';
import { uploadSelfieHandler } from '../src/routes/selfie';
import { DocumentModel } from '../src/models/Document';
import { SelfieModel } from '../src/models/Selfie';
import { SubmissionModel } from '../src/models/Submission';

afterEach(() => vi.restoreAllMocks());
describe('upload content validation', () => {
  for (const handler of [uploadDocumentHandler, uploadSelfieHandler]) {
    it(`rejects disguised nonimage content in ${handler.name} before persistence`, async () => {
      vi.spyOn(fs, 'existsSync').mockReturnValue(true);
      vi.spyOn(fs, 'writeFileSync').mockImplementation(() => {});
      vi.spyOn(DocumentModel, 'findOne').mockResolvedValue(null);
      const create = vi.spyOn(DocumentModel, 'create').mockResolvedValue({} as any);
      const upsert = vi.spyOn(SelfieModel, 'findOneAndUpdate').mockResolvedValue({} as any);
      vi.spyOn(SubmissionModel, 'updateOne').mockResolvedValue({} as any);
      let status = 200;
      const reply = {
        status(code: number) {
          status = code;
          return this;
        },
        send(value: unknown) {
          return value;
        },
      };
      const request = {
        user: { userId: 'synthetic' },
        log: { error() {} },
        file: async () => ({
          filename: 'synthetic.png',
          mimetype: 'image/png',
          fields: { type: { value: 'passport' }, documentNumber: { value: 'SYNTHETIC' } },
          toBuffer: async () => Buffer.from('not a real image'),
        }),
      };
      await handler(request as any, reply as any);
      expect(status).toBe(400);
      expect(create).not.toHaveBeenCalled();
      expect(upsert).not.toHaveBeenCalled();
    });
  }
});
