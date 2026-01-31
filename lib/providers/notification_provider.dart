import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/fcm_notification.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FCMService _fcmService = FCMService();
  final NotificationService _notificationService = NotificationService();

  List<FCMNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  List<FCMNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize FCM
  Future<void> initializeFCM() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _fcmService.initializeNotifications();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error initializing FCM: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get FCM token and save to Firestore
  Future<String?> getAndSaveToken(String userId) async {
    try {
      final token = await _fcmService.getToken();
      if (token != null) {
        await _fcmService.saveTokenToFirestore(userId, token);
      }
      return token;
    } catch (e) {
      print('Error getting/saving token: $e');
      return null;
    }
  }

  // Fetch notifications
  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notificationService.getUserNotifications(userId).listen((notifs) {
        _notifications =
            notifs.map((n) => _convertToFCMNotification(n)).toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert NotificationModel to FCMNotification
  FCMNotification _convertToFCMNotification(dynamic notification) {
    return FCMNotification(
      id: notification.id,
      userId: notification.userId,
      title: notification.title,
      body: notification.message,
      type: notification.type,
      data: {'relatedPropertyId': notification.relatedPropertyId},
      timestamp: notification.timestamp,
      isRead: notification.isRead,
      sentViaFCM: false,
    );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Handle incoming notification from FCM
  void handleIncomingNotification(RemoteMessage message) {
    try {
      final notification = FCMNotification(
        id: message.messageId ?? DateTime.now().toString(),
        userId: message.data['userId'] ?? '',
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        type: message.data['type'] ?? '',
        data: message.data,
        timestamp: DateTime.now(),
        isRead: false,
        sentViaFCM: true,
      );

      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    } catch (e) {
      print('Error handling incoming notification: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcmService.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcmService.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Clear all data
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
