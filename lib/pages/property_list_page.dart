import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_button.dart';
import '../widgets/compare_button.dart';
import '../widgets/animated_property_card.dart';
import '../models/property.dart';
import '../utils/animations.dart';
import '../providers/property_provider.dart';
import 'property_details_page.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  @override
  void initState() {
    super.initState();
    // Ensure properties are fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PropertyProvider>(context, listen: false);
      if (provider.properties.isEmpty) {
        provider.fetchProperties();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PropertyProvider>(
          builder: (context, propertyProvider, child) {
            final properties = propertyProvider.filteredProperties.isNotEmpty 
                ? propertyProvider.filteredProperties 
                : propertyProvider.properties.where((p) => p.type != PropertyType.rental).toList();

            return CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    'Properties for Sale',
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
                            hintText: 'Search properties...',
                            onChanged: (query) {
                              propertyProvider.searchProperties(query);
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
                if (propertyProvider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (properties.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No properties found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )
                else
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
                          final property = properties[index];
                          return AnimatedPropertyCard(
                            property: property,
                            index: index,
                            heroTagPrefix: 'list',
                            onTap: () {
                              Navigator.push(
                                context,
                                AppAnimations.scaleRoute(
                                  PropertyDetailsPage(
                                    property: property,
                                    heroIndex: index,
                                    heroTagPrefix: 'list',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: properties.length,
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
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    final minController = TextEditingController();
    final maxController = TextEditingController();
    String sort = 'none';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filters & Sort',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
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
                initialValue: sort,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  prefixIcon: Icon(Icons.sort),
                ),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => sort = v ?? 'none',
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
            onPressed: () {
              double? min = double.tryParse(minController.text);
              double? max = double.tryParse(maxController.text);
              provider.filterProperties(
                minPrice: min,
                maxPrice: max,
                sortOption: sort,
              );
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
