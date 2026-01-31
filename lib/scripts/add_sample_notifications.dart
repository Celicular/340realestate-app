import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script to add sample notifications to Firestore for testing
/// Run this once to populate your notifications collection
Future<void> addSampleNotifications() async {
  final firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    print('No user logged in. Please log in first.');
    return;
  }

  final userId = currentUser.uid;
  print('Adding sample notifications for user: $userId');

  final notifications = [
    {
      'userId': userId,
      'title': 'New Property Match',
      'message': 'A property matching your criteria has been listed in Downtown, San Francisco',
      'type': 'new_match',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'iconType': 'home',
    },
    {
      'userId': userId,
      'title': 'Price Drop Alert',
      'message': 'Modern Luxury Villa price dropped by \$50,000',
      'type': 'price_drop',
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      'isRead': false,
      'iconType': 'trending_down',
    },
    {
      'userId': userId,
      'title': 'Viewing Scheduled',
      'message': 'Your property viewing for Cozy Family Home is scheduled for tomorrow at 2:00 PM',
      'type': 'viewing',
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
      'isRead': false,
      'iconType': 'calendar_today',
    },
    {
      'userId': userId,
      'title': 'Agent Response',
      'message': 'Sarah Johnson replied to your inquiry about Urban Loft Apartment',
      'type': 'agent_response',
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
      'isRead': true,
      'iconType': 'message',
    },
    {
      'userId': userId,
      'title': 'New Listing',
      'message': '5 new properties added in your saved search area',
      'type': 'new_listing',
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'isRead': true,
      'iconType': 'add_circle',
    },
    {
      'userId': userId,
      'title': 'Favorite Property Update',
      'message': 'Beachfront Condo has new photos and updated amenities',
      'type': 'favorite_update',
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'isRead': true,
      'iconType': 'favorite',
    },
    {
      'userId': userId,
      'title': 'Market Report',
      'message': 'Monthly market report for Los Angeles is now available',
      'type': 'market_report',
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'isRead': true,
      'iconType': 'assessment',
    },
  ];

  try {
    for (final notification in notifications) {
      await firestore.collection('notifications').add(notification);
    }
    print('✅ Successfully added ${notifications.length} sample notifications!');
  } catch (e) {
    print('❌ Error adding notifications: $e');
  }
}

/// To use this script:
/// 1. Import this file in your app
/// 2. Call addSampleNotifications() from anywhere in your app (e.g., a debug button)
/// 3. The notifications will be created for the currently logged-in user
