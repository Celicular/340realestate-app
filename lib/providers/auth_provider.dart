import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart' as app_user;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  auth.User? _firebaseUser;
  app_user.User? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  auth.User? get firebaseUser => _firebaseUser;
  auth.User? get user => _firebaseUser; // Alias for compatibility
  app_user.User? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  String? get userId => _firebaseUser?.uid;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
        _userService.updateLastLogin(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      _userProfile = await _userService.getUserById(userId);
      if (_userProfile == null && _firebaseUser != null) {
        await _userService.updateUser(userId, {
          'uid': userId,
          'email': _firebaseUser!.email ?? '',
          'displayName': _firebaseUser!.displayName ?? '',
          'name': _firebaseUser!.displayName ?? '',
        });
        _userProfile = await _userService.getUserById(userId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up as an agent
  Future<bool> signUpAsAgent({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    required String agencyName,
    required String licenseNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );

      if (userCredential != null && userCredential.user != null) {
        await _userService.updateUser(userCredential.user!.uid, {
          'role': 'agent',
          'agencyName': agencyName,
          'licenseNumber': licenseNumber,
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google - Temporarily disabled
  /*
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return result != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  */

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newName =
          (data['displayName'] as String?) ?? (data['name'] as String?);
      if (newName != null && newName.isNotEmpty) {
        await _authService.currentUser?.updateDisplayName(newName);
      }
      await _userService.updateUser(userId!, data);
      await _loadUserProfile(userId!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite property
  Future<void> toggleFavorite(String propertyId) async {
    if (userId == null) return;

    final isFav =
        _userProfile?.favoriteProperties.contains(propertyId) ?? false;

    try {
      if (isFav) {
        await _userService.removeFromFavorites(userId!, propertyId);
      } else {
        await _userService.addToFavorites(userId!, propertyId);
      }
      await _loadUserProfile(userId!);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Optionally set error state
    }
  }

  // Add recently viewed property
  Future<void> addRecentlyViewed(String propertyId) async {
    if (userId == null) return;
    try {
      await _userService.addRecentlyViewed(userId!, propertyId);
      await _loadUserProfile(userId!);
    } catch (e) {
      debugPrint('Error adding recently viewed: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
