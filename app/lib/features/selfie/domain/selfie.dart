class Selfie {
  final String id;
  final String userId;
  final String filePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final DateTime uploadedAt;
  final String status;

  Selfie({
    required this.id,
    required this.userId,
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
    required this.status,
  });

  factory Selfie.fromJson(Map<String, dynamic> json) {
    return Selfie(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      mimeType: json['mimeType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'filePath': filePath,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'status': status,
    };
  }
}
