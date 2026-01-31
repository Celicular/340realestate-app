import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRequest {
  final String id;
  final String propertyId;
  final String status;
  final DateTime requestedAt;
  final DateTime updatedAt;
  
  // Booking details
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final String? season;
  final int totalNights;
  final DateTime? expiresAt;
  
  // Guest info
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String? message;
  
  // Pricing
  final double baseRate;
  final double cleaningFee;
  final double serviceFee;
  final double taxes;
  final double totalAmount;
  
  // Property details
  final String propertyName;
  final String propertyAddress;
  final String? propertySlug;
  final String? propertyType;

  BookingRequest({
    required this.id,
    required this.propertyId,
    required this.status,
    required this.requestedAt,
    required this.updatedAt,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.season,
    required this.totalNights,
    this.expiresAt,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    this.message,
    required this.baseRate,
    required this.cleaningFee,
    required this.serviceFee,
    required this.taxes,
    required this.totalAmount,
    required this.propertyName,
    required this.propertyAddress,
    this.propertySlug,
    this.propertyType,
  });

  factory BookingRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final bookingDetails = data['bookingDetails'] as Map<String, dynamic>? ?? {};
    final guestInfo = data['guestInfo'] as Map<String, dynamic>? ?? {};
    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
    final propertyDetails = data['propertyDetails'] as Map<String, dynamic>? ?? {};

    return BookingRequest(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      status: data['status'] ?? 'pending',
      requestedAt: parseDate(data['requestedAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']) ?? DateTime.now(),
      checkIn: parseDate(bookingDetails['checkIn']) ?? DateTime.now(),
      checkOut: parseDate(bookingDetails['checkOut']) ?? DateTime.now(),
      guests: toInt(bookingDetails['guests']),
      season: bookingDetails['season'] as String?,
      totalNights: toInt(bookingDetails['totalNights']),
      expiresAt: parseDate(bookingDetails['expiresAt']),
      guestName: guestInfo['name'] ?? '',
      guestEmail: guestInfo['email'] ?? '',
      guestPhone: guestInfo['phone'] ?? '',
      message: guestInfo['message'] as String?,
      baseRate: toDouble(pricing['baseRate']),
      cleaningFee: toDouble(pricing['cleaningFee']),
      serviceFee: toDouble(pricing['serviceFee']),
      taxes: toDouble(pricing['taxes']),
      totalAmount: toDouble(pricing['totalAmount']),
      propertyName: propertyDetails['name'] ?? '',
      propertyAddress: propertyDetails['address'] ?? '',
      propertySlug: propertyDetails['slug'] as String?,
      propertyType: propertyDetails['type'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'bookingDetails': {
        'checkIn': Timestamp.fromDate(checkIn),
        'checkOut': Timestamp.fromDate(checkOut),
        'guests': guests,
        if (season != null) 'season': season,
        'totalNights': totalNights,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      },
      'guestInfo': {
        'name': guestName,
        'email': guestEmail,
        'phone': guestPhone,
        if (message != null && message!.isNotEmpty) 'message': message,
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
  }

  // Helper getters
  String get statusDisplay {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
}
