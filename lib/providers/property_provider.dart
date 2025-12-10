import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/rental_property.dart';
import '../services/property_service.dart';
import '../services/rental_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class PropertyProvider with ChangeNotifier {
  final PropertyService _propertyService = PropertyService();
  final RentalService _rentalService = RentalService();

  List<Property> _properties = [];
  List<Property> _featuredProperties = [];
  List<Property> _filteredProperties = [];

  bool _isLoading = false;
  String? _error;

  // Filters
  String _searchQuery = '';
  String? _selectedType;
  double? _minPrice;
  double? _maxPrice;
  String _sortOption = 'none'; // none, price_asc, price_desc, distance
  Position? _userLocation;
  double? _maxDistance; // in kilometers

  // Getters
  List<Property> get properties => _properties;
  List<Property> get featuredProperties => _featuredProperties;
  List<Property> get filteredProperties => _filteredProperties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all properties (Sale + Rentals)
  Future<void> fetchProperties() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch both concurrently
      final results = await Future.wait([
        _propertyService.getAllProperties(),
        _rentalService.getAllRentals(),
      ]);

      final saleProperties = results[0] as List<Property>;
      final rentalProperties = results[1] as List<RentalProperty>;

      // Map rentals to Property objects
      final mappedRentals = rentalProperties
          .map((rental) => _mapRentalToProperty(rental))
          .toList();

      // Combine lists
      _properties = [...saleProperties, ...mappedRentals];

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to map RentalProperty to Property
  Property _mapRentalToProperty(RentalProperty rental) {
    return Property(
      id: rental.id,
      name: rental.name,
      location: rental.address,
      price: rental.pricePerNight * 7,
      imageUrl: rental.imageUrl,
      description: rental.description,
      bedrooms: rental.bedrooms,
      bathrooms: rental.bathrooms,
      sqft: 0,
      amenities: rental.amenities,
      isFeatured: false,
      type: PropertyType.rental,
      latitude: rental.latitude,
      longitude: rental.longitude,
    );
  }

  // Fetch featured properties
  Future<void> fetchFeaturedProperties() async {
    if (_properties.isEmpty) {
      await fetchProperties();
    }
    _featuredProperties = _properties.where((p) => p.isFeatured).toList();
    notifyListeners();
  }

  // Search properties
  void searchProperties(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter properties
  void filterProperties({
    String? type,
    double? minPrice,
    double? maxPrice,
    String? sortOption,
    Position? userLocation,
    double? maxDistance,
  }) {
    if (type != null) _selectedType = type;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    if (sortOption != null) _sortOption = sortOption;
    _userLocation = userLocation;
    _maxDistance = maxDistance;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProperties = _properties.where((property) {
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = property.name.toLowerCase();
        final location = property.location.toLowerCase();
        if (!name.contains(query) && !location.contains(query)) {
          return false;
        }
      }

      // Type filter
      if (_selectedType != null && property.type.name != _selectedType) {
        return false;
      }

      // Price filter
      if (_minPrice != null && property.price < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && property.price > _maxPrice!) {
        return false;
      }

      // Distance filter
      if (_userLocation != null && _maxDistance != null) {
        if (property.latitude != null && property.longitude != null) {
          final distance = LocationService.calculateDistance(
            startLatitude: _userLocation!.latitude,
            startLongitude: _userLocation!.longitude,
            endLatitude: property.latitude!,
            endLongitude: property.longitude!,
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
        _filteredProperties.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        _filteredProperties.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'distance':
        if (_userLocation != null) {
          _filteredProperties.sort((a, b) {
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
    _selectedType = null;
    _minPrice = null;
    _maxPrice = null;
    _sortOption = 'none';
    _applyFilters();
    notifyListeners();
  }

  // Favorites
  List<Property> _favoriteProperties = [];
  List<Property> get favoritePropertiesList => _favoriteProperties;

  Future<void> fetchFavorites(List<String> ids) async {
    if (ids.isEmpty) {
      _favoriteProperties = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Try fetching from properties first
      final properties = await _propertyService.getPropertiesByIds(ids);

      // Identify missing IDs
      final foundIds = properties.map((p) => p.id).toSet();
      final missingIds = ids.where((id) => !foundIds.contains(id)).toList();

      if (missingIds.isNotEmpty) {
        // Try fetching from rentals
        final rentals = await _rentalService.getRentalsByIds(missingIds);
        final mappedRentals =
            rentals.map((r) => _mapRentalToProperty(r)).toList();
        properties.addAll(mappedRentals);
      }

      _favoriteProperties = properties;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recently viewed
  List<Property> _recentlyViewedProperties = [];
  List<Property> get recentlyViewedPropertiesList => _recentlyViewedProperties;

  Future<void> fetchRecentlyViewed(List<String> ids) async {
    if (ids.isEmpty) {
      _recentlyViewedProperties = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      var properties = await _propertyService.getPropertiesByIds(ids);
      final foundIds = properties.map((p) => p.id).toSet();
      final missingIds = ids.where((id) => !foundIds.contains(id)).toList();

      if (missingIds.isNotEmpty) {
        final rentals = await _rentalService.getRentalsByIds(missingIds);
        final mappedRentals =
            rentals.map((r) => _mapRentalToProperty(r)).toList();
        properties.addAll(mappedRentals);
      }

      final byId = {for (final p in properties) p.id: p};
      _recentlyViewedProperties = ids
          .where((id) => byId.containsKey(id))
          .map((id) => byId[id]!)
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void addLocalRecentlyViewed(Property property, {int limit = 50}) {
    _recentlyViewedProperties.removeWhere((p) => p.id == property.id);
    _recentlyViewedProperties.insert(0, property);
    if (_recentlyViewedProperties.length > limit) {
      _recentlyViewedProperties.removeRange(
          limit, _recentlyViewedProperties.length);
    }
    notifyListeners();
  }
}
