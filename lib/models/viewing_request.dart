import 'package:cloud_firestore/cloud_firestore.dart';

class ViewingRequest {
  final String id;
  final String propertyId;
  final String userId;
  final String agentId;
  final DateTime requestedDate;
  final String? requestedTime;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String userName;
  final String userEmail;
  final String userPhone;
  final String? message;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ViewingRequest({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.agentId,
    required this.requestedDate,
    this.requestedTime,
    this.status = 'pending',
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    this.message,
    required this.createdAt,
    this.updatedAt,
  });

  factory ViewingRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ViewingRequest(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      userId: data['userId'] ?? '',
      agentId: data['agentId'] ?? '',
      requestedDate: (data['requestedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestedTime: data['requestedTime'],
      status: data['status'] ?? 'pending',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'userId': userId,
      'agentId': agentId,
      'requestedDate': Timestamp.fromDate(requestedDate),
      if (requestedTime != null) 'requestedTime': requestedTime,
      'status': status,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      if (message != null && message!.isNotEmpty) 'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  ViewingRequest copyWith({
    String? status,
    DateTime? updatedAt,
  }) {
    return ViewingRequest(
      id: id,
      propertyId: propertyId,
      userId: userId,
      agentId: agentId,
      requestedDate: requestedDate,
      requestedTime: requestedTime,
      status: status ?? this.status,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      message: message,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
}
