import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class LandPortfolio {
  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String type;
  final double price;
  final String? mls;
  final String status;
  final String? source;
  final List<String>? images;
  final List<String>? amenities;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? overview;
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? features;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LandPortfolio({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.type,
    required this.price,
    this.mls,
    this.status = 'for-sale',
    this.source,
    this.images,
    this.amenities,
    this.location,
    this.overview,
    this.details,
    this.features,
    required this.createdAt,
    this.updatedAt,
  });

  factory LandPortfolio.fromFirestore(DocumentSnapshot doc) {
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

    final List<String> imagesList = data['images'] != null
        ? sanitizeImages(data['images'])
        : sanitizeImages(data['imageUrl']);

    final List<String> amenitiesList = data['amenities'] != null
        ? List<String>.from(data['amenities'])
        : (data['view'] != null ? List<String>.from(data['view']) : <String>[]);

    return LandPortfolio(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'land',
      subcategory: data['subcategory'] ?? 'land',
      type: data['type'] ?? 'Land',
      price: toDouble(data['price']),
      mls: data['mls'],
      status: data['status'] ?? 'for-sale',
      source: data['source'],
      images: imagesList,
      amenities: amenitiesList.isNotEmpty ? amenitiesList : null,
      location: data['location'] as Map<String, dynamic>?,
      overview: data['overview'] as Map<String, dynamic>?,
      details: data['details'] as Map<String, dynamic>?,
      features: data['features'] as Map<String, dynamic>?,
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'type': type,
      'price': price,
      if (mls != null) 'mls': mls,
      'status': status,
      if (source != null) 'source': source,
      if (images != null) 'images': images,
      if (amenities != null) 'amenities': amenities,
      if (location != null) 'location': location,
      if (overview != null) 'overview': overview,
      if (details != null) 'details': details,
      if (features != null) 'features': features,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // Helper getters for common fields
  String get locationString {
    if (location == null) return '';
    final parts = <String>[];
    if (location!['quarter'] != null) parts.add(location!['quarter']);
    if (location!['subdivision'] != null) parts.add(location!['subdivision']);
    if (location!['address'] != null) parts.add(location!['address']);
    return parts.join(', ');
  }

  double get lotSizeAcres {
    if (overview == null) return 0;
    return (overview!['lotSizeAcres'] ?? 0).toDouble();
  }

  String get imageUrl {
    if (images == null || images!.isEmpty) return '';
    return images!.first;
  }

  double? get latitude {
    if (location == null) return null;
    final lat = location!['latitude'];
    if (lat == null) return null;
    if (lat is num) return lat.toDouble();
    if (lat is String) return double.tryParse(lat);
    return null;
  }

  double? get longitude {
    if (location == null) return null;
    final lng = location!['longitude'];
    if (lng == null) return null;
    if (lng is num) return lng.toDouble();
    if (lng is String) return double.tryParse(lng);
    return null;
  }
}
