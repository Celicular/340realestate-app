import 'package:cloud_firestore/cloud_firestore.dart';

class Rental {
  final String id;
  final String name;
  final String location;
  final String description;
  final String price;
  final int bedrooms;
  final int bathrooms;
  final int guests;
  final List<String> amenities;
  final List<String> images;
  final double rating;
  final int reviews;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Rental({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.guests,
    required this.amenities,
    required this.images,
    this.rating = 0.0,
    this.reviews = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Rental.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rental(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? '',
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      guests: data['guests'] ?? 0,
      amenities: data['amenities'] != null 
          ? List<String>.from(data['amenities']) 
          : [],
      images: data['images'] != null 
          ? List<String>.from(data['images']) 
          : [],
      rating: (data['rating'] ?? 0).toDouble(),
      reviews: data['reviews'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'guests': guests,
      'amenities': amenities,
      'images': images,
      'rating': rating,
      'reviews': reviews,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // Helper getters
  String get imageUrl {
    if (images.isNotEmpty) return images.first;
    return '';
  }

  bool get hasImages => images.isNotEmpty;
}
