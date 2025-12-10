import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType {
  rental,
  sale,
  villa,
  cottage,
  house,
  combo,
}

class Property {
  final String id;
  final String name;
  final String location;
  final double price;
  final String imageUrl;
  final String description;
  final int bedrooms;
  final int bathrooms;
  final int sqft;
  final List<String> amenities;
  final bool isFeatured;
  final PropertyType type;
  final double? latitude;
  final double? longitude;

  Property({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.bedrooms,
    required this.bathrooms,
    required this.sqft,
    required this.amenities,
    this.isFeatured = false,
    this.type = PropertyType.house,
    this.latitude,
    this.longitude,
  });

  // Create Property from Firestore document
  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract location from nested map
    String locationStr = '';
    if (data['location'] is Map) {
      final loc = data['location'] as Map<String, dynamic>;
      final parts = <String>[];
      if (loc['quarter'] != null) parts.add(loc['quarter']);
      if (loc['subdivision'] != null) parts.add(loc['subdivision']);
      if (loc['address'] != null) parts.add(loc['address']);
      locationStr = parts.join(', ');
    } else {
      locationStr = data['location'] ?? '';
    }

    // Extract latitude and longitude from location map
    double? latitude;
    double? longitude;
    if (data['location'] is Map) {
      final loc = data['location'] as Map<String, dynamic>;
      if (loc['latitude'] != null && loc['longitude'] != null) {
        latitude = (loc['latitude'] is num) ? (loc['latitude'] as num).toDouble() : null;
        longitude = (loc['longitude'] is num) ? (loc['longitude'] as num).toDouble() : null;
      }
    }

    // Extract bedrooms and bathrooms from overview map
    int bedrooms = 0;
    int bathrooms = 0;
    int sqft = 0;
    if (data['overview'] is Map) {
      final overview = data['overview'] as Map<String, dynamic>;
      bedrooms = overview['beds'] ?? 0;
      bathrooms = overview['baths'] ?? 0;
      sqft = overview['sqft'] ?? 0;
    } else {
      bedrooms = data['bedrooms'] ?? 0;
      bathrooms = data['bathrooms'] ?? 0;
      sqft = data['sqft'] ?? 0;
    }

    double price = 0;
    if (data['rates'] is Map) {
      final rates = data['rates'] as Map<String, dynamic>;
      final v = rates['monthly'] ?? rates['nightly'] ?? rates['weekly'] ?? 0;
      if (v is num) {
        price = v.toDouble();
      } else if (v is String) {
        final cleaned = v.replaceAll(RegExp(r'[^0-9\.]'), '');
        price = double.tryParse(cleaned) ?? 0;
      } else {
        price = 0;
      }
    } else {
      final p = data['price'];
      if (p is num) {
        price = p.toDouble();
      } else if (p is String) {
        final cleaned = p.replaceAll(RegExp(r'[^0-9\.]'), '');
        price = double.tryParse(cleaned) ?? 0;
      } else {
        price = 0;
      }
    }

    // Extract image URL from images array
    String imageUrl = '';
    if (data['images'] is List && (data['images'] as List).isNotEmpty) {
      final images = data['images'] as List;
      if (images[0] is Map) {
        imageUrl = (images[0] as Map<String, dynamic>)['url'] ?? '';
      } else {
        imageUrl = images[0].toString();
      }
    } else {
      imageUrl = data['imageUrl'] ?? '';
    }

    // Extract amenities or view as amenities
    List<String> amenities = [];
    if (data['amenities'] != null) {
      amenities = List<String>.from(data['amenities']);
    } else if (data['view'] != null) {
      amenities = List<String>.from(data['view']);
    }

    return Property(
      id: doc.id,
      name: data['title'] ?? data['name'] ?? '',
      location: locationStr,
      price: price,
      imageUrl: imageUrl,
      description: data['description'] ?? 'No description provided',
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      sqft: sqft,
      amenities: amenities,
      isFeatured: data['isLive'] ?? data['isFeatured'] ?? false,
      type: _propertyTypeFromString(data['type']),
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Convert Property to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'sqft': sqft,
      'amenities': amenities,
      'isFeatured': isFeatured,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static PropertyType _propertyTypeFromString(String? typeStr) {
    if (typeStr == null) return PropertyType.house;
    try {
      return PropertyType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => PropertyType.house,
      );
    } catch (e) {
      return PropertyType.house;
    }
  }

