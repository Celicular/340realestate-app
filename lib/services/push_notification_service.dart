import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/viewing_request.dart';

class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // Send new listing notification
  Future<void> sendNewListingNotification(
    Property property,
    List<String> userIds,
  ) async {
    try {
      for (final userId in userIds) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': 'New Property Listed!',
          'body': '${property.name} is now available for \$${property.price}',
          'type': 'new_listing',
          'data': {
            'propertyId': property.id,
            'type': 'new_listing',
          },
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'sentViaFCM': true,
          'relatedPropertyId': property.id,
          'iconType': 'home',
        });
      }
    } catch (e) {
      print('Error sending new listing notification: $e');
    }
  }

  // Send price change notification
  Future<void> sendPriceChangeNotification(
    Property property,
    double oldPrice,
    double newPrice,
    List<String> userIds,
  ) async {
    try {
      final priceChange = newPrice - oldPrice;
      final isIncrease = priceChange > 0;
      final changeText = isIncrease ? 'increased' : 'decreased';
      final emoji = isIncrease ? '📈' : '📉';

      for (final userId in userIds) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': '$emoji Price Update!',
          'body':
              '${property.name} price $changeText to \$${newPrice.toStringAsFixed(0)}',
          'type': 'price_change',
          'data': {
            'propertyId': property.id,
            'oldPrice': oldPrice,
            'newPrice': newPrice,
            'type': 'price_change',
          },
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'sentViaFCM': true,
          'relatedPropertyId': property.id,
          'iconType': 'attach_money',
        });
      }
    } catch (e) {
      print('Error sending price change notification: $e');
    }
  }

  // Send appointment reminder notification
  Future<void> sendAppointmentReminderNotification(
    ViewingRequest viewingRequest,
    String timeBeforeText,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': viewingRequest.userId,
        'title': 'Viewing Reminder',
        'body':
            'Your property viewing is $timeBeforeText! Don\'t forget to check the details.',
        'type': 'appointment',
        'data': {
          'viewingRequestId': viewingRequest.id,
          'propertyId': viewingRequest.propertyId,
          'type': 'appointment',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sentViaFCM': true,
        'relatedPropertyId': viewingRequest.propertyId,
        'iconType': 'calendar_today',
      });
    } catch (e) {
      print('Error sending appointment reminder: $e');
    }
  }

  // Send appointment status notification
  Future<void> sendAppointmentStatusNotification(
    ViewingRequest viewingRequest,
    String status,
  ) async {
    try {
      String title = '';
      String body = '';

      switch (status) {
        case 'confirmed':
          title = '✅ Viewing Confirmed!';
          body =
              'Your viewing request has been confirmed. Check the details for the date and time.';
          break;
        case 'cancelled':
          title = '❌ Viewing Cancelled';
          body =
              'Unfortunately, your viewing request has been cancelled. Contact the agent for more details.';
          break;
        case 'completed':
          title = '🎉 Viewing Completed';
          body = 'Thank you for visiting! Let us know if you have any questions.';
          break;
        default:
          title = 'Viewing Update';
          body = 'Your viewing request status has been updated to: $status';
      }

      await _firestore.collection('notifications').add({
        'userId': viewingRequest.userId,
        'title': title,
        'body': body,
        'type': 'appointment',
        'data': {
          'viewingRequestId': viewingRequest.id,
          'propertyId': viewingRequest.propertyId,
          'status': status,
          'type': 'appointment',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sentViaFCM': true,
        'relatedPropertyId': viewingRequest.propertyId,
        'iconType': 'calendar_today',
      });
    } catch (e) {
      print('Error sending appointment status notification: $e');
    }
  }

  // Send chat message notification
  Future<void> sendChatMessageNotification(
    String userId,
    String chatId,
    String senderId,
    String message,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': '💬 New Message',
        'body': message.length > 50
            ? '${message.substring(0, 50)}...'
            : message,
        'type': 'chat_message',
        'data': {
          'chatId': chatId,
          'senderId': senderId,
          'type': 'chat_message',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sentViaFCM': true,
        'iconType': 'chat',
      });
    } catch (e) {
      print('Error sending chat message notification: $e');
    }
  }

  // Schedule appointment reminder
  Future<void> scheduleAppointmentReminder(
    ViewingRequest viewingRequest,
    Duration duration,
  ) async {
    // This would typically be handled by a backend service
    // For now, we'll just store the reminder info
    try {
      await _firestore.collection('appointment_reminders').add({
        'viewingRequestId': viewingRequest.id,
        'userId': viewingRequest.userId,
        'reminderTime': Timestamp.fromDate(
          viewingRequest.requestedDate.subtract(duration),
        ),
        'isSent': false,
        'type': duration.inHours >= 24
            ? '24h'
            : duration.inHours >= 1
                ? '1h'
                : '30m',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error scheduling appointment reminder: $e');
    }
  }

  // Send comparison saved notification
  Future<void> sendComparisonSavedNotification(
    String userId,
    String comparisonName,
    int propertyCount,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': '✨ Comparison Saved',
        'body':
            'Your comparison "$comparisonName" with $propertyCount properties has been saved.',
        'type': 'comparison',
        'data': {
          'type': 'comparison',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sentViaFCM': true,
        'iconType': 'compare_arrows',
      });
    } catch (e) {
      print('Error sending comparison saved notification: $e');
    }
  }

  // Send KYC status notification
  Future<void> sendKYCStatusNotification(
    String userId,
    String status,
    String? reason,
  ) async {
    try {
      String title = '';
      String body = '';

      switch (status) {
        case 'approved':
          title = '✅ KYC Verified!';
          body = 'Your identity verification has been approved. You now have full access.';
          break;
        case 'rejected':
          title = '❌ KYC Rejected';
          body = reason ?? 'Your verification was not approved. Please resubmit with correct documents.';
          break;
        case 'underReview':
          title = '⏳ KYC Under Review';
          body = 'Your documents are being reviewed. We\'ll notify you once complete.';
          break;
        default:
          title = 'KYC Update';
          body = 'Your KYC status has been updated.';
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'kyc',
        'data': {
          'status': status,
          'type': 'kyc',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sentViaFCM': true,
        'iconType': 'verified_user',
      });
    } catch (e) {
      print('Error sending KYC status notification: $e');
    }
  }
}
