import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId; // User this notification is for
  final String title;
  final String message;
  final String type; // 'price_drop', 'new_match', 'viewing', 'agent_response', etc.
  final DateTime timestamp;
  final bool isRead;
  final String? relatedPropertyId;
  final String iconType; // 'home', 'trending_down', 'calendar', 'message', etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedPropertyId,
    this.iconType = 'notifications',
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      relatedPropertyId: data['relatedPropertyId'],
      iconType: data['iconType'] ?? 'notifications',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'relatedPropertyId': relatedPropertyId,
      'iconType': iconType,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? relatedPropertyId,
    String? iconType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedPropertyId: relatedPropertyId ?? this.relatedPropertyId,
      iconType: iconType ?? this.iconType,
    );
  }
}
