import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ResidentialPortfolio {
  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String propertyType;
  final String location;
  final String price;
  final String status;
  final String? source;
  final List<String> amenities;
  final List<String> images;
  final Map<String, dynamic>? features;
  final List<dynamic>? propertyDetails;
  final bool showPackageDetails;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? locationData;

  ResidentialPortfolio({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.propertyType,
    required this.location,
    required this.price,
    this.status = 'for-sale',
    this.source,
    required this.amenities,
    required this.images,
    this.features,
    this.propertyDetails,
    this.showPackageDetails = false,
    required this.createdAt,
    this.updatedAt,
    this.locationData,
  });

  factory ResidentialPortfolio.fromFirestore(DocumentSnapshot doc) {
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

    List<String> sanitizeImages(dynamic v) {
      List<String> normalize(List<dynamic> list) {
        return list
            .map((e) => e.toString().replaceAll('`', '').trim())
            .where((s) => s.isNotEmpty)
            .map((s) {
              if (s.startsWith('http') || s.startsWith('data:image')) return s;
              if (s.startsWith('/static/media') && AppTheme.staticMediaBaseUrl.isNotEmpty) {
                return AppTheme.staticMediaBaseUrl + s;
              }
              return '';
            })
            .where((s) => s.isNotEmpty)
            .toList();
      }
      if (v is List) {
        return normalize(v);
      }
      if (v is String) {
        final s = v.replaceAll('`', '').trim();
        if (s.isEmpty) return [];
        if (s.startsWith('http') || s.startsWith('data:image')) return [s];
        if (s.startsWith('/static/media') && AppTheme.staticMediaBaseUrl.isNotEmpty) {
          return [AppTheme.staticMediaBaseUrl + s];
        }
        return [];
      }
      return [];
    }

    final List<String> amenities = () {
      final v = data['amenities'];
      if (v is List) {
        return v
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return <String>[];
    }();

    List<String> imagesList = data['images'] != null
        ? sanitizeImages(data['images'])
        : sanitizeImages(data['imageUrl']);

    final propertyName = data['title'] ?? 'Unknown';
    print('🏠 RESIDENTIAL [$propertyName]: Found ${imagesList.length} images');

    if (imagesList.isEmpty) {
      imagesList = [AppTheme.placeholderImageUrl];
      print('🏠 RESIDENTIAL [$propertyName]: Using placeholder image');
    }

    // Coerce location into a readable string
    String locationString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v.trim();
      if (v is Map) {
        final loc = v as Map<String, dynamic>;
        final parts = <String>[];
        for (final key in ['quarter', 'subdivision', 'address', 'city', 'island']) {
          final val = loc[key];
          if (val is String && val.trim().isNotEmpty) parts.add(val.trim());
        }
        return parts.join(', ');
      }
      return v.toString();
    }

    String stringify(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is num) return v.toString();
      if (v is Timestamp) return v.toDate().toIso8601String();
      if (v is Map || v is List) return v.toString();
      return v.toString();
    }

    return ResidentialPortfolio(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'residential',
      subcategory: data['subcategory'] ?? '',
      propertyType: data['propertyType'] ?? '',
      location: locationString(data['location']),
      price: stringify(data['price']),
      status: data['status'] ?? 'for-sale',
      source: data['source'],
      amenities: amenities,
      images: imagesList,
      features: data['features'] as Map<String, dynamic>?,
      propertyDetails: data['propertyDetails'] as List<dynamic>?,
      showPackageDetails: data['showPackageDetails'] ?? false,
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']),
      locationData: data['location'] is Map ? data['location'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'propertyType': propertyType,
      'location': location,
      'price': price,
      'status': status,
      if (source != null) 'source': source,
      'amenities': amenities,
      'images': images,
      if (features != null) 'features': features,
      if (propertyDetails != null) 'propertyDetails': propertyDetails,
      'showPackageDetails': showPackageDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // Helper getters
  String get imageUrl {
    for (final s in images) {
      if (s.startsWith('http') || s.startsWith('data:image')) return s;
    }
    return '';
  }

  int get bedrooms {
    if (features != null && features!['beds'] != null) {
      final v = features!['beds'];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 0;
    }
    return 0;
  }

  int get bathrooms {
    if (features != null && features!['baths'] != null) {
      final v = features!['baths'];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return 0;
    }
    return 0;
  }

  String get sqft {
    if (features != null && features!['sqft'] != null) {
      return features!['sqft'].toString();
    }
    return '';
  }

  bool get hasPool {
    if (features != null && features!['pool'] != null) {
      return features!['pool'] == true;
    }
    return false;
  }

  double? get latitude {
    if (locationData == null) return null;
    final lat = locationData!['latitude'];
    if (lat == null) return null;
    if (lat is num) return lat.toDouble();
    if (lat is String) return double.tryParse(lat);
    return null;
  }

  double? get longitude {
    if (locationData == null) return null;
    final lng = locationData!['longitude'];
    if (lng == null) return null;
    if (lng is num) return lng.toDouble();
    if (lng is String) return double.tryParse(lng);
    return null;
  }
}
