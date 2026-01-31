import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_button.dart';
import '../widgets/compare_button.dart';
import '../widgets/animated_property_card.dart';
import '../models/property.dart';
import '../utils/animations.dart';
import '../providers/rental_provider.dart';
import '../providers/property_provider.dart';
import '../models/rental_property.dart';
import 'property_details_page.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class RentalsPage extends StatefulWidget {
  const RentalsPage({super.key});

  @override
  State<RentalsPage> createState() => _RentalsPageState();
}

class _RentalsPageState extends State<RentalsPage> {
  Property _mapRental(RentalProperty r, String priceMode) {
    debugPrint('🏠 RENTALS_PAGE [${r.name}]: imageLinks has ${r.imageLinks.length} images');
    return Property(
      id: r.id,
      name: r.name,
      location: r.address,
      price: priceMode == 'night' ? r.pricePerNight : r.pricePerNight * 7,
      images: r.imageLinks,
      description: r.description,
      bedrooms: r.bedrooms,
      bathrooms: r.bathrooms,
      sqft: r.sqft,
      amenities: r.amenities,
      isFeatured: false,
      type: PropertyType.rental,
    );
  }

  @override
  void initState() {
    super.initState();
    // Ensure properties are fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RentalProvider>(context, listen: false);
      provider.clearFilters();
      if (provider.rentals.isEmpty) {
        provider.fetchRentals();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<RentalProvider, PropertyProvider>(
          builder: (context, rentalProvider, propertyProvider, child) {
            final rentalsPrimary = rentalProvider.filteredRentals.isNotEmpty
                ? rentalProvider.filteredRentals
                : rentalProvider.rentals;
            final priceMode = rentalProvider.priceMode;
            final propertiesPrimary =
                rentalsPrimary.map((r) => _mapRental(r, priceMode)).toList();
            final rentalsFallback =
                propertyProvider.filteredProperties.isNotEmpty
                    ? propertyProvider.filteredProperties
                        .where((p) => p.type == PropertyType.rental)
                        .toList()
                    : propertyProvider.properties
                        .where((p) => p.type == PropertyType.rental)
                        .toList();
            final propertiesToShow = propertiesPrimary.isNotEmpty
                ? propertiesPrimary
                : rentalsFallback;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    'Rentals',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                // Search and Filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLarge,
                      vertical: AppTheme.spacingMedium,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchBarWidget(
                            hintText: 'Search rentals...',
                            onChanged: (query) {
                              rentalProvider.searchRentals(query);
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        FilterButton(
                          onTap: () {
                            _showFilterDialog(context);
                          },
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        const CompareButton(),
                      ],
                    ),
                  ),
                ),
                // Property Grid
                if ((rentalProvider.isLoading || propertyProvider.isLoading) &&
                    propertiesToShow.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (propertiesToShow.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.home_outlined,
                            size: 60,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rentals found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppTheme.spacingMedium,
                        mainAxisSpacing: AppTheme.spacingMedium,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final property = propertiesToShow[index];

                          return AnimatedPropertyCard(
                            property: property,
                            index: index,
                            heroTagPrefix: 'rental_list',
                            onTap: () {
                              Navigator.push(
                                context,
                                AppAnimations.scaleRoute(
                                  PropertyDetailsPage(
                                    property: property,
                                    heroIndex: index,
                                    heroTagPrefix: 'rental_list',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: propertiesToShow.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacingXLarge),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final rentalProvider = Provider.of<RentalProvider>(context, listen: false);
    final minController = TextEditingController();
    final maxController = TextEditingController();
    final bedsController = TextEditingController();
    final locationController = TextEditingController();
    String sort = 'none';
    String priceMode = rentalProvider.priceMode; // 'week' or 'night'
    String propertyType = 'any';
    bool useNearbyLocation = false;
    double maxDistance = 10.0; // Default 10 km

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Filters & Sort',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nearby Location Toggle
                SwitchListTile(
                  title: const Text('Nearby My Location'),
                  subtitle: Text(
                    useNearbyLocation
                        ? 'Filter by distance from you'
                        : 'Search all locations',
                  ),
                  value: useNearbyLocation,
                  onChanged: (value) {
                    setState(() {
                      useNearbyLocation = value;
                      if (value) {
                        // Clear manual location input when using nearby
                        locationController.clear();
                      }
                    });
                  },
                ),
                if (useNearbyLocation) ...[
                  const SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    'Max Distance: ${maxDistance.toStringAsFixed(0)} km',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: maxDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${maxDistance.toStringAsFixed(0)} km',
                    onChanged: (value) {
                      setState(() {
                        maxDistance = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                ],
                if (!useNearbyLocation)
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'e.g., San Francisco',
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingMedium),
                DropdownButtonFormField<String>(
                  value: priceMode,
                  decoration: const InputDecoration(
                    labelText: 'Price Basis',
                    prefixIcon: Icon(Icons.swap_vert),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'week', child: Text('Per week')),
                    DropdownMenuItem(value: 'night', child: Text('Per night')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      priceMode = v ?? 'week';
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        'Min Price (${priceMode == 'week' ? 'per week' : 'per night'})',
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        'Max Price (${priceMode == 'week' ? 'per week' : 'per night'})',
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                DropdownButtonFormField<String>(
                  value: propertyType,
                  decoration: const InputDecoration(
                    labelText: 'Property Type',
                    prefixIcon: Icon(Icons.home_work_outlined),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'any', child: Text('Any')),
                    DropdownMenuItem(value: 'villa', child: Text('Villa')),
                    DropdownMenuItem(value: 'house', child: Text('House')),
                    DropdownMenuItem(value: 'cottage', child: Text('Cottage')),
                    DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                    DropdownMenuItem(value: 'condo', child: Text('Condo')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      propertyType = v ?? 'any';
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextField(
                  controller: bedsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Bedrooms',
                    prefixIcon: Icon(Icons.bed),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                DropdownButtonFormField<String>(
                  value: sort,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    prefixIcon: Icon(Icons.sort),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 'none', child: Text('None')),
                    const DropdownMenuItem(
                        value: 'price_asc', child: Text('Price: Low to High')),
                    const DropdownMenuItem(
                        value: 'price_desc', child: Text('Price: High to Low')),
                    const DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    const DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    if (useNearbyLocation)
                      const DropdownMenuItem(
                          value: 'distance', child: Text('Distance: Nearest First')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      sort = v ?? 'none';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                double? min = double.tryParse(minController.text);
                double? max = double.tryParse(maxController.text);
                int? beds = int.tryParse(bedsController.text);
                final loc = locationController.text.trim();

                // Get user location if nearby is enabled
                Position? userLocation;
                if (useNearbyLocation || sort == 'distance') {
                  final hasPermission =
                      await LocationService.requestLocationPermission();
                  if (hasPermission) {
                    userLocation = await LocationService.getCurrentLocation();
                    if (userLocation == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Unable to get your location. Please enable location services.'),
                        ),
                      );
                      return;
                    }
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location permission required for nearby filtering.'),
                      ),
                    );
                    return;
                  }
                }

                rentalProvider.filterRentals(
                  minPrice: min,
                  maxPrice: max,
                  minBedrooms: beds,
                  sortOption: sort,
                  priceMode: priceMode,
                  location: useNearbyLocation ? null : (loc.isEmpty ? null : loc),
                  propertyType:
                      propertyType == 'any' ? null : propertyType.toLowerCase(),
                  userLocation: userLocation,
                  maxDistance: useNearbyLocation ? maxDistance : null,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
