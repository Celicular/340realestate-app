import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/rental_property.dart';

class RentalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rentalProperties';

  // Get all rental properties
  Future<List<RentalProperty>> getAllRentals() async {
    try {
      final collections = <String>{
        _collection,
        'rentals',
        'Rentals',
        'rental',
      };
      final results = <RentalProperty>[];
      final seen = <String>{};
      for (final col in collections) {
        try {
          final snapshot = await _firestore.collection(col).get();
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final top =
                  (data['status']?.toString() ?? '').trim().toLowerCase();
              final nested = (data['propertyInfo'] is Map)
                  ? (((data['propertyInfo'] as Map<String, dynamic>)['status']
                              ?.toString() ??
                          '')
                      .trim()
                      .toLowerCase())
                  : '';
              final flag = (data['isApproved'] == true);
              final approved =
                  top == 'approved' || nested == 'approved' || flag;
              if (!approved) continue;

              if (seen.add(doc.id)) {
                results.add(RentalProperty.fromFirestore(doc));
              }
            } catch (_) {}
          }
          // Do not break; collect across all potential collections
        } catch (_) {}
      }
      if (kDebugMode) {
        // ignore: avoid_print
        print(
            '[Diagnostics] approved rentals: ${results.length} ids=${results.map((e) => e.id).toList()}');
      }
      return results;
    } catch (e) {
      throw 'Error fetching rentals: $e';
    }
  }

  // Get rentals stream
  Stream<List<RentalProperty>> getRentalsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalProperty.fromFirestore(doc))
            .toList());
  }

  // Get featured rentals
  Future<List<RentalProperty>> getFeaturedRentals() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'approved')
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => RentalProperty.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error fetching featured rentals: $e';
    }
  }

  // Get rental by ID
  Future<RentalProperty?> getRentalById(String rentalId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(rentalId).get();
      if (doc.exists) {
        final rental = RentalProperty.fromFirestore(doc);
        if (rental.status.toLowerCase() != 'approved') return null;
        return rental;
      }
      return null;
    } catch (e) {
      throw 'Error fetching rental: $e';
    }
  }

  // Filter rentals
  Future<List<RentalProperty>> filterRentals({
    double? minRent,
    double? maxRent,
    int? minBedrooms,
    int? minBathrooms,
    bool? petsAllowed,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'approved');

      final snapshot = await query.get();
      var rentals = snapshot.docs
          .map((doc) => RentalProperty.fromFirestore(doc))
          .toList();

      // Apply filters
      if (minRent != null) {
        rentals = rentals.where((r) => r.pricePerNight >= minRent).toList();
      }
      if (maxRent != null) {
        rentals = rentals.where((r) => r.pricePerNight <= maxRent).toList();
      }
      if (minBedrooms != null) {
        rentals = rentals.where((r) => r.bedrooms >= minBedrooms).toList();
      }
      if (minBathrooms != null) {
        rentals = rentals.where((r) => r.bathrooms >= minBathrooms).toList();
      }
      if (petsAllowed != null && petsAllowed) {
        rentals = rentals.where((r) => r.pets).toList();
      }

      return rentals;
    } catch (e) {
      throw 'Error filtering rentals: $e';
    }
  }

  // Search rentals
  Future<List<RentalProperty>> searchRentals(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'approved')
          .get();
      final allRentals = snapshot.docs
          .map((doc) => RentalProperty.fromFirestore(doc))
          .toList();

      return allRentals.where((rental) {
        final titleLower = rental.name.toLowerCase();
        final locationLower = rental.address.toLowerCase();
        final queryLower = query.toLowerCase();
        return titleLower.contains(queryLower) ||
            locationLower.contains(queryLower);
      }).toList();
    } catch (e) {
      throw 'Error searching rentals: $e';
    }
  }

  // Get rentals by IDs (for favorites)
  Future<List<RentalProperty>> getRentalsByIds(List<String> rentalIds) async {
    if (rentalIds.isEmpty) return [];

    try {
      final rentals = <RentalProperty>[];
      // Firestore 'in' query supports max 10 items
      for (var i = 0; i < rentalIds.length; i += 10) {
        final batch = rentalIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        rentals.addAll(snapshot.docs
            .map((doc) => RentalProperty.fromFirestore(doc))
            .where((r) => r.status.toLowerCase() == 'approved')
            .toList());
      }
      return rentals;
    } catch (e) {
      throw 'Error fetching rentals by IDs: $e';
    }
  }

  // Diagnostics: Check presence of pricePerNight field in rentalProperties
  Future<void> diagnosePricePerNightPresence() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      int total = snapshot.docs.length;
      int directCount = 0;
      int inPropInfoCount = 0;
      int inRatesNightlyCount = 0;
      int inRatesWeeklyCount = 0;
      final missingIds = <String>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        bool found = false;
        if (data.containsKey('pricePerNight') &&
            data['pricePerNight'] != null) {
          directCount++;
          found = true;
        }
        if (!found &&
            data['propertyInfo'] is Map &&
            (data['propertyInfo'] as Map<String, dynamic>)['pricePerNight'] !=
                null) {
          inPropInfoCount++;
          found = true;
        }
        if (!found && data['rates'] is Map) {
          final rates = data['rates'] as Map<String, dynamic>;
          if (rates['nightly'] != null) {
            inRatesNightlyCount++;
            found = true;
          }
          if (rates['weekly'] != null ||
              rates['pricePerWeek'] != null ||
              rates['weeklyRate'] != null) {
            inRatesWeeklyCount++;
            found = true;
          }
        }
        if (!found) missingIds.add(doc.id);
      }

      // Print summary to console (visible in debug logs)
      // This is safe and does not modify any data
      // Format: counts and a sample of missing IDs
      // ignore: avoid_print
      print('[Diagnostics] rentalProperties: total=$total');
      // ignore: avoid_print
      print(
          '[Diagnostics] pricePerNight direct=$directCount, propertyInfo=$inPropInfoCount, ratesNightly=$inRatesNightlyCount, ratesWeekly=$inRatesWeeklyCount');
      if (missingIds.isNotEmpty) {
        // ignore: avoid_print
        print(
            '[Diagnostics] Missing price fields for ${missingIds.length} docs. Sample: ${missingIds.take(10).toList()}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[Diagnostics] Error: $e');
    }
  }

  // Diagnostics: Fetch a specific rental document across known collections and print key info
  Future<void> diagnoseRentalDocById(String docId) async {
    final collections = <String>{
      _collection,
      'rentals',
      'Rentals',
      'rental',
    };
    for (final col in collections) {
      try {
        final doc = await _firestore.collection(col).doc(docId).get();
        if (!doc.exists) continue;
        final data = doc.data() as Map<String, dynamic>;
        // ignore: avoid_print
        print('[Diagnostics] Found doc id=$docId in collection=$col');
        // ignore: avoid_print
        print(
            '[Diagnostics] Top-level keys (${data.length}): ${data.keys.toList()}');
        dynamic piStatus;
        if (data['propertyInfo'] is Map) {
          final pi = data['propertyInfo'] as Map<String, dynamic>;
          piStatus = pi['status'];
        }
        dynamic mediaImageLinks;
        if (data['media'] is Map) {
          final media = data['media'] as Map<String, dynamic>;
          mediaImageLinks = media['imageLinks'];
        }
        // ignore: avoid_print
        print(
            '[Diagnostics] status=${data['status']} (${data['status']?.runtimeType}) propertyInfo.status=$piStatus');
        // ignore: avoid_print
        print(
            '[Diagnostics] type=${data['type']} (${data['type']?.runtimeType}) address=${data['address']}');
        // ignore: avoid_print
        print(
            '[Diagnostics] pricePerNight=${data['pricePerNight']} (${data['pricePerNight']?.runtimeType})');
        // ignore: avoid_print
        print(
            '[Diagnostics] bedrooms=${data['bedrooms']} (${data['bedrooms']?.runtimeType}) bathrooms=${data['bathrooms']} (${data['bathrooms']?.runtimeType}) maxGuests=${data['maxGuests'] ?? data['guests']} (${(data['maxGuests'] ?? data['guests'])?.runtimeType})');
        // ignore: avoid_print
        print(
            '[Diagnostics] amenities=${data['amenities']} (${data['amenities']?.runtimeType}) imageLinks=${data['imageLinks']} (${data['imageLinks']?.runtimeType}) media.imageLinks=$mediaImageLinks (${mediaImageLinks?.runtimeType})');

        try {
          final parsed = RentalProperty.fromFirestore(doc);
          // ignore: avoid_print
          print(
              '[Diagnostics] Parsed: name=${parsed.name}, pricePerNight=${parsed.pricePerNight}, bedrooms=${parsed.bedrooms}, status=${parsed.status}, imageUrl=${parsed.imageUrl}');
        } catch (e) {
          // ignore: avoid_print
          print('[Diagnostics] Parse error for id=$docId: $e');
        }
      } catch (e) {
        // ignore: avoid_print
        print('[Diagnostics] Error reading id=$docId from $col: $e');
      }
    }
  }
}
