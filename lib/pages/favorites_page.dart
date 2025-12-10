import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_property_card.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../utils/animations.dart';
import 'property_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    final favoriteIds = authProvider.userProfile?.favoriteProperties ?? [];
    propertyProvider.fetchFavorites(favoriteIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<AuthProvider, PropertyProvider>(
          builder: (context, authProvider, propertyProvider, child) {
            // Check if user has favorites
            final favoriteIds = authProvider.userProfile?.favoriteProperties ?? [];
            
            if (favoriteIds.isEmpty) {
              return _buildEmptyState(context);
            }

            if (propertyProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final favorites = propertyProvider.favoritePropertiesList;

            if (favorites.isEmpty && !propertyProvider.isLoading) {
              // This might happen if IDs exist but properties don't (deleted)
              return _buildEmptyState(context);
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Favorites',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppTheme.spacingMedium,
                      mainAxisSpacing: AppTheme.spacingMedium,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final property = favorites[index];
                        return AnimatedPropertyCard(
                          property: property,
                          index: index,
                          heroTagPrefix: 'fav',
                          onTap: () {
                            Navigator.push(
                              context,
                              AppAnimations.scaleRoute(
                                PropertyDetailsPage(
                                  property: property,
                                  heroIndex: index,
                                  heroTagPrefix: 'fav',
                                ),
                              ),
                            ).then((_) {
                              // Refresh favorites when returning (in case unfavorited)
                              _loadFavorites();
                            });
                          },
                        );
                      },
                      childCount: favorites.length,
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

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Favorites',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                Text(
                  'No favorites yet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Start saving your favorite properties',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
