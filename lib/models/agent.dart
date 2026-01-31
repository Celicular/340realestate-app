import 'package:cloud_firestore/cloud_firestore.dart';

class Agent {
  final String id;
  final String? userId; // Links to User document
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final String? fullBio;
  final String? title;
  final String? location;
  final String? experience;
  final List<String>? specialties;
  final List<String>? achievements;
  final List<String>? galleryImages;
  final int? legacyId;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agent({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.bio,
    this.fullBio,
    this.title,
    this.location,
    this.experience,
    this.specialties,
    this.achievements,
    this.galleryImages,
    this.legacyId,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  // Create Agent from Firestore document
  factory Agent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Agent(
      id: doc.id,
      userId: data['userId'],
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      profileImage: data['profileImage'],
      bio: data['bio'],
      fullBio: data['fullBio'],
      title: data['title'],
      location: data['location'],
      experience: data['experience'],
      specialties: data['specialties'] != null 
          ? List<String>.from(data['specialties']) 
          : null,
      achievements: data['achievements'] != null 
          ? List<String>.from(data['achievements']) 
          : null,
      galleryImages: data['galleryImages'] != null 
          ? List<String>.from(data['galleryImages']) 
          : null,
      legacyId: data['legacyId'],
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert Agent to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) 'userId': userId,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
      if (bio != null) 'bio': bio,
      if (fullBio != null) 'fullBio': fullBio,
      if (title != null) 'title': title,
      if (location != null) 'location': location,
      if (experience != null) 'experience': experience,
      if (specialties != null) 'specialties': specialties,
      if (achievements != null) 'achievements': achievements,
      if (galleryImages != null) 'galleryImages': galleryImages,
      if (legacyId != null) 'legacyId': legacyId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // Copy with method for updates
  Agent copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? bio,
    String? fullBio,
    String? title,
    String? location,
    String? experience,
    List<String>? specialties,
    List<String>? achievements,
    List<String>? galleryImages,
    int? legacyId,
    String? status,
    DateTime? updatedAt,
  }) {
    return Agent(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      fullBio: fullBio ?? this.fullBio,
      title: title ?? this.title,
      location: location ?? this.location,
      experience: experience ?? this.experience,
      specialties: specialties ?? this.specialties,
      achievements: achievements ?? this.achievements,
      galleryImages: galleryImages ?? this.galleryImages,
      legacyId: legacyId ?? this.legacyId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
