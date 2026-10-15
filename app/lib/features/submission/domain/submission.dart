class Submission {
  final String id;
  final String userId;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? notes;

  Submission({
    required this.id,
    required this.userId,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.notes,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'draft',
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt']) 
          : null,
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.parse(json['reviewedAt']) 
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'status': status,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  bool get isSubmitted => status == 'submitted';
  bool get isUnderReview => status == 'under_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
