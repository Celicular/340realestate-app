import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../utils/animations.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../providers/rental_provider.dart';
import '../widgets/login_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rental_service.dart';
import '../services/property_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/booking_service.dart';

class PropertyDetailsPage extends StatefulWidget {
  final Property property;
  final int? heroIndex;
  final String? heroTagPrefix;

  const PropertyDetailsPage({
    super.key,
    required this.property,
    this.heroIndex,
    this.heroTagPrefix,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  bool _descExpanded = false;
  bool _amenitiesExpanded = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.addRecentlyViewed(widget.property.id);
      } catch (_) {}
      try {
        final prop = Provider.of<PropertyProvider>(context, listen: false);
        prop.addLocalRecentlyViewed(widget.property);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with AppBar
            _buildHeroImage(context),
            // Content
            AppAnimations.fadeIn(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.property.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.property.location,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    Builder(builder: (context) {
                      final isRental =
                          widget.property.type == PropertyType.rental;
                      String priceText = widget.property.formattedPrice;
                      if (isRental) {
                        String mode = 'week';
                        try {
                          mode = Provider.of<RentalProvider>(context,
                                  listen: false)
                              .priceMode;
                        } catch (_) {}
                        priceText =
                            '\$${widget.property.price.toStringAsFixed(0)} / ${mode == 'night' ? 'night' : 'week'}';
                      }
                      return Text(
                        priceText,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontSize: 32,
                                ),
                      );
                    }),
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Property Details
                    _buildPropertyDetails(),
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Description
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    if (widget.property.type == PropertyType.rental) ...[
                      Text(
                        widget.property.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: _descExpanded ? null : 5,
                        overflow: _descExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _descExpanded = !_descExpanded),
                          child:
                              Text(_descExpanded ? 'Read less' : 'Read more'),
                        ),
                      ),
                    ] else ...[
                      Text(
                        widget.property.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Amenities
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    _buildAmenitiesGrid(),
                    if (widget.property.type == PropertyType.rental &&
                        widget.property.amenities.length > 6) ...[
                      const SizedBox(height: AppTheme.spacingSmall),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(
                              () => _amenitiesExpanded = !_amenitiesExpanded),
                          child: Text(
                              _amenitiesExpanded ? 'Read less' : 'Read more'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Location Map
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    Builder(
                      builder: (context) {
                        final hasCoordinates = widget.property.latitude != null && 
                            widget.property.longitude != null;
                        final mapCenter = hasCoordinates
                            ? LatLng(widget.property.latitude!, widget.property.longitude!)
                            : const LatLng(18.33, -64.74);
                        final mapZoom = hasCoordinates ? 15.0 : 11.0;
                        
                        return GestureDetector(
                          onTap: () => _showFullScreenMap(
                            context, 
                            mapCenter, 
                            mapZoom, 
                            hasCoordinates,
                          ),
                          child: Stack(
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: mapCenter,
                                    initialZoom: mapZoom,
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.none,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.company.RealEstate',
                                      maxZoom: 19,
                                    ),
                                    if (hasCoordinates)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: mapCenter,
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.location_pin,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Add extra padding to account for bottom action bar
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (widget.property.type == PropertyType.rental) {
                      _showBookingDialog(context);
                    } else {
                      _showScheduleDialog(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: Text(
                    widget.property.type == PropertyType.rental
                        ? 'Book Now'
                        : 'Schedule Viewing',
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showContactDialog(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Contact Agent'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    final imageCount = widget.property.images.length;

    return Stack(
      children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: imageCount > 1
              ? PageView.builder(
                  itemCount: imageCount,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Hero(
                      tag: index == 0
                          ? (widget.heroTagPrefix != null && widget.heroIndex != null
                              ? '${widget.heroTagPrefix}_property_${widget.property.id}_${widget.heroIndex}'
                              : widget.heroIndex != null
                                  ? 'property_${widget.property.id}_${widget.heroIndex}'
                                  : 'property_${widget.property.id}')
                          : 'property_${widget.property.id}_image_$index',
                      child: _buildImage(index),
                    );
                  },
                )
              : Hero(
                  tag: widget.heroTagPrefix != null && widget.heroIndex != null
                      ? '${widget.heroTagPrefix}_property_${widget.property.id}_${widget.heroIndex}'
                      : widget.heroIndex != null
                          ? 'property_${widget.property.id}_${widget.heroIndex}'
                          : 'property_${widget.property.id}',
                  child: _buildImage(0),
                ),
        ),
        // Image counter overlay
        if (imageCount > 1)
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1} / $imageCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        // Page indicator dots
        if (imageCount > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _buildPageIndicator(imageCount),
          ),
        // AppBar Overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Row(
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final isFavorite = authProvider
                                  .userProfile?.favoriteProperties
                                  .contains(widget.property.id) ??
                              false;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                              onPressed: () {
                                if (!authProvider.isAuthenticated) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const LoginDialog(),
                                  );
                                  return;
                                }
                                authProvider.toggleFavorite(widget.property.id);
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            final p = widget.property;
                            final msg =
                                '${p.name} — ${p.location}\n${p.formattedPrice}\n';
                            Share.share(msg.trim());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(int index) {
    final images = widget.property.images;
    final url = images.isNotEmpty && index < images.length
        ? images[index]
        : '';
    const placeholder = AppTheme.placeholderImageUrl;

    if (url.isEmpty) {
      return Image.network(
        placeholder,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppTheme.textTertiary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.home,
              size: 80,
              color: AppTheme.textTertiary,
            ),
          );
        },
      );
    }
    if (url.startsWith('data:image')) {
      const marker = 'base64,';
      final idx = url.indexOf(marker);
      if (idx != -1) {
        final b64 = url.substring(idx + marker.length);
        try {
          final bytes = base64Decode(b64);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                placeholder,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.textTertiary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.home,
                      size: 80,
                      color: AppTheme.textTertiary,
                    ),
                  );
                },
              );
            },
          );
        } catch (_) {
          return Image.network(
            placeholder,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.textTertiary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.home,
                  size: 80,
                  color: AppTheme.textTertiary,
                ),
              );
            },
          );
        }
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          placeholder,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppTheme.textTertiary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.home,
                size: 80,
                color: AppTheme.textTertiary,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPageIndicator(int imageCount) {
    // Only show dots for 7 or fewer images
    // For many images, the counter at top-right is sufficient
    const maxDots = 7;

    if (imageCount > maxDots) {
      // Don't show dots for many images - counter at top is enough
      return const SizedBox.shrink();
    }

    // Show dots for 7 or fewer images
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          imageCount,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentImageIndex == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetails() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.textTertiary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailItem(
            Icons.bed,
            '${widget.property.bedrooms}',
            'Bedrooms',
          ),
          _buildDetailItem(
            Icons.bathtub,
            '${widget.property.bathrooms}',
            'Bathrooms',
          ),
          _buildDetailItem(
            Icons.square_foot,
            '${widget.property.sqft}',
            'Sqft',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    final list = widget.property.amenities;
    const limit = 6;
    final display = (widget.property.type == PropertyType.rental &&
            !_amenitiesExpanded &&
            list.length > limit)
        ? list.take(limit).toList()
        : list;
    return Wrap(
      spacing: AppTheme.spacingMedium,
      runSpacing: AppTheme.spacingMedium,
      children: display.map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLarge,
            vertical: AppTheme.spacingMedium,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            amenity,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      }).toList(),
    );
  }





  void _showFullScreenMap(
    BuildContext context,
    LatLng center,
    double zoom,
    bool hasCoordinates,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              widget.property.name,
              style: const TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (hasCoordinates)
                IconButton(
                  icon: const Icon(Icons.directions, color: Colors.white),
                  onPressed: () async {
                    final lat = widget.property.latitude!;
                    final lng = widget.property.longitude!;
                    final url = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  tooltip: 'Get Directions',
                ),
            ],
          ),
          body: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.company.RealEstate',
                maxZoom: 19,
              ),
              if (hasCoordinates)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Agent',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interested in ${widget.property.name}?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Contact our agent to schedule a viewing or get more information.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Agent will contact you soon!'),
                ),
              );
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final profile = auth.userProfile;
    final formKey = GlobalKey<FormState>();
    String name = (profile?.name.isNotEmpty ?? false)
        ? (profile?.name ?? '')
        : ((profile?.displayName.isNotEmpty ?? false)
            ? (profile?.displayName ?? '')
            : (user?.displayName ?? ''));
    String email = user?.email ?? profile?.email ?? '';
    String phone = profile?.phoneNumber ?? user?.phoneNumber ?? '';
    DateTime? checkIn;
    DateTime? checkOut;
    int guests = 1;
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final messageController = TextEditingController();
    String two(int n) => n.toString().padLeft(2, '0');
    String fmt(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Row(
            children: [
              const Icon(Icons.event_available),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Book Now',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          scrollable: true,
          content: StatefulBuilder(
            builder: (context, setState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline),
                                const SizedBox(width: 8),
                                Text(
                                  'Guest Information',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name *',
                                hintText: 'Enter your full name',
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email Address *',
                                hintText: 'your.email@example.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              validator: (v) => (v == null ||
                                      v.trim().isEmpty ||
                                      !v.contains('@'))
                                  ? 'Valid email required'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number *',
                                hintText: '+1 (555) 123-4567',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  'Booking Details',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Check-in Date *',
                                hintText: checkIn == null
                                    ? fmt(DateTime.now())
                                    : fmt(checkIn!),
                                prefixIcon:
                                    const Icon(Icons.calendar_today_outlined),
                                suffixIcon:
                                    const Icon(Icons.calendar_month_outlined),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => checkIn = picked);
                                }
                              },
                              validator: (_) =>
                                  checkIn == null ? 'Required' : null,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                            TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Check-out Date *',
                                hintText: checkOut == null
                                    ? fmt(DateTime.now())
                                    : fmt(checkOut!),
                                prefixIcon:
                                    const Icon(Icons.calendar_today_outlined),
                                suffixIcon:
                                    const Icon(Icons.calendar_month_outlined),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              onTap: () async {
                                final base = checkIn ?? DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      base.add(const Duration(days: 1)),
                                  firstDate: base,
                                  lastDate: base.add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => checkOut = picked);
                                }
                              },
                              validator: (_) {
                                if (checkOut == null) return 'Required';
                                if (checkIn != null &&
                                    checkOut!.isBefore(checkIn!)) {
                                  return 'Must be after check-in';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                            DropdownButtonFormField<int>(
                              initialValue: guests,
                              decoration: InputDecoration(
                                labelText: 'Number of Guests *',
                                prefixIcon: const Icon(Icons.people_outline),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                              ),
                              items: List.generate(10, (i) => i + 1)
                                  .map((n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                            n == 1 ? '1 Guest' : '$n Guests'),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => guests = v);
                              },
                              validator: (v) =>
                                  (v == null || v <= 0) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),
                      TextFormField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Message to Host',
                          prefixIcon: const Icon(Icons.message_outlined),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusMedium),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            StatefulBuilder(
              builder: (context, setButtonState) {
                bool isSubmitting = false;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                  ),
                  onPressed: isSubmitting ? null : () async {
                    if (formKey.currentState?.validate() ?? false) {
                      setButtonState(() => isSubmitting = true);
                      
                      try {
                        final bookingService = BookingService();
                        await bookingService.createBookingRequest(
                          propertyId: widget.property.id,
                          checkIn: checkIn!,
                          checkOut: checkOut!,
                          guests: guests,
                          guestName: nameController.text.trim(),
                          guestEmail: emailController.text.trim(),
                          guestPhone: phoneController.text.trim(),
                          message: messageController.text.trim(),
                          baseRate: widget.property.price,
                          propertyName: widget.property.name,
                          propertyAddress: widget.property.location,
                          propertyType: widget.property.type.name,
                        );
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking request submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setButtonState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Booking'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showScheduleDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    TimeOfDay? selectedTime;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    String two(int n) => n.toString().padLeft(2, '0');
    String fmt(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
    String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Row(
            children: [
              const Icon(Icons.event_note),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Schedule a Viewing',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          scrollable: true,
          content: StatefulBuilder(
            builder: (context, setState) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Details',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(s);
                                return ok ? null : 'Enter a valid email';
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            TextFormField(
                              controller: mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Mobile',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                            Text('Select Date',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: fmt(selectedDate),
                                hintText: fmt(selectedDate),
                                prefixIcon:
                                    const Icon(Icons.calendar_today_outlined),
                                suffixIcon:
                                    const Icon(Icons.calendar_month_outlined),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 12),
                              ),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 60)),
                                );
                                if (picked != null) {
                                  setState(() => selectedDate = picked);
                                }
                              },
                              validator: (_) => null,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                            Text('Select Time',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<TimeOfDay>(
                              initialValue: selectedTime,
                              hint: const Text('Choose a time'),
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.access_time),
                                filled: true,
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusMedium),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              items: List.generate(10, (i) => 9 + i)
                                  .map((h) => TimeOfDay(hour: h, minute: 0))
                                  .map((t) => DropdownMenuItem<TimeOfDay>(
                                        value: t,
                                        child: Text(t.format(context)),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedTime = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (selectedTime != null)
                                    ? () async {
                                        if (formKey.currentState?.validate() ??
                                            false) {
                                          FocusScope.of(context).unfocus();
                                          final service = PropertyService();
                                          final propertyId = widget.property.id;
                                          final selectedDateStr =
                                              ymd(selectedDate);
                                          final selectedTimeStr =
                                              selectedTime!.format(context);
                                          try {
                                            await service.scheduleViewing(
                                              propertyId: propertyId,
                                              fullName:
                                                  nameController.text.trim(),
                                              email:
                                                  emailController.text.trim(),
                                              mobile:
                                                  mobileController.text.trim(),
                                              selectedDate: selectedDateStr,
                                              selectedTime: selectedTimeStr,
                                            );
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              final when =
                                                  '${fmt(selectedDate)} at ${selectedTimeStr}';
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Viewing scheduled for $when')),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(e
                                                          .toString()
                                                          .contains(
                                                              'already booked')
                                                      ? 'This time slot is already booked'
                                                      : 'Failed to schedule: $e'),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    : null,
                                child: const Text('Schedule Viewing'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