  String get formattedPrice {
    if (type == PropertyType.rental) {
      return '\$${price.toStringAsFixed(0)} / week';
    }
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(0)}K';
    }
    return '\$${price.toStringAsFixed(0)}';
  }
}

// Dummy data
class PropertyData {
  static List<Property> getProperties() {
    return [
      Property(
        id: '1',
        name: 'Modern Luxury Villa',
        location: 'Downtown, San Francisco',
        price: 2500000,
        imageUrl:
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
        description:
            'Stunning modern villa with panoramic city views. Features open floor plan, high-end finishes, and premium amenities. Perfect for entertaining with spacious living areas and gourmet kitchen.',
        bedrooms: 4,
        bathrooms: 3,
        sqft: 3500,
        amenities: ['Swimming Pool', 'Gym', 'Parking', 'Garden', 'Security'],
        isFeatured: true,
        type: PropertyType.villa,
      ),
      Property(
        id: '2',
        name: 'Cozy Family Home',
        location: 'Suburban, Los Angeles',
        price: 850000,
        imageUrl:
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
        description:
            'Beautiful family home in a quiet neighborhood. Features large backyard, updated kitchen, and comfortable living spaces. Great schools nearby.',
        bedrooms: 3,
        bathrooms: 2,
        sqft: 2200,
        amenities: ['Garden', 'Parking', 'Fireplace'],
        isFeatured: true,
        type: PropertyType.house,
      ),
      Property(
        id: '3',
        name: 'Urban Loft Apartment',
        location: 'Midtown, New York',
        price: 1200000,
        imageUrl:
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
        description:
            'Stylish loft apartment in the heart of the city. High ceilings, exposed brick, and modern amenities. Walking distance to restaurants and shops.',
        bedrooms: 2,
        bathrooms: 2,
        sqft: 1800,
        amenities: ['Gym', 'Concierge', 'Rooftop', 'Parking'],
        isFeatured: true,
        type: PropertyType.rental,
      ),
      Property(
        id: '4',
        name: 'Beachfront Condo',
        location: 'Ocean View, Miami',
        price: 1800000,
        imageUrl:
            'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800',
        description:
            'Luxurious beachfront condo with stunning ocean views. Direct beach access, resort-style amenities, and premium finishes throughout.',
        bedrooms: 3,
        bathrooms: 3,
        sqft: 2800,
        amenities: ['Beach Access', 'Pool', 'Gym', 'Concierge', 'Parking'],
        isFeatured: false,
        type: PropertyType.sale,
      ),
      Property(
        id: '5',
        name: 'Mountain Retreat',
        location: 'Aspen, Colorado',
        price: 3200000,
        imageUrl:
            'https://images.unsplash.com/photo-1600585154084-4e5fe7c39198?w=800',
        description:
            'Spectacular mountain retreat with breathtaking views. Rustic elegance meets modern luxury. Perfect for year-round enjoyment.',
        bedrooms: 5,
        bathrooms: 4,
        sqft: 4500,
        amenities: [
          'Fireplace',
          'Hot Tub',
          'Garage',
          'Mountain View',
          'Ski Access'
        ],
        isFeatured: false,
        type: PropertyType.cottage,
      ),
      Property(
        id: '6',
        name: 'Contemporary Townhouse',
        location: 'Seattle, Washington',
        price: 950000,
        imageUrl:
            'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=800',
        description:
            'Modern townhouse with sleek design and smart home features. Located in vibrant neighborhood with easy access to downtown.',
        bedrooms: 3,
        bathrooms: 2,
        sqft: 2400,
        amenities: ['Smart Home', 'Parking', 'Patio', 'Storage'],
        isFeatured: false,
        type: PropertyType.combo,
      ),
    ];
  }

  static List<Property> getFeaturedProperties() {
    return getProperties().where((p) => p.isFeatured).toList();
  }

  static List<Property> getPropertiesForSale() {
    return getProperties()
        .where((p) => p.type == PropertyType.sale || p.isFeatured)
        .toList();
  }

  static List<Property> getPropertiesByType(PropertyType type) {
    return getProperties().where((p) => p.type == type).toList();
  }
}
