import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentType {
  passport,
  driversLicense,
  nationalId,
  utilityBill,
  other,
}

enum VerificationStatus {
  pending,
  underReview,
  approved,
  rejected,
  resubmissionRequired,
}

class KYCDocument {
  final String id;
  final String userId;
  final DocumentType documentType;
  final String documentUrl;
  final String? documentNumber;
  final VerificationStatus status;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;

  KYCDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.documentUrl,
    this.documentNumber,
    this.status = VerificationStatus.pending,
    required this.uploadedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.metadata,
  });

  factory KYCDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KYCDocument(
      id: doc.id,
      userId: data['userId'] ?? '',
      documentType: _documentTypeFromString(data['documentType']),
      documentUrl: data['documentUrl'] ?? '',
      documentNumber: data['documentNumber'],
      status: statusFromString(data['status']),
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'documentType': documentType.name,
      'documentUrl': documentUrl,
      if (documentNumber != null) 'documentNumber': documentNumber,
      'status': status.name,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static DocumentType _documentTypeFromString(String? type) {
    if (type == null) return DocumentType.other;
    try {
      return DocumentType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => DocumentType.other,
      );
    } catch (e) {
      return DocumentType.other;
    }
  }

  static VerificationStatus statusFromString(String? status) {
    if (status == null) return VerificationStatus.pending;
    try {
      return VerificationStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => VerificationStatus.pending,
      );
    } catch (e) {
      return VerificationStatus.pending;
    }
  }

  KYCDocument copyWith({
    String? id,
    String? userId,
    DocumentType? documentType,
    String? documentUrl,
    String? documentNumber,
    VerificationStatus? status,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) {
    return KYCDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      documentNumber: documentNumber ?? this.documentNumber,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
    );
  }

  String get documentTypeDisplay {
    switch (documentType) {
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.driversLicense:
        return 'Driver\'s License';
      case DocumentType.nationalId:
        return 'National ID';
      case DocumentType.utilityBill:
        return 'Utility Bill';
      case DocumentType.other:
        return 'Other Document';
    }
  }

  String get statusDisplay {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.underReview:
        return 'Under Review';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.resubmissionRequired:
        return 'Resubmission Required';
    }
  }
}
