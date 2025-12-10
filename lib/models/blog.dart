import 'package:cloud_firestore/cloud_firestore.dart';

class BlogAuthor {
  final String name;
  final String email;
  final String? role;

  BlogAuthor({
    required this.name,
    required this.email,
    this.role,
  });

  factory BlogAuthor.fromMap(Map<String, dynamic> data) {
    return BlogAuthor(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      if (role != null) 'role': role,
    };
  }
}

class Blog {
  final String id;
  final String title;
  final String? subtitle;
  final String description;
  final String? slug;
  final String? originalId;
  final String? coverImage;
  final BlogAuthor? author;
  final List<String>? tags;
  final String? category;
  final String? metaDescription;
  final List<String>? metaKeywords;
  final int views;
  final int likes;
  final bool featured;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  Blog({
    required this.id,
    required this.title,
    this.subtitle,
    required this.description,
    this.slug,
    this.originalId,
    this.coverImage,
    this.author,
    this.tags,
    this.category,
    this.metaDescription,
    this.metaKeywords,
    this.views = 0,
    this.likes = 0,
    this.featured = false,
    this.status = 'draft',
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  factory Blog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Blog(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      description: data['description'] ?? '',
      slug: data['slug'],
      originalId: data['originalId'],
      coverImage: data['coverImage'],
      author: data['author'] != null 
          ? BlogAuthor.fromMap(data['author'] as Map<String, dynamic>)
          : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      category: data['category'],
      metaDescription: data['metaDescription'],
      metaKeywords: data['metaKeywords'] != null 
          ? List<String>.from(data['metaKeywords']) 
          : null,
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      featured: data['featured'] ?? false,
      status: data['status'] ?? 'draft',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      'description': description,
      if (slug != null) 'slug': slug,
      if (originalId != null) 'originalId': originalId,
      if (coverImage != null) 'coverImage': coverImage,
      if (author != null) 'author': author!.toMap(),
      if (tags != null) 'tags': tags,
      if (category != null) 'category': category,
      if (metaDescription != null) 'metaDescription': metaDescription,
      if (metaKeywords != null) 'metaKeywords': metaKeywords,
      'views': views,
      'likes': likes,
      'featured': featured,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
    };
  }
}
