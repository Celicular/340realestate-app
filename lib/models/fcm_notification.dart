import 'package:cloud_firestore/cloud_firestore.dart';

class FCMNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'new_listing', 'price_change', 'appointment', 'chat_message'
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final bool sentViaFCM;

  FCMNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.sentViaFCM = false,
  });

  factory FCMNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FCMNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? data['message'] ?? '',
      type: data['type'] ?? '',
      data: data['data'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      sentViaFCM: data['sentViaFCM'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      if (data != null) 'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'sentViaFCM': sentViaFCM,
    };
  }

  FCMNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    bool? sentViaFCM,
  }) {
    return FCMNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      sentViaFCM: sentViaFCM ?? this.sentViaFCM,
    );
  }

  String get iconType {
    switch (type) {
      case 'new_listing':
        return 'home';
      case 'price_change':
        return 'attach_money';
      case 'appointment':
        return 'calendar_today';
      case 'chat_message':
        return 'chat';
      default:
        return 'notifications';
    }
  }
}
