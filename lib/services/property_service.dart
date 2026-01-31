import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'properties';
  final String _viewingsCollection = 'viewingRequests';

  // Get all properties
  Future<List<Property>> getAllProperties() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching properties: $e';
    }
  }

  // Viewing Requests
  Future<bool> isViewingSlotAvailable({
    required String propertyId,
    required String selectedDate,
    required String selectedTime,
  }) async {
    try {
      final snap = await _firestore
          .collection(_viewingsCollection)
          .where('propertyId', isEqualTo: propertyId)
          .where('selectedDate', isEqualTo: selectedDate)
          .where('selectedTime', isEqualTo: selectedTime)
          .limit(1)
          .get();
      return snap.docs.isEmpty;
    } catch (e) {
      throw 'Error checking slot: $e';
    }
  }

  Future<void> scheduleViewing({
    required String propertyId,
    required String fullName,
    required String email,
    required String mobile,
    required String selectedDate,
    required String selectedTime,
  }) async {
    final cleanTimeKey = selectedTime
        .replaceAll(':', '')
        .replaceAll(' ', '')
        .replaceAll('/', '')
        .toLowerCase();
    final docId = '${propertyId}_${selectedDate}_$cleanTimeKey';
    final docRef = _firestore.collection(_viewingsCollection).doc(docId);
    await _firestore.runTransaction((txn) async {
      final existing = await txn.get(docRef);
      if (existing.exists) {
        throw 'This time slot is already booked';
      }
      txn.set(docRef, {
        'propertyId': propertyId,
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'selectedDate': selectedDate,
        'selectedTime': selectedTime,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get properties stream
  Stream<List<Property>> getPropertiesStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList());
  }

  // Get featured properties
  Future<List<Property>> getFeaturedProperties() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isFeatured', isEqualTo: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching featured properties: $e';
    }
  }

  // Get featured properties stream
  Stream<List<Property>> getFeaturedPropertiesStream() {
    return _firestore
        .collection(_collection)
        .where('isFeatured', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList());
  }

  // Get property by ID
  Future<Property?> getPropertyById(String propertyId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(propertyId).get();
      if (doc.exists) {
        return Property.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error fetching property: $e';
    }
  }

  // Get property stream by ID
  Stream<Property?> getPropertyStream(String propertyId) {
    return _firestore
        .collection(_collection)
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.exists ? Property.fromFirestore(doc) : null);
  }

  // Get properties by type
  Future<List<Property>> getPropertiesByType(PropertyType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .get();
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching properties by type: $e';
    }
  }

  // Search properties
  Future<List<Property>> searchProperties(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final allProperties =
          snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();

      // Filter by name or location
      return allProperties.where((property) {
        final nameLower = property.name.toLowerCase();
        final locationLower = property.location.toLowerCase();
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower) ||
            locationLower.contains(queryLower);
      }).toList();
    } catch (e) {
      throw 'Error searching properties: $e';
    }
  }

  // Filter properties
  Future<List<Property>> filterProperties({
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? minBathrooms,
    PropertyType? type,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.get();
      var properties =
          snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();

      // Apply filters
      if (minPrice != null) {
        properties = properties.where((p) => p.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        properties = properties.where((p) => p.price <= maxPrice).toList();
      }
      if (minBedrooms != null) {
        properties =
            properties.where((p) => p.bedrooms >= minBedrooms).toList();
      }
      if (minBathrooms != null) {
        properties =
            properties.where((p) => p.bathrooms >= minBathrooms).toList();
      }

      return properties;
    } catch (e) {
      throw 'Error filtering properties: $e';
    }
  }

  // Get properties by IDs (for favorites)
  Future<List<Property>> getPropertiesByIds(List<String> propertyIds) async {
    if (propertyIds.isEmpty) return [];

    try {
      final properties = <Property>[];
      // Firestore 'in' query supports max 10 items
      for (var i = 0; i < propertyIds.length; i += 10) {
        final batch = propertyIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        properties.addAll(
            snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList());
      }
      return properties;
    } catch (e) {
      throw 'Error fetching properties by IDs: $e';
    }
  }

  // ===== AGENT PROPERTY MANAGEMENT =====

  // Create a new property (for agents)
  Future<String> createProperty(Property property) async {
    try {
      final docRef = await _firestore.collection(_collection).add(property.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'Error creating property: $e';
    }
  }

  // Update property
  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(propertyId).update(data);
    } catch (e) {
      throw 'Error updating property: $e';
    }
  }

  // Delete property
  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection(_collection).doc(propertyId).delete();
    } catch (e) {
      throw 'Error deleting property: $e';
    }
  }

  // Get properties by agent ID
  Future<List<Property>> getPropertiesByAgent(String agentId) async {
    try {
      // Simple query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_collection)
          .where('agentId', isEqualTo: agentId)
          .get();
      
      final properties = snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
      
      // Sort by name in Dart (since we can't easily sort by createdAt without index)
      properties.sort((a, b) => b.name.compareTo(a.name));
      
      return properties;
    } catch (e) {
      print('Error fetching agent properties: $e');
      throw 'Error fetching agent properties: $e';
    }
  }

  // Stream properties by agent ID
  Stream<List<Property>> streamPropertiesByAgent(String agentId) {
    return _firestore
        .collection(_collection)
        .where('agentId', isEqualTo: agentId)
        .snapshots()
        .map((snapshot) {
          final properties = snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
          properties.sort((a, b) => b.name.compareTo(a.name));
          return properties;
        });
  }
}
