import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/viewing_request.dart';

class ViewingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'viewing_requests';

  // Create a new viewing request
  Future<String> createViewingRequest(ViewingRequest request) async {
    try {
      final docRef = await _firestore.collection(_collection).add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'Error creating viewing request: $e';
    }
  }

  // Get viewing requests by agent ID
  Future<List<ViewingRequest>> getViewingRequestsByAgent(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => ViewingRequest.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching viewing requests: $e';
    }
  }

  // Get viewing requests by user ID
  Future<List<ViewingRequest>> getViewingRequestsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => ViewingRequest.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching viewing requests: $e';
    }
  }

  // Get viewing requests by property ID
  Future<List<ViewingRequest>> getViewingRequestsByProperty(String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('propertyId', isEqualTo: propertyId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => ViewingRequest.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching viewing requests: $e';
    }
  }

  // Update viewing request status
  Future<void> updateViewingStatus(String requestId, String status) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error updating viewing status: $e';
    }
  }

  // Get a single viewing request by ID
  Future<ViewingRequest?> getViewingRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      if (doc.exists) {
        return ViewingRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error fetching viewing request: $e';
    }
  }

  // Delete viewing request
  Future<void> deleteViewingRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).delete();
    } catch (e) {
      throw 'Error deleting viewing request: $e';
    }
  }

  // Stream viewing requests for real-time updates
  Stream<List<ViewingRequest>> streamViewingRequestsByAgent(String agentId) {
    return _firestore
        .collection(_collection)
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ViewingRequest.fromFirestore(doc)).toList());
  }
}
