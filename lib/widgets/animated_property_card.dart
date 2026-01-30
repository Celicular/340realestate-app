import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../providers/rental_provider.dart';
import '../providers/comparison_provider.dart';
import 'dart:convert';
import '../models/property.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';

class AnimatedPropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback? onTap;
  final int index;
  final String? heroTagPrefix;
  final String? priceLabelOverride;

  const AnimatedPropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.index = 0,
    this.heroTagPrefix,
    this.priceLabelOverride,
  });

  @override
  State<AnimatedPropertyCard> createState() => _AnimatedPropertyCardState();
}

class _AnimatedPropertyCardState extends State<AnimatedPropertyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAnimations.staggeredAnimation(
      index: widget.index,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) async {
          setState(() => _isPressed = false);
          _controller.reverse();
          try {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            auth.addRecentlyViewed(widget.property.id);
          } catch (_) {}
          try {
            final prop = Provider.of<PropertyProvider>(context, listen: false);
            prop.addLocalRecentlyViewed(widget.property);
          } catch (_) {}
          widget.onTap?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadowColor,
                  blurRadius: _isPressed ? 5 : 10,
                  offset: Offset(0, _isPressed ? 2 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Property Image with Hero animation
                Stack(
                  children: [
                    Hero(
                      tag: widget.heroTagPrefix != null
                          ? '${widget.heroTagPrefix}_property_${widget.property.id}_${widget.index}'
                          : 'property_${widget.property.id}_${widget.index}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.borderRadiusMedium),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildImage(),
                        ),
                      ),
                    ),
                    // Compare Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<ComparisonProvider>(
                        builder: (context, comparisonProvider, child) {
                          final isSelected = comparisonProvider.isSelected(widget.property.id);
                          final canAdd = comparisonProvider.canAddMore();
                          return GestureDetector(
                            onTap: () {
                              if (!isSelected && !canAdd) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Maximum 2 properties can be compared'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              comparisonProvider.toggleProperty(widget.property);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSelected
                                        ? 'Removed from comparison'
                                        : 'Added to comparison (${comparisonProvider.selectedCount}/2)',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isSelected ? Icons.check : Icons.compare_arrows,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Image count badge (only show if multiple images)
                    if (widget.property.images.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.property.images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                // Property Details
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.property.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              widget.property.location,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Builder(builder: (context) {
                        final isRental =
                            widget.property.type == PropertyType.rental;
                        String priceText = widget.priceLabelOverride ??
                            widget.property.formattedPrice;
                        if (isRental && widget.priceLabelOverride == null) {
                          try {
                            final mode = Provider.of<RentalProvider>(context,
                                    listen: false)
                                .priceMode;
                            priceText =
                                '\$${widget.property.price.toStringAsFixed(0)} / ${mode == 'night' ? 'night' : 'week'}';
                          } catch (_) {}
                        }
                        // Generate a consistent "viewing" count based on property ID
                        final viewingCount = (widget.property.id.hashCode.abs() % 15) + 2;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              priceText,
                              style:
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$viewingCount people viewing',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = widget.property.imageUrl;
    const placeholder = AppTheme.placeholderImageUrl;
    if (url.isEmpty) {
      return Image.network(
        placeholder,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.home,
              size: 40,
              color: Theme.of(context).textTheme.bodySmall?.color,
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
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                placeholder,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.textTertiary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.home,
                      size: 40,
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
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.home,
                  size: 40,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              );
            },
          );
        }
      }
    }
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          placeholder,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Icon(
                Icons.home,
                size: 40,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            );
          },
        );
      },
    );
  }
}
