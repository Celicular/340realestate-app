import 'package:cloud_firestore/cloud_firestore.dart';

class RentalProperty {
  final String id;
  final String name;
  final String type;
  final String description;
  final String? details;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final int guests;
  final int sqft;
  final double pricePerNight;
  final List<String> amenities;
  final List<String> imageLinks;
  final Map<String, dynamic>? accommodation;
  final Map<String, dynamic>? agentInfo;
  final Map<String, dynamic>? rates;
  final Map<String, dynamic>? policies;
  final Map<String, dynamic>? propertyInfo;
  final Map<String, dynamic>? media;
  final String? additionalNotes;
  final String? adminNotes;
  final String? cancellationPolicy;
  final String? damagePolicy;
  final bool children;
  final bool pets;
  final bool smoking;
  final bool party;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final double? latitude;
  final double? longitude;

  RentalProperty({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.details,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.guests,
    required this.sqft,
    required this.pricePerNight,
    required this.amenities,
    required this.imageLinks,
    this.accommodation,
    this.agentInfo,
    this.rates,
    this.policies,
    this.propertyInfo,
    this.media,
    this.additionalNotes,
    this.adminNotes,
    this.cancellationPolicy,
    this.damagePolicy,
    this.children = false,
    this.pets = false,
    this.smoking = false,
    this.party = false,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.reviewedAt,
    this.latitude,
    this.longitude,
  });

