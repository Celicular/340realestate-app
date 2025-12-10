import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String name;
  final String displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final String role;
  final List<String> favoriteProperties;
  final List<String> recentlyViewed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.role = 'user',
    this.favoriteProperties = const [],
    this.recentlyViewed = const [],
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'user',
      favoriteProperties: data['favoriteProperties'] != null
          ? List<String>.from(data['favoriteProperties'])
          : [],
      recentlyViewed: data['recentlyViewed'] != null
          ? List<String>.from(data['recentlyViewed'])
          : [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'displayName': displayName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'role': role,
      'favoriteProperties': favoriteProperties,
      'recentlyViewed': recentlyViewed,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
    };
  }

  User copyWith({
    String? email,
    String? name,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    List<String>? favoriteProperties,
    List<String>? recentlyViewed,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return User(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      favoriteProperties: favoriteProperties ?? this.favoriteProperties,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isAgent => role == 'agent';
}
