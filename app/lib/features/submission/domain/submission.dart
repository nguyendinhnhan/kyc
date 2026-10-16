class RejectionDetails {
  final PersonalDetailsRejection? personalDetails;
  final DocumentRejection? documents;
  final SelfieRejection? selfie;
  final String? generalNotes;

  RejectionDetails({
    this.personalDetails,
    this.documents,
    this.selfie,
    this.generalNotes,
  });

  factory RejectionDetails.fromJson(Map<String, dynamic> json) {
    return RejectionDetails(
      personalDetails: json['personalDetails'] != null
          ? PersonalDetailsRejection.fromJson(json['personalDetails'])
          : null,
      documents: json['documents'] != null
          ? DocumentRejection.fromJson(json['documents'])
          : null,
      selfie: json['selfie'] != null
          ? SelfieRejection.fromJson(json['selfie'])
          : null,
      generalNotes: json['generalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personalDetails': personalDetails?.toJson(),
      'documents': documents?.toJson(),
      'selfie': selfie?.toJson(),
      'generalNotes': generalNotes,
    };
  }

  bool get hasPersonalDetailsErrors =>
      personalDetails != null &&
      (personalDetails!.dateOfBirth != null ||
          personalDetails!.nationality != null ||
          personalDetails!.phone != null ||
          personalDetails!.address != null);

  bool get hasDocumentErrors =>
      documents != null &&
      (documents!.imageQuality != null ||
          documents!.documentNumber != null ||
          documents!.expirationDate != null);

  bool get hasSelfieErrors =>
      selfie != null &&
      (selfie!.imageQuality != null || selfie!.faceMatch != null);
}

class PersonalDetailsRejection {
  final String? dateOfBirth;
  final String? nationality;
  final String? phone;
  final String? address;

  PersonalDetailsRejection({
    this.dateOfBirth,
    this.nationality,
    this.phone,
    this.address,
  });

  factory PersonalDetailsRejection.fromJson(Map<String, dynamic> json) {
    return PersonalDetailsRejection(
      dateOfBirth: json['dateOfBirth'],
      nationality: json['nationality'],
      phone: json['phone'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateOfBirth': dateOfBirth,
      'nationality': nationality,
      'phone': phone,
      'address': address,
    };
  }
}

class DocumentRejection {
  final String? imageQuality;
  final String? documentNumber;
  final String? expirationDate;

  DocumentRejection({
    this.imageQuality,
    this.documentNumber,
    this.expirationDate,
  });

  factory DocumentRejection.fromJson(Map<String, dynamic> json) {
    return DocumentRejection(
      imageQuality: json['imageQuality'],
      documentNumber: json['documentNumber'],
      expirationDate: json['expirationDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageQuality': imageQuality,
      'documentNumber': documentNumber,
      'expirationDate': expirationDate,
    };
  }
}

class SelfieRejection {
  final String? imageQuality;
  final String? faceMatch;

  SelfieRejection({this.imageQuality, this.faceMatch});

  factory SelfieRejection.fromJson(Map<String, dynamic> json) {
    return SelfieRejection(
      imageQuality: json['imageQuality'],
      faceMatch: json['faceMatch'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'imageQuality': imageQuality, 'faceMatch': faceMatch};
  }
}

class Submission {
  final String id;
  final String userId;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? notes;
  final RejectionDetails? rejectionDetails;

  Submission({
    required this.id,
    required this.userId,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.notes,
    this.rejectionDetails,
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
      rejectionDetails: json['rejectionDetails'] != null
          ? RejectionDetails.fromJson(json['rejectionDetails'])
          : null,
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
      'rejectionDetails': rejectionDetails?.toJson(),
    };
  }

  bool get isSubmitted => status == 'submitted';
  bool get isUnderReview => status == 'under_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