  factory RentalProperty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == 'yes' || s == '1';
      }
      if (v is num) return v != 0;
      return false;
    }

    List<String> sanitizeLinks(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString().replaceAll('`', '').trim()).toList();
      }
      return [];
    }

    // Extract bedrooms and bathrooms from accommodation map or direct fields
    int bedrooms = 0;
    int bathrooms = 0;
    int guests = 0;

    if (data['accommodation'] is Map) {
      final acc = data['accommodation'] as Map<String, dynamic>;
      bedrooms = toInt(acc['bedrooms'] ?? data['bedrooms']);
      bathrooms = toInt(acc['bathrooms'] ?? data['bathrooms']);
      guests = toInt(acc['maxGuests'] ?? data['guests']);
    } else {
      bedrooms = toInt(data['bedrooms']);
      bathrooms = toInt(data['bathrooms']);
      guests = toInt(data['guests']);
    }
    
    // Extract sqft from multiple possible locations
    int sqft = 0;
    // Try 1: details.squareFeet (as seen in firestore.js admin update)
    if (data['details'] is Map) {
      final det = data['details'] as Map<String, dynamic>;
      sqft = toInt(det['squareFeet'] ?? 0);
    }
    // Try 2: accommodation.squareFeet
    if (sqft == 0 && data['accommodation'] is Map) {
      final acc = data['accommodation'] as Map<String, dynamic>;
      sqft = toInt(acc['squareFeet'] ?? 0);
    }
    // Try 3: Direct sqft or squareFeet field
    if (sqft == 0) {
      sqft = toInt(data['sqft'] ?? data['squareFeet'] ?? 0);
    }

    // Extract price from propertyInfo or direct field or rates object
    // Note: Firebase stores prices per week, so divide by 7 to get per night
    double pricePerNight = 0;
    
    // Try 1: Direct pricePerNight field
    if (data['propertyInfo'] is Map) {
      final propInfo = data['propertyInfo'] as Map<String, dynamic>;
      pricePerNight = toDouble(propInfo['pricePerNight'] ?? 0);
    }
    if (pricePerNight == 0) {
      pricePerNight = toDouble(data['pricePerNight'] ?? 0);
    }
    
    // Try 2: Nested property.propertyInfo.pricePerNight (as seen in firestore.js)
    if (pricePerNight == 0 && data['property'] is Map) {
      final property = data['property'] as Map<String, dynamic>;
      if (property['propertyInfo'] is Map) {
        final nestedPropInfo = property['propertyInfo'] as Map<String, dynamic>;
        pricePerNight = toDouble(nestedPropInfo['pricePerNight'] ?? 0);
      }
    }
    
    // Try 3: rates object (weekly, baseRate, seasonalRate, etc.)
    if (pricePerNight == 0 && data['rates'] is Map) {
      final rates = data['rates'] as Map<String, dynamic>;
      pricePerNight = toDouble(
        rates['weekly'] ?? 
        rates['pricePerWeek'] ?? 
        rates['weeklyRate'] ?? 
        rates['baseRate'] ??
        rates['seasonalRate'] ??
        0
      );
    }
    
    // Divide by 7 to convert weekly to nightly (only if we got a value)
    if (pricePerNight > 0) {
      pricePerNight = pricePerNight / 7;
    }

    // Extract latitude and longitude from location map or direct fields
    double? latitude;
    double? longitude;
    if (data['location'] is Map) {
      final loc = data['location'] as Map<String, dynamic>;
      if (loc['latitude'] != null) {
        latitude = toDouble(loc['latitude']);
        if (latitude == 0) latitude = null;
      }
      if (loc['longitude'] != null) {
        longitude = toDouble(loc['longitude']);
        if (longitude == 0) longitude = null;
      }
    }

    return RentalProperty(
      id: doc.id,
      name: data['name'] is String
          ? data['name']
          : (data['title'] is String ? data['title'] : ''),
      type: data['type'] ?? 'Villa',
      description: data['description'] is String
          ? data['description']
          : (data['notes'] is String ? data['notes'] : ''),
      details: data['details'] is String ? data['details'] : null,
      address: data['address'] ?? '',
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      guests: guests,
      sqft: sqft,
      pricePerNight: pricePerNight,
      amenities: data['amenities'] is List
          ? (data['amenities'] as List).map((e) => e.toString()).toList()
          : [],
      imageLinks: (() {
        List<String> result = [];
        final propertyName = data['name'] ?? data['title'] ?? 'Unknown';

        // 1. Try media.imageList first (primary for rentals)
        if (data['media'] is Map) {
          final media = data['media'] as Map<String, dynamic>;
          if (media['imageList'] is List && (media['imageList'] as List).isNotEmpty) {
            result = sanitizeLinks(media['imageList']);
            print('🖼️ RENTAL [$propertyName]: Found ${result.length} images in media.imageList');
            return result;
          }
          if (media['imageLinks'] is List && (media['imageLinks'] as List).isNotEmpty) {
            result = sanitizeLinks(media['imageLinks']);
            print('🖼️ RENTAL [$propertyName]: Found ${result.length} images in media.imageLinks');
            return result;
          }
        }

        // 2. Try direct imageLinks array
        if (data['imageLinks'] is List && (data['imageLinks'] as List).isNotEmpty) {
          result = sanitizeLinks(data['imageLinks']);
          print('🖼️ RENTAL [$propertyName]: Found ${result.length} images in imageLinks');
          return result;
        }

        // 3. Single image field fallback
        if (data['image'] is String && data['image'].toString().isNotEmpty) {
          result = [data['image'].toString().replaceAll('`', '').trim()];
          print('🖼️ RENTAL [$propertyName]: Found 1 image in image field');
          return result;
        }

        print('⚠️ RENTAL [$propertyName]: No images found!');
        return <String>[];
      })(),
      accommodation: data['accommodation'] as Map<String, dynamic>?,
      agentInfo: data['agentInfo'] as Map<String, dynamic>?,
      rates: data['rates'] as Map<String, dynamic>?,
      policies: data['policies'] as Map<String, dynamic>?,
      propertyInfo: data['propertyInfo'] as Map<String, dynamic>?,
      media: data['media'] as Map<String, dynamic>?,
      additionalNotes:
          data['additionalNotes'] is String ? data['additionalNotes'] : null,
      adminNotes: data['adminNotes'] is String ? data['adminNotes'] : null,
      cancellationPolicy: data['cancellationPolicy'] is String
          ? data['cancellationPolicy']
          : null,
      damagePolicy:
          data['damagePolicy'] is String ? data['damagePolicy'] : null,
      children: toBool(data['children']),
      pets: toBool(data['pets']),
      smoking: toBool(data['smoking']),
      party: toBool(data['party']),
      status: (() {
        final s = data['status'];
        if (s != null) return s.toString().trim();
        if (data['propertyInfo'] is Map) {
          final pi = data['propertyInfo'] as Map<String, dynamic>;
          final ps = pi['status'];
          if (ps != null) return ps.toString().trim();
        }
        if (data['isApproved'] == true) return 'approved';
        return 'pending';
      })(),
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']),
      submittedAt: parseDate(data['submittedAt']),
      reviewedAt: parseDate(data['reviewedAt']),
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'description': description,
      if (details != null) 'details': details,
      'address': address,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'guests': guests,
      'sqft': sqft,
      'pricePerNight': pricePerNight,
      'amenities': amenities,
      'imageLinks': imageLinks,
      if (accommodation != null) 'accommodation': accommodation,
      if (agentInfo != null) 'agentInfo': agentInfo,
      if (rates != null) 'rates': rates,
      if (policies != null) 'policies': policies,
      if (propertyInfo != null) 'propertyInfo': propertyInfo,
      if (media != null) 'media': media,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (cancellationPolicy != null) 'cancellationPolicy': cancellationPolicy,
      if (damagePolicy != null) 'damagePolicy': damagePolicy,
      'children': children,
      'pets': pets,
      'smoking': smoking,
      'party': party,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  // Helper getters
  String get imageUrl {
    // First check if imageLinks was populated
    if (imageLinks.isNotEmpty) return imageLinks.first;
    
    // Fallback to media object if imageLinks is empty
    if (media != null) {
      // Try imageList first (primary field in firestore.js)
      if (media!['imageList'] is List) {
        final links = (media!['imageList'] as List)
            .map((e) => e.toString().replaceAll('`', '').trim())
            .toList();
        if (links.isNotEmpty) return links.first;
      }
      // Try imageLinks (backward compatibility)
      if (media!['imageLinks'] is List) {
        final links = (media!['imageLinks'] as List)
            .map((e) => e.toString().replaceAll('`', '').trim())
            .toList();
        if (links.isNotEmpty) return links.first;
      }
    }
    
    return '';
  }

  String get slug {
    if (propertyInfo != null && propertyInfo!['slug'] != null) {
      return propertyInfo!['slug'];
    }
    return name.toLowerCase().replaceAll(' ', '-');
  }
}
