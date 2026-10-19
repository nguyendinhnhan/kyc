import { chmod, mkdir, readFile, writeFile, unlink } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import path from 'node:path';
import sharp from 'sharp';
import { config } from '../config';

export class InvalidImage extends Error {}

export async function storeImage(input: Buffer) {
  if (input.length > 10 * 1024 * 1024)
    throw Object.assign(new Error('Image exceeds 10 MiB'), { statusCode: 413 });
  let data: Buffer, mimeType: string, extension: string;
  try {
    const decoder = sharp(input, { limitInputPixels: 24_000_000, failOn: 'warning' });
    const metadata = await decoder.metadata();
    if (!['jpeg', 'png'].includes(metadata.format || '') || (metadata.pages || 1) !== 1)
      throw new Error();
    extension = metadata.format === 'png' ? 'png' : 'jpg';
    mimeType = metadata.format === 'png' ? 'image/png' : 'image/jpeg';
    data = await decoder
      .rotate()
      .toFormat(metadata.format as 'png' | 'jpeg')
      .toBuffer();
  } catch {
    throw new InvalidImage('File must contain a valid JPEG or PNG image');
  }
  const directory = path.resolve(config.storage.uploadDir);
  await mkdir(directory, { recursive: true, mode: 0o700 });
  await chmod(directory, 0o700);
  const fileName = `${randomUUID()}.${extension}`;
  const filePath = path.join(directory, fileName);
  await writeFile(filePath, data, { mode: 0o600, flag: 'wx' });
  return { filePath, fileName, mimeType, fileSize: data.length, uploadedAt: new Date() };
}

// Cleanup only after a confirmed metadata replacement; never remove an uncertain write.
export async function removeReplacedImage(filePath: string | undefined): Promise<boolean> {
  if (!filePath) return true;
  try {
    await unlink(filePath);
    return true;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code === 'ENOENT';
  }
}
export const readImage = readFile;
