import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_button.dart';
import '../widgets/animated_property_card.dart';
import '../widgets/comparison_fab.dart';
import '../models/property.dart';
import '../utils/animations.dart';
import '../providers/property_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/comparison_provider.dart';
import 'recently_viewed_page.dart';
import 'property_list_page.dart';
import 'property_details_page.dart';
import 'property_comparison_page.dart';
import 'rentals_page.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRentMode = false; // Toggle between Buy (false) and Rent (true)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final props = Provider.of<PropertyProvider>(context, listen: false);
      props.fetchProperties();
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final ids = auth.userProfile?.recentlyViewed ?? [];
        if (auth.isAuthenticated && ids.isNotEmpty) {
          props.fetchRecentlyViewed(ids);
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ComparisonFAB(),
      body: SafeArea(
        child: Consumer<PropertyProvider>(
          builder: (context, propertyProvider, child) {
            if (propertyProvider.isLoading &&
                propertyProvider.properties.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final allProperties = propertyProvider.filteredProperties.isNotEmpty
                ? propertyProvider.filteredProperties
                : propertyProvider.properties;

            // Filter properties based on mode
            final displayProperties = allProperties.where((p) {
              if (_isRentMode) {
                return p.type == PropertyType.rental;
              } else {
                return p.type != PropertyType.rental;
              }
            }).toList();

            final featuredProperties =
                displayProperties.where((p) => p.isFeatured).toList();
            final recommendedProperties =
                displayProperties.take(5).toList(); // Simple logic for now

            return CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    '340 Real Estate',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  centerTitle: false,
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
                            hintText: _isRentMode
                                ? 'Search rentals...'
                                : 'Search properties...',
                            onChanged: (q) {
                              Provider.of<PropertyProvider>(context,
                                      listen: false)
                                  .searchProperties(q);
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        FilterButton(
                          onTap: () => _showFilterDialog(context),
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        // Compare Button
                        Consumer<ComparisonProvider>(
                          builder: (context, comparisonProvider, child) {
                            final count = comparisonProvider.selectedProperties.length;
                            return GestureDetector(
                              onTap: () {
                                if (count >= 2) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PropertyComparisonPage(
                                        properties: comparisonProvider.selectedProperties,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        count == 0
                                            ? 'Add properties to compare from property cards'
                                            : 'Add at least one more property to compare',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                                decoration: BoxDecoration(
                                  color: count >= 2
                                      ? AppTheme.primaryColor
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: count >= 2
                                        ? AppTheme.primaryColor
                                        : AppTheme.textTertiary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.compare_arrows,
                                      color: count >= 2
                                          ? Colors.white
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : AppTheme.textPrimary),
                                      size: 20,
                                    ),
                                    if (count > 0) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: count >= 2
                                              ? Colors.white
                                              : AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            color: count >= 2
                                                ? AppTheme.primaryColor
                                                : Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Buy/Rent Toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isRentMode = false);
                                Provider.of<PropertyProvider>(context,
                                        listen: false)
                                    .filterProperties(type: 'sale');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isRentMode
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusLarge),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Buy',
                                  style: TextStyle(
                                    color: !_isRentMode
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : (Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color ??
                                            AppTheme.textSecondary),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isRentMode = true);
                                Provider.of<PropertyProvider>(context,
                                        listen: false)
                                    .filterProperties(type: 'rental');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isRentMode
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusLarge),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Rent',
                                  style: TextStyle(
                                    color: _isRentMode
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : (Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color ??
                                            AppTheme.textSecondary),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: AppTheme.spacingLarge)),

                // Recently Viewed Section
                if (propertyProvider
                    .recentlyViewedPropertiesList.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Recently Viewed', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecentlyViewedPage(),
                      ),
                    );
                  }),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLarge),
                        itemCount: propertyProvider
                            .recentlyViewedPropertiesList.length,
                        itemBuilder: (context, index) {
                          final property = propertyProvider
                              .recentlyViewedPropertiesList[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(
                                right: AppTheme.spacingMedium),
                            child: AnimatedPropertyCard(
                              property: property,
                              index: index,
                              heroTagPrefix:
                                  'recent_${_isRentMode ? "rent" : "buy"}',
                              onTap: () => _navigateToDetails(
                                  context, property, index, 'recent'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppTheme.spacingLarge)),
                ],

                // Featured Properties Section
                if (featuredProperties.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Featured Properties', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _isRentMode
                            ? const RentalsPage()
                            : const PropertyListPage(),
                      ),
                    );
                  }),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLarge),
                        itemCount: featuredProperties.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(
                                right: AppTheme.spacingMedium),
                            child: AnimatedPropertyCard(
                              property: featuredProperties[index],
                              index: index,
                              heroTagPrefix:
                                  'featured_${_isRentMode ? "rent" : "buy"}',
                              onTap: () => _navigateToDetails(context,
                                  featuredProperties[index], index, 'featured'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppTheme.spacingLarge)),
                ],

                // Recommended Section
                if (recommendedProperties.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Recommended for You', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _isRentMode
                            ? const RentalsPage()
                            : const PropertyListPage(),
                      ),
                    );
                  }),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLarge),
                        itemCount: recommendedProperties.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(
                                right: AppTheme.spacingMedium),
                            child: AnimatedPropertyCard(
                              property: recommendedProperties[index],
                              index: index,
                              heroTagPrefix:
                                  'recommended_${_isRentMode ? "rent" : "buy"}',
                              onTap: () => _navigateToDetails(
                                  context,
                                  recommendedProperties[index],
                                  index,
                                  'recommended'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppTheme.spacingLarge)),
                ],

                // Static Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusLarge),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusLarge),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'List Your Property With Us',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reach thousands of potential buyers and renters',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppTheme.spacingLarge)),

                // Get In Touch Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge),
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusLarge),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Get in Touch',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        const Text(
                          'Have questions? We are here to help you find your dream home.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSocialButton(
                                Icons.email_outlined, 'Email', _openEmail),
                            _buildSocialButton(
                                Icons.phone_outlined, 'Call', _openDialer),
                            _buildSocialButton(Icons.chat_bubble_outline,
                                'Chat', _openWhatsApp),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppTheme.spacingXLarge)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEmail() async {
    final uri = Uri(scheme: 'mailto', path: '340realestateco@gmail.com');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        final web = Uri.parse(
            'https://mail.google.com/mail/?view=cm&fs=1&to=340realestateco@gmail.com');
        if (await canLaunchUrl(web)) {
          await launchUrl(web, mode: LaunchMode.externalApplication);
        } else {
          throw 'No mail app found';
        }
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open mail app')),
      );
    }
  }

  Future<void> _openDialer() async {
    final uri = Uri(scheme: 'tel', path: '+13406436068');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        throw 'No dialer app found';
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open dialer')),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final waUri = Uri.parse('whatsapp://send?phone=13406436068');
    final webUri = Uri.parse('https://wa.me/13406436068');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.platformDefault);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } else {
        throw 'WhatsApp not available';
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp')),
      );
    }
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onSeeAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.cardShadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(
      BuildContext context, Property property, int index, String prefix) {
    Navigator.push(
      context,
      AppAnimations.scaleRoute(
        PropertyDetailsPage(
          property: property,
          heroIndex: index,
          heroTagPrefix: '${prefix}_${_isRentMode ? "rent" : "buy"}',
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    final minController = TextEditingController();
    final maxController = TextEditingController();
    String sort = 'none';
    bool useLocation = false;
    double maxDistance = 10.0; // Default 10 km

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                DropdownButtonFormField<String>(
                  value: sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    prefixIcon: Icon(Icons.sort),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(
                        value: 'price_asc', child: Text('Price: Low to High')),
                    DropdownMenuItem(
                        value: 'price_desc', child: Text('Price: High to Low')),
                    DropdownMenuItem(
                        value: 'distance', child: Text('Distance: Nearest First')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      sort = v ?? 'none';
                      if (sort == 'distance') {
                        useLocation = true;
                      }
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                SwitchListTile(
                  title: const Text('Nearby Properties Only'),
                  subtitle: Text(
                      useLocation ? 'Filter by distance' : 'Show all properties'),
                  value: useLocation,
                  onChanged: (value) {
                    setState(() {
                      useLocation = value;
                    });
                  },
                ),
                if (useLocation) ...[
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
                ],
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
                final min = double.tryParse(minController.text);
                final max = double.tryParse(maxController.text);

                // Get user location if needed
                Position? userLocation;
                if (useLocation || sort == 'distance') {
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
                        content: Text(
                            'Location permission required for this filter.'),
                      ),
                    );
                    return;
                  }
                }

                provider.filterProperties(
                  type: _isRentMode ? 'rental' : 'sale',
                  minPrice: min,
                  maxPrice: max,
                  sortOption: sort,
                  userLocation: userLocation,
                  maxDistance: useLocation ? maxDistance : null,
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

