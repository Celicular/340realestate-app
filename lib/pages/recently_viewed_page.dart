import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../widgets/animated_property_card.dart';
import '../theme/app_theme.dart';
import '../utils/animations.dart';
import 'property_details_page.dart';

class RecentlyViewedPage extends StatefulWidget {
  const RecentlyViewedPage({super.key});

  @override
  State<RecentlyViewedPage> createState() => _RecentlyViewedPageState();
}

class _RecentlyViewedPageState extends State<RecentlyViewedPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final prop = Provider.of<PropertyProvider>(context, listen: false);
    final ids = auth.userProfile?.recentlyViewed ?? [];
    if ((auth.isAuthenticated) && ids.isNotEmpty) {
      await prop.fetchRecentlyViewed(ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prop = Provider.of<PropertyProvider>(context);
    final items = prop.recentlyViewedPropertiesList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Viewed'),
      ),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history,
                        size: 80, color: AppTheme.textTertiary),
                    const SizedBox(height: 12),
                    Text('No recently viewed properties',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.spacingLarge),
                itemBuilder: (context, index) {
                  final p = items[index];
                  return AnimatedPropertyCard(
                    property: p,
                    heroTagPrefix: 'recently_viewed',
                    index: index,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppAnimations.scaleRoute(
                          PropertyDetailsPage(
                            property: p,
                            heroIndex: index,
                            heroTagPrefix: 'recently_viewed',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
