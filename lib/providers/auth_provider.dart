import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/email_service.dart';
import '../services/fcm_service.dart';
import '../models/user.dart' as app_user;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final EmailService _emailService = EmailService();
  final FCMService _fcmService = FCMService();

  // SharedPreferences keys for caching
  static const String _cachedRoleKey = 'cached_user_role';
  static const String _cachedUserIdKey = 'cached_user_id';

  auth.User? _firebaseUser;
  app_user.User? _userProfile;
  bool _isLoading = false;
  String? _error;
  String? _cachedRole; // Cached role for immediate access
  
  // OTP verification state
  String? _generatedOtp;
  bool _isOtpVerified = false;

  // Getters
  auth.User? get firebaseUser => _firebaseUser;
  auth.User? get user => _firebaseUser; // Alias for compatibility
  app_user.User? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  String? get userId => _firebaseUser?.uid;
  
  // Cached role getter for immediate routing decisions
  String? get cachedRole => _cachedRole;
  bool get isAgentFromCache => _cachedRole == 'agent';
  
  // OTP verification getters
  bool get isOtpVerified => _isOtpVerified;
  String? get generatedOtp => _generatedOtp;

  AuthProvider() {
    // Load cached role on startup
    _loadCachedRole();
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
        _userService.updateLastLogin(user.uid);
      } else {
        _userProfile = null;
        _clearCachedRole();
      }
      notifyListeners();
    });
  }

  // Load cached role from SharedPreferences
  Future<void> _loadCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedRole = prefs.getString(_cachedRoleKey);
      final cachedUserId = prefs.getString(_cachedUserIdKey);
      
      debugPrint('=== CACHED ROLE LOADED ===');
      debugPrint('Cached role: $_cachedRole');
      debugPrint('Cached user ID: $cachedUserId');
      debugPrint('==========================');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached role: $e');
    }
  }

  // Save role to SharedPreferences
  Future<void> _cacheRole(String userId, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedRoleKey, role);
      await prefs.setString(_cachedUserIdKey, userId);
      _cachedRole = role;
      
      debugPrint('=== ROLE CACHED ===');
      debugPrint('Cached role: $role');
      debugPrint('Cached user ID: $userId');
      debugPrint('===================');
    } catch (e) {
      debugPrint('Error caching role: $e');
    }
  }

  // Clear cached role on logout
  Future<void> _clearCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedRoleKey);
      await prefs.remove(_cachedUserIdKey);
      _cachedRole = null;
      debugPrint('Cached role cleared');
    } catch (e) {
      debugPrint('Error clearing cached role: $e');
    }
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
      
      // Cache the role for future app restarts
      if (_userProfile != null) {
        await _cacheRole(userId, _userProfile!.role);
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

      // Save FCM token after successful login
      if (_firebaseUser != null) {
        final token = await _fcmService.getToken();
        if (token != null) {
          await _fcmService.saveTokenToFirestore(_firebaseUser!.uid, token);
        }
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
      _isOtpVerified = false;
      _generatedOtp = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount();
      _userProfile = null;
      _isOtpVerified = false;
      _generatedOtp = null;
      _isLoading = false;
      await _clearCachedRole();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
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

  // ============ OTP VERIFICATION METHODS ============

  /// Generates and sends an OTP to the specified email address.
  /// Returns the generated OTP if successful, null otherwise.
  Future<String?> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _generatedOtp = EmailService.generateOtp();
      final success = await _emailService.sendOtp(email, _generatedOtp!);
      
      _isLoading = false;
      notifyListeners();

      if (success) {
        debugPrint('OTP sent successfully to $email');
        return _generatedOtp;
      } else {
        _error = 'Failed to send verification email. Please try again.';
        return null;
      }
    } catch (e) {
      _error = 'Error sending OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Verifies the entered OTP against the generated OTP.
  /// Returns true if the OTP is correct.
  bool verifyOtp(String enteredOtp) {
    if (_generatedOtp == null) {
      _error = 'No OTP was generated. Please request a new OTP.';
      notifyListeners();
      return false;
    }

    if (enteredOtp == _generatedOtp) {
      _isOtpVerified = true;
      _generatedOtp = null; // Clear OTP after successful verification
      notifyListeners();
      return true;
    } else {
      _error = 'Invalid verification code. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Resets OTP verification state
  void resetOtpState() {
    _isOtpVerified = false;
    _generatedOtp = null;
    notifyListeners();
  }

  /// Sets OTP verified status (used when OTP is verified in UI)
  void setOtpVerified(bool verified) {
    _isOtpVerified = verified;
    notifyListeners();
  }
}
