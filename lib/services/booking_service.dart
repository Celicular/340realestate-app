import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_request.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a booking request in the subcollection under rentalProperties
  Future<String> createBookingRequest({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    String? message,
    required double baseRate,
    double cleaningFee = 0,
    double serviceFee = 0,
    double taxes = 0,
    required String propertyName,
    required String propertyAddress,
    String? propertySlug,
    String? propertyType,
  }) async {
    final totalNights = checkOut.difference(checkIn).inDays;
    final totalAmount = baseRate + cleaningFee + serviceFee + taxes;
    
    // Determine season (simple logic - can be customized)
    final month = checkIn.month;
    final season = (month >= 12 || month <= 4) ? 'inSeason' : 'offSeason';
    
    // Expires 48 hours after checkout
    final expiresAt = checkOut.add(const Duration(hours: 48));

    final bookingData = {
      'propertyId': propertyId,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'bookingDetails': {
        'checkIn': Timestamp.fromDate(checkIn),
        'checkOut': Timestamp.fromDate(checkOut),
        'guests': guests,
        'season': season,
        'totalNights': totalNights,
        'expiresAt': Timestamp.fromDate(expiresAt),
      },
      'guestInfo': {
        'name': guestName,
        'email': guestEmail,
        'phone': guestPhone,
        if (message != null && message.isNotEmpty) 'message': message,
      },
      'pricing': {
        'baseRate': baseRate,
        'cleaningFee': cleaningFee,
        'serviceFee': serviceFee,
        'taxes': taxes,
        'totalAmount': totalAmount,
        'totalNights': totalNights,
      },
      'propertyDetails': {
        'name': propertyName,
        'address': propertyAddress,
        if (propertySlug != null) 'slug': propertySlug,
        if (propertyType != null) 'type': propertyType,
      },
      'metadata': {
        'source': 'mobile_app',
      },
    };

    final docRef = await _firestore
        .collection('rentalProperties')
        .doc(propertyId)
        .collection('bookingRequests')
        .add(bookingData);

    return docRef.id;
  }

  /// Get all booking requests for a specific property
  Future<List<BookingRequest>> getPropertyBookings(String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection('rentalProperties')
          .doc(propertyId)
          .collection('bookingRequests')
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookingRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all booking requests by guest email (for user's booking history)
  Future<List<BookingRequest>> getBookingsByEmail(String email) async {
    try {
      // Get all rental properties
      final propertiesSnapshot = await _firestore
          .collection('rentalProperties')
          .get();

      final List<BookingRequest> allBookings = [];

      // For each property, check for bookings with matching email
      for (final propertyDoc in propertiesSnapshot.docs) {
        final bookingsSnapshot = await _firestore
            .collection('rentalProperties')
            .doc(propertyDoc.id)
            .collection('bookingRequests')
            .where('guestInfo.email', isEqualTo: email)
            .orderBy('requestedAt', descending: true)
            .get();

        allBookings.addAll(
          bookingsSnapshot.docs.map((doc) => BookingRequest.fromFirestore(doc)),
        );
      }

      // Sort all bookings by date
      allBookings.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return allBookings;
    } catch (e) {
      // If the query fails (likely due to index), try without ordering
      try {
        final propertiesSnapshot = await _firestore
            .collection('rentalProperties')
            .get();

        final List<BookingRequest> allBookings = [];

        for (final propertyDoc in propertiesSnapshot.docs) {
          final bookingsSnapshot = await _firestore
              .collection('rentalProperties')
              .doc(propertyDoc.id)
              .collection('bookingRequests')
              .get();

          // Filter locally by email
          final filtered = bookingsSnapshot.docs
              .map((doc) => BookingRequest.fromFirestore(doc))
              .where((b) => b.guestEmail.toLowerCase() == email.toLowerCase());

          allBookings.addAll(filtered);
        }

        allBookings.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        return allBookings;
      } catch (_) {
        return [];
      }
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String propertyId, String bookingId) async {
    await _firestore
        .collection('rentalProperties')
        .doc(propertyId)
        .collection('bookingRequests')
        .doc(bookingId)
        .update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get a single booking request
  Future<BookingRequest?> getBooking(String propertyId, String bookingId) async {
    try {
      final doc = await _firestore
          .collection('rentalProperties')
          .doc(propertyId)
          .collection('bookingRequests')
          .doc(bookingId)
          .get();

      if (doc.exists) {
        return BookingRequest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
