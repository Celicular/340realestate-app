import 'package:cloud_firestore/cloud_firestore.dart';
import 'kyc_document.dart';

class KYCProfile {
  final String userId;
  final String fullName;
  final DateTime dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final List<KYCDocument> documents;
  final VerificationStatus overallStatus;
  final DateTime? completedAt;
  final DateTime createdAt;

  KYCProfile({
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.documents = const [],
    this.overallStatus = VerificationStatus.pending,
    this.completedAt,
    required this.createdAt,
  });

  factory KYCProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KYCProfile(
      userId: doc.id,
      fullName: data['fullName'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      country: data['country'] ?? 'USA',
      overallStatus: KYCDocument.statusFromString(data['overallStatus']),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'overallStatus': overallStatus.name,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
