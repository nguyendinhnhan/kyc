class Document {
  final String id;
  final String userId;
  final String type;
  final String documentNumber;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String status;
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.userId,
    required this.type,
    required this.documentNumber,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    required this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      documentNumber: json['documentNumber'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      status: json['status'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': type,
      'documentNumber': documentNumber,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'status': status,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
