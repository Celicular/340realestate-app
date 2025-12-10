import 'package:flutter/foundation.dart';
import '../models/rental_property.dart';
import '../services/rental_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class RentalProvider with ChangeNotifier {
  final RentalService _rentalService = RentalService();

  List<RentalProperty> _rentals = [];
  List<RentalProperty> _filteredRentals = [];

  bool _isLoading = false;
  String? _error;

  // Filters
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  int? _minBedrooms;
  String _sortOption = 'none'; // none, price_asc, price_desc, newest, oldest, distance
  String _priceMode = 'week'; // 'night' or 'week'
  String? _locationQuery;
  String? _propertyType;
  Position? _userLocation;
  double? _maxDistance; // in kilometers

  // Getters
  List<RentalProperty> get rentals => _rentals;
  List<RentalProperty> get filteredRentals => _filteredRentals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get priceMode => _priceMode;

  // Fetch all rentals
  Future<void> fetchRentals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rentals = await _rentalService.getAllRentals();
      if (kDebugMode) {
        // Firestore diagnostics: check where price fields live
        _rentalService.diagnosePricePerNightPresence();
        // Additional: print the specific doc causing issues, if any
        _rentalService.diagnoseRentalDocById('hfky8uAsCQLvguCaPNDS');
      }
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search rentals
  void searchRentals(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterRentals({
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    String? sortOption,
    String? priceMode,
    String? location,
    String? propertyType,
    Position? userLocation,
    double? maxDistance,
  }) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minBedrooms = minBedrooms;
    if (sortOption != null) _sortOption = sortOption;
    if (priceMode != null) _priceMode = priceMode;
    _locationQuery = location;
    _propertyType = propertyType;
    _userLocation = userLocation;
    _maxDistance = maxDistance;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredRentals = _rentals.where((rental) {
      if (rental.status.trim().toLowerCase() != 'approved') {
        return false;
      }
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = rental.name.toLowerCase();
        final location = rental.address.toLowerCase();
        if (!title.contains(query) && !location.contains(query)) {
          return false;
        }
      }

      if (_locationQuery != null && _locationQuery!.trim().isNotEmpty) {
        final q = _locationQuery!.toLowerCase().trim();
        if (!rental.address.toLowerCase().contains(q)) {
          return false;
        }
      }

      if (_propertyType != null && _propertyType!.trim().isNotEmpty) {
        if (rental.type.toLowerCase() != _propertyType!.toLowerCase()) {
          return false;
        }
      }

      // Price filter (based on mode)
      final basePrice = _priceMode == 'night'
          ? rental.pricePerNight
          : rental.pricePerNight * 7;
      if (_minPrice != null && basePrice < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && basePrice > _maxPrice!) {
        return false;
      }

      // Bedrooms filter
      if (_minBedrooms != null && rental.bedrooms < _minBedrooms!) {
        return false;
      }

      // Distance filter
      if (_userLocation != null && _maxDistance != null) {
        if (rental.latitude != null && rental.longitude != null) {
          final distance = LocationService.calculateDistance(
            startLatitude: _userLocation!.latitude,
            startLongitude: _userLocation!.longitude,
            endLatitude: rental.latitude!,
            endLongitude: rental.longitude!,
          );
          if (distance > _maxDistance!) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Sorting
    switch (_sortOption) {
      case 'price_asc':
        _filteredRentals.sort((a, b) {
          final ap =
              _priceMode == 'night' ? a.pricePerNight : a.pricePerNight * 7;
          final bp =
              _priceMode == 'night' ? b.pricePerNight : b.pricePerNight * 7;
          return ap.compareTo(bp);
        });
        break;
      case 'price_desc':
        _filteredRentals.sort((a, b) {
          final ap =
              _priceMode == 'night' ? a.pricePerNight : a.pricePerNight * 7;
          final bp =
              _priceMode == 'night' ? b.pricePerNight : b.pricePerNight * 7;
          return bp.compareTo(ap);
        });
        break;
      case 'newest':
        _filteredRentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        _filteredRentals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'distance':
        if (_userLocation != null) {
          _filteredRentals.sort((a, b) {
            if (a.latitude == null || a.longitude == null) return 1;
            if (b.latitude == null || b.longitude == null) return -1;
            final distA = LocationService.calculateDistance(
              startLatitude: _userLocation!.latitude,
              startLongitude: _userLocation!.longitude,
              endLatitude: a.latitude!,
              endLongitude: a.longitude!,
            );
            final distB = LocationService.calculateDistance(
              startLatitude: _userLocation!.latitude,
              startLongitude: _userLocation!.longitude,
              endLatitude: b.latitude!,
              endLongitude: b.longitude!,
            );
            return distA.compareTo(distB);
          });
        }
        break;
      default:
        break;
    }
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _minPrice = null;
    _maxPrice = null;
    _minBedrooms = null;
    _sortOption = 'none';
    _locationQuery = null;
    _propertyType = null;
    _applyFilters();
    notifyListeners();
  }
}
