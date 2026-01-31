import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_button.dart';
import '../widgets/compare_button.dart';
import '../widgets/animated_property_card.dart';
import '../models/property.dart';
import '../models/residential_portfolio.dart';
import '../models/land_portfolio.dart';
import '../utils/animations.dart';
import 'property_details_page.dart';

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> {

  bool _loadingResidential = true;
  bool _loadingLand = true;
  bool _loadingLandMore = false;
  String _resSearch = '';
  String _landSearch = '';
  String? _resError;

  List<ResidentialPortfolio> _residential = [];
  List<LandPortfolio> _land = [];
  final int _landPageSize = 10;
  DocumentSnapshot? _landLastDoc;
  bool _landHasMore = true;
  final ScrollController _landScrollController = ScrollController();

  // Local filters & sort
  double? _resMinPrice;
  double? _resMaxPrice;
  int? _resMinBedrooms;
  String _resSort = 'none'; // none, price_asc, price_desc

  double? _landMinPrice;
  double? _landMaxPrice;
  String _landSort = 'none'; // none, price_asc, price_desc, newest, oldest

  @override
  void initState() {
    super.initState();
    _fetchResidential();
    _fetchLandInitial();
    _landScrollController.addListener(_onLandScroll);
  }

  Future<void> _fetchResidential() async {
    try {
      Query<Map<String, dynamic>> base = FirebaseFirestore.instance
          .collection('residentialPortfolio');
      var snapshot = await base.get();
      var items = snapshot.docs
          .map((doc) => ResidentialPortfolio.fromFirestore(doc))
          .toList();
      if (items.isEmpty) {
        final alt1 = await FirebaseFirestore.instance
            .collection('ResidentialPortfolio')
            .get();
        items = alt1.docs
            .map((doc) => ResidentialPortfolio.fromFirestore(doc))
            .toList();
      }
      if (items.isEmpty) {
        final alt2 = await FirebaseFirestore.instance
            .collection('residential portfolio')
            .get();
        items = alt2.docs
            .map((doc) => ResidentialPortfolio.fromFirestore(doc))
            .toList();
      }
      if (items.isEmpty) {
        final alt3 = await FirebaseFirestore.instance
            .collection('residential_portfolio')
            .get();
        items = alt3.docs
            .map((doc) => ResidentialPortfolio.fromFirestore(doc))
            .toList();
      }
      if (items.isEmpty) {
        final alt4 = await FirebaseFirestore.instance
            .collection('Residential Portfolio')
            .get();
        items = alt4.docs
            .map((doc) => ResidentialPortfolio.fromFirestore(doc))
            .toList();
      }
      if (items.isEmpty) {
        final alt5 = await FirebaseFirestore.instance
            .collection('residentialPortfolios')
            .get();
        items = alt5.docs
            .map((doc) => ResidentialPortfolio.fromFirestore(doc))
            .toList();
      }
      _residential = items;
    } catch (e) {
      _resError = e.toString();
    }
    setState(() {
      _loadingResidential = false;
    });
  }

  Future<void> _fetchLandInitial() async {
    try {
      // Fetch all land documents (no orderBy to avoid requiring Firestore index)
      final snapshot = await FirebaseFirestore.instance
          .collection('landPortfolio')
          .get();
      debugPrint('[Land] Fetched ${snapshot.docs.length} land docs');
      _land = snapshot.docs
          .map((doc) => LandPortfolio.fromFirestore(doc))
          .toList();
      // Sort locally by createdAt (newest first)
      _land.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _landHasMore = false; // All docs fetched
    } catch (e) {
      debugPrint('[Land] Error fetching land: $e');
    }
    setState(() {
      _loadingLand = false;
    });
  }

  Future<void> _fetchLandMore() async {
    // Since we removed orderBy from server, pagination is handled by initial fetch
    // This is now a no-op since we fetch all in _fetchLandInitial
  }

  void _onLandScroll() {
    if (!_landHasMore || _loadingLandMore) return;
    if (_landScrollController.position.pixels >=
        _landScrollController.position.maxScrollExtent - 200) {
      _fetchLandMore();
    }
  }

  @override
  void dispose() {
    _landScrollController.removeListener(_onLandScroll);
    _landScrollController.dispose();
    super.dispose();
  }

  double _parsePrice(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  int _parseSqft(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  Property _mapResidential(ResidentialPortfolio r) {
    debugPrint('🏠 BUY_PAGE [${r.title}]: images has ${r.images.length} images');
    return Property(
      id: r.id,
      name: r.title,
      location: r.location,
      price: _parsePrice(r.price),
      images: r.images,
      description: r.description,
      bedrooms: r.bedrooms,
      bathrooms: r.bathrooms,
      sqft: _parseSqft(r.sqft),
      amenities: r.amenities,
      isFeatured: false,
      type: PropertyType.sale,
      latitude: r.latitude,
      longitude: r.longitude,
    );
  }

  Property _mapLand(LandPortfolio l) {
    final acres = l.lotSizeAcres;
    final sqft = acres > 0 ? (acres * 43560).round() : 0;
    debugPrint('🏔️ BUY_PAGE [${l.title}]: images has ${l.images?.length ?? 0} images');
    return Property(
      id: l.id,
      name: l.title,
      location: l.locationString,
      price: l.price,
      images: l.images ?? [],
      description: l.description,
      bedrooms: 0,
      bathrooms: 0,
      sqft: sqft,
      amenities: l.amenities ?? [],
      isFeatured: false,
      type: PropertyType.sale,
      latitude: l.latitude,
      longitude: l.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        
        appBar: AppBar(
          elevation: 0,
          title: Text('For Sale', style: Theme.of(context).textTheme.headlineMedium),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Residential'),
              Tab(text: 'Land'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildResidentialTab(context),
            _buildLandTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentialTab(BuildContext context) {
    var list = _residential.where((r) {
      if (_resSearch.isEmpty) return true;
      final q = _resSearch.toLowerCase();
      return r.title.toLowerCase().contains(q) || r.location.toLowerCase().contains(q);
    }).toList();

    // Apply filters
    list = list.where((r) {
      final price = _parsePrice(r.price);
      final beds = r.bedrooms;
      if (_resMinPrice != null && price < _resMinPrice!) return false;
      if (_resMaxPrice != null && price > _resMaxPrice!) return false;
      if (_resMinBedrooms != null && beds < _resMinBedrooms!) return false;
      return true;
    }).toList();

    // Sort
    switch (_resSort) {
      case 'price_asc':
        list.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
        break;
      case 'price_desc':
        list.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
        break;
      default:
        break;
    }

    if (_loadingResidential) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 60, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text('No residential properties', style: Theme.of(context).textTheme.titleMedium),
            if (_resError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Unable to load residentialPortfolio. Check Firestore rules or collection name.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                child: Text(
                  _resError!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBarWidget(
                  hintText: 'Search residential...',
                  onChanged: (v) => setState(() => _resSearch = v),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              FilterButton(onTap: () => _showResidentialFilterDialog(context)),
              const SizedBox(width: AppTheme.spacingSmall),
              const CompareButton(),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.spacingMedium,
                mainAxisSpacing: AppTheme.spacingMedium,
                childAspectRatio: 0.75,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final property = _mapResidential(list[index]);
                return AnimatedPropertyCard(
                  property: property,
                  index: index,
                  heroTagPrefix: 'buy_residential',
                  onTap: () {
                    Navigator.push(
                      context,
                      AppAnimations.scaleRoute(
                        PropertyDetailsPage(
                          property: property,
                          heroIndex: index,
                          heroTagPrefix: 'buy_residential',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandTab(BuildContext context) {
    var list = _land.where((l) {
      if (_landSearch.isEmpty) return true;
      final q = _landSearch.toLowerCase();
      return l.title.toLowerCase().contains(q) || l.locationString.toLowerCase().contains(q);
    }).toList();

    // Apply filters
    list = list.where((l) {
      final price = l.price;
      if (_landMinPrice != null && price < _landMinPrice!) return false;
      if (_landMaxPrice != null && price > _landMaxPrice!) return false;
      return true;
    }).toList();

    // Sort
    switch (_landSort) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      default:
        break;
    }

    if (_loadingLand) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.landscape_outlined, size: 60, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text('No land listings', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBarWidget(
                  hintText: 'Search land...',
                  onChanged: (v) => setState(() => _landSearch = v),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              FilterButton(onTap: () => _showLandFilterDialog(context)),
              const SizedBox(width: AppTheme.spacingSmall),
              const CompareButton(),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Expanded(
            child: GridView.builder(
              controller: _landScrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.spacingMedium,
                mainAxisSpacing: AppTheme.spacingMedium,
                childAspectRatio: 0.75,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final property = _mapLand(list[index]);
                return AnimatedPropertyCard(
                  property: property,
                  index: index,
                  heroTagPrefix: 'buy_land',
                  onTap: () {
                    Navigator.push(
                      context,
                      AppAnimations.scaleRoute(
                        PropertyDetailsPage(
                          property: property,
                          heroIndex: index,
                          heroTagPrefix: 'buy_land',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showResidentialFilterDialog(BuildContext context) {
    final minController = TextEditingController(text: _resMinPrice?.toString() ?? '');
    final maxController = TextEditingController(text: _resMaxPrice?.toString() ?? '');
    final bedsController = TextEditingController(text: _resMinBedrooms?.toString() ?? '');
    String sort = _resSort;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filters & Sort', style: Theme.of(context).textTheme.headlineMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Price', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Price', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: bedsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Bedrooms', prefixIcon: Icon(Icons.bed)),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              DropdownButtonFormField<String>(
                initialValue: sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort', prefixIcon: Icon(Icons.sort)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _resMinPrice = double.tryParse(minController.text);
                _resMaxPrice = double.tryParse(maxController.text);
                _resMinBedrooms = int.tryParse(bedsController.text);
                _resSort = sort;
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showLandFilterDialog(BuildContext context) {
    final minController = TextEditingController(text: _landMinPrice?.toString() ?? '');
    final maxController = TextEditingController(text: _landMaxPrice?.toString() ?? '');
    String sort = _landSort;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filters & Sort', style: Theme.of(context).textTheme.headlineMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Price', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Price', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              DropdownButtonFormField<String>(
                initialValue: sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort', prefixIcon: Icon(Icons.sort)),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'newest', child: Text('Newest', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => sort = v ?? 'none',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _landMinPrice = double.tryParse(minController.text);
                _landMaxPrice = double.tryParse(maxController.text);
                _landSort = sort;
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
