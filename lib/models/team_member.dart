import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String name;
  final String title;
  final String email;
  final String phone;
  final String bio;
  final String image;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TeamMember({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    required this.bio,
    required this.image,
    required this.createdAt,
    this.updatedAt,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamMember(
      id: doc.id,
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      bio: data['bio'] ?? '',
      image: data['image'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'title': title,
      'email': email,
      'phone': phone,
      'bio': bio,
      'image': image,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
