import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error fetching user: $e';
    }
  }

  // Get user stream
  Stream<User?> getUserStream(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? User.fromFirestore(doc) : null);
  }

  // Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(userId).set({
        ...data,
        'uid': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Error updating user: $e';
    }
  }

  // Add property to favorites
  Future<void> addToFavorites(String userId, String propertyId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'favoriteProperties': FieldValue.arrayUnion([propertyId]),
      });
    } catch (e) {
      throw 'Error adding to favorites: $e';
    }
  }

  // Remove property from favorites
  Future<void> removeFromFavorites(String userId, String propertyId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'favoriteProperties': FieldValue.arrayRemove([propertyId]),
      });
    } catch (e) {
      throw 'Error removing from favorites: $e';
    }
  }

  // Get user's favorite properties
  Future<List<String>> getFavorites(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        final user = User.fromFirestore(doc);
        return user.favoriteProperties;
      }
      return [];
    } catch (e) {
      throw 'Error fetching favorites: $e';
    }
  }

  // Recently viewed
  Future<List<String>> getRecentlyViewed(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        final user = User.fromFirestore(doc);
        return user.recentlyViewed;
      }
      return [];
    } catch (e) {
      throw 'Error fetching recently viewed: $e';
    }
  }

  Future<void> addRecentlyViewed(String userId, String propertyId, {int limit = 50}) async {
    try {
      final ref = _firestore.collection(_collection).doc(userId);
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(ref);
        List<dynamic> listDyn = [];
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final rv = (data['recentlyViewed'] as List?) ?? [];
          listDyn = List<dynamic>.from(rv);
        }
        final list = listDyn.map((e) => e.toString()).toList();
        list.remove(propertyId);
        list.insert(0, propertyId);
        if (list.length > limit) {
          list.removeRange(limit, list.length);
        }
        txn.set(ref, {
          'uid': userId,
          'recentlyViewed': list,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw 'Error updating recently viewed: $e';
    }
  }

  // Check if property is favorited
  Future<bool> isFavorite(String userId, String propertyId) async {
    try {
      final favorites = await getFavorites(userId);
      return favorites.contains(propertyId);
    } catch (e) {
      return false;
    }
  }

  // Update last login
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }
}
