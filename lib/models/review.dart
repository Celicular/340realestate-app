import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final String targetType; // property, agent
  final String targetId; // propertyId or agentId
  final double rating; // 1-5
  final String? title;
  final String comment;
  final List<String>? images;
  final bool isVerified;
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.targetType,
    required this.targetId,
    required this.rating,
    this.title,
    required this.comment,
    this.images,
    this.isVerified = false,
    this.helpfulCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userPhotoUrl: data['userPhotoUrl'],
      targetType: data['targetType'] ?? 'property',
      targetId: data['targetId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      title: data['title'],
      comment: data['comment'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      isVerified: data['isVerified'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (userName != null) 'userName': userName,
      if (userPhotoUrl != null) 'userPhotoUrl': userPhotoUrl,
      'targetType': targetType,
      'targetId': targetId,
      'rating': rating,
      if (title != null) 'title': title,
      'comment': comment,
      if (images != null) 'images': images,
      'isVerified': isVerified,
      'helpfulCount': helpfulCount,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  int get ratingStars => rating.round();
}
