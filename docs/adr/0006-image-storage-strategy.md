# 0006: Image storage strategy (local + S3-compatible)
Status: Accepted
Date: 2026-10-14

## Context
R4/R5 require camera capture of ID documents and selfies. R6 requires uploading these images. R9 requires secure handling of sensitive data including images. The app needs to:
- Capture images on mobile (camera)
- Store images temporarily before upload
- Upload images to backend securely
- Backend needs to store images persistently
- Images contain PII and must be protected
- Need to handle upload failures and retries
- Need to support resume capability

## Decision
Use a **two-tier storage strategy**:
- **Development**: Local filesystem storage
- **Production**: S3-compatible object storage (AWS S3, Cloudflare R2, or MinIO)

Key implications:
- Abstract storage layer in backend (interface/strategy pattern)
- Implement local filesystem adapter for development
- Implement S3-compatible adapter for production
- Store image metadata in MongoDB (path, owner, upload status, checksum)
- Never store images directly in MongoDB (GridFS not used)
- Use pre-signed URLs for direct uploads (optional optimization)
- Encrypt images at rest in production
- Implement access control for image retrieval
- Clean up temporary files after successful upload

## Alternatives

1. **MongoDB GridFS** — Store files in MongoDB
   - Pros: Simple, everything in one database
   - Cons: Not scalable, slower than object storage, harder to serve via CDN
   
2. **AWS S3 only** — Always use S3, even in development
   - Pros: Consistent environment
   - Cons: Requires AWS account, costs money, slower local development
   
3. **Cloudinary** — Managed image storage and transformation
   - Pros: Built-in transformations, CDN
   - Cons: Vendor lock-in, costs money, overkill for this project

## Rationale

### Why Local for Development?
- **Fast**: No network calls, instant uploads
- **Free**: No cloud storage costs during development
- **Simple**: Easy to inspect files, debug issues
- **Offline**: Works without internet connection
- **Quick iteration**: Fast feedback loop

### Why S3-Compatible for Production?
- **Scalable**: Handles large files and high throughput
- **Durable**: 99.999999999% durability (11 nines for S3)
- **Secure**: Built-in encryption, access control, versioning
- **CDN-ready**: Easy to serve via CDN if needed
- **Standard**: Industry standard for object storage
- **Cost-effective**: Pay only for what you use

### Why S3-Compatible (Not AWS-Specific)?
- **Flexibility**: Can switch between S3, R2, MinIO, etc.
- **Cost**: Cloudflare R2 has no egress fees
- **Local testing**: MinIO is S3-compatible, can run locally
- **No vendor lock-in**: Standard API

### Why Not GridFS?
- Slower than object storage for large files
- Harder to serve files efficiently
- Not designed for high-throughput image serving
- Object storage is better suited for this use case

## Consequences

### Benefits
- Fast local development without cloud dependencies
- Production-grade storage with S3 durability and security
- Flexible (can switch S3 providers easily)
- Cost-effective (free in dev, pay-as-you-go in prod)
- Scalable for future growth
- Standard approach with good tooling

### Costs and Risks
- Need to implement and maintain storage abstraction
- Two storage adapters to test and maintain
- S3 costs money in production (but minimal for this scale)
- Image encryption adds complexity
- Access control must be implemented correctly

### Mitigations
- Use strategy pattern for clean abstraction
- Test both adapters thoroughly
- Use MinIO for local S3 testing if needed
- Implement encryption at rest for production
- Use pre-signed URLs with short expiry
- Implement proper access control (ownership checks)
- Log all image access (audit trail)

## Implementation

### Backend Storage Interface
```typescript
interface ImageStorage {
  upload(image: Buffer, metadata: ImageMetadata): Promise<string>;
  download(imageId: string): Promise<Buffer>;
  delete(imageId: string): Promise<void>;
  getSignedUrl(imageId: string, expiresInSeconds: number): Promise<string>;
}
```

### Local Filesystem Adapter
- Store in `backend/uploads/` directory
- Use UUID for filenames (prevent guessing)
- Store metadata in MongoDB
- Organize by user_id/date for easy cleanup

### S3-Compatible Adapter
- Use AWS SDK v3 or compatible client
- Configure bucket, region, credentials via environment variables
- Use UUID for object keys
- Enable server-side encryption (AES-256)
- Set bucket policy to private
- Use pre-signed URLs for uploads/downloads

### Image Metadata (MongoDB)
```typescript
interface ImageMetadata {
  _id: string;
  userId: string;
  type: 'document' | 'selfie';
  filename: string;
  mimeType: string;
  size: number;
  checksum: string;
  storagePath: string;
  uploadStatus: 'pending' | 'uploaded' | 'failed';
  createdAt: Date;
  updatedAt: Date;
}
```

### Security
- Validate image type (JPEG, PNG only)
- Validate image dimensions and file size
- Scan for malware (optional, future enhancement)
- Encrypt at rest in production (S3 server-side encryption)
- Access control: only owner can access their images
- Never expose storage paths to client
- Use pre-signed URLs with short expiry (15 minutes)
- Log all image access

### Mobile App
- Compress images before upload (max 2MB)
- Generate checksum for integrity verification
- Implement retry logic for failed uploads
- Store upload status for resume capability
- Clean up temporary files after successful upload
- Show upload progress to user

## Verification and Follow-up
- Test local filesystem upload/download/delete
- Test S3 upload/download/delete (use MinIO or real S3)
- Verify image encryption in production
- Test access control (cross-user denial)
- Test upload retry logic
- Verify checksum validation
- Test cleanup of temporary files
- Document storage configuration for deployment
- Record costs and performance metrics

## References
- AWS S3 documentation: https://docs.aws.amazon.com/s3/
- Cloudflare R2: https://developers.cloudflare.com/r2/
- MinIO (local S3): https://min.io/
- Pre-signed URLs: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html
