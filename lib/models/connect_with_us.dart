import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectWithUs {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String message;
  final String status;
  final DateTime createdAt;

  ConnectWithUs({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.message,
    this.status = 'new',
    required this.createdAt,
  });

  factory ConnectWithUs.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConnectWithUs(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'new',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get fullName => '$firstName $lastName';
}
