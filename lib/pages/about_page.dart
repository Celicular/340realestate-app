import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  final String? contentType;
  const AboutPage({super.key, this.contentType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: contentType == 'stjohn'
              ? _buildStJohnContent(context)
              : _buildAboutUsContent(context),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
              child: InkWell(
                onTap: title.toLowerCase() == 'contact'
                    ? () => _handleItemTap(item)
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: title.toLowerCase() == 'contact'
                                  ? TextDecoration.underline
                                  : null,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  

  Widget _buildAboutUsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          child: const Icon(
            Icons.home_rounded,
            size: 70,
            color: AppTheme.backgroundColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXLarge),
        Text(
          'Your Key to Paradise: The Local Experts in St. John Real Estate',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        Text(
          'Welcome to 340 Real Estate, your dedicated partner in navigating the vibrant and unique property market of St. John, U.S. Virgin Islands. Our name is a proud nod to our deep roots in this community—"340" is our area code, a constant reminder of our local commitment and expertise. We don\'t just sell properties here; we live here, we love it here, and we know this island from the sandy shores to the highest peaks.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'At 340 Real Estate, we believe that buying or selling a home in St. John is about more than just a transaction; it\'s about a lifestyle. Our team is made up of passionate, long-time residents who have an intimate understanding of each neighborhood\'s unique character. Whether you\'re dreaming of a luxury villa with breathtaking ocean views, a charming cottage tucked away in the hills, or the perfect plot of land to build your future, our unparalleled local knowledge is your greatest asset.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'Our approach is built on a foundation of integrity, personalized service, and a genuine desire to see our clients succeed. We take the time to understand your vision and work tirelessly to make it a reality. By combining our insider expertise with the latest market insights, we ensure a seamless, transparent, and rewarding experience from start to finish.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'Ready to find your piece of paradise? Let\'s start the conversation. Contact 340 Real Estate today and let our local knowledge lead you home.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingXLarge),
        _buildSection(
          context,
          title: 'Island Quick Facts',
          items: [
            'Size: 20 square miles – 7 miles long, 3 miles wide',
            'Highest Point: Bordeaux Mountain – 1,277 ft above sea level',
            'Map of St. John',
          ],
        ),
        const SizedBox(height: AppTheme.spacingXLarge),
        _buildSection(
          context,
          title: 'Contact',
          items: [
            '340 Real Estate Company, PO Box 766, St John, VI 00831',
            '+1 340-643-6068',
            '340realestateco@gmail.com',
          ],
        ),
      ],
    );
  }

  Widget _buildStJohnContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'St. John, Virgin Islands Real Estate',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          'A Historical Journey and Modern Paradise',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        _buildSection(
          context,
          title: 'Island Quick Facts',
          items: [
            'Size: 20 square miles – 7 miles long, 3 miles wide.',
            'Highest Point: Bordeaux Mountain – 1,277 ft above sea level',
            'Map of St. John',
          ],
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        Text(
          'real estate companies in st john in US virgin islands, real estate for sale in st John US virgin islands, real estate for sale in st thomas virgin islands, real estate for sale in the virgin islands, real estate for sale st john usvi, real estate news, caribbean real estate, rentals & more.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        Text(
          'A Historical Journey and Modern Paradise',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'St. John became part of the United States in 1917 when it was purchased from Denmark. However, it wasn’t until the 1930s that word of this tropical paradise began to reach mainland America. This marked the beginning of a tourism era that would eventually blossom into a thriving industry.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'A pivotal moment came in 1956 when conservationist and philanthropist Laurance S. Rockefeller donated a significant portion of St. John to the U.S. Federal Government, forming the Virgin Islands National Park—initially 5,000 acres of protected land.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'Rockefeller’s donation was accepted by Secretary of the Interior Fred Seaton, who declared: “The government will take care of this sacred soil—these green hills, valleys, and flaming miles. Take good, proper, Christ-like care!”',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'Since then, the park has expanded to over 7,200 acres of land and 5,600 acres of marine habitat, preserving nearly 56,500 acres of beauty and biodiversity.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        Text(
          'Modern-Day St. John: Accessible, Accommodating, and Awe-Inspiring',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'One of the best parts? U.S. citizens don’t need a passport to visit. Whether you prefer rustic campgrounds or luxury resorts, St. John offers accommodations for every traveler.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'The island also boasts accessible beaches like Trunk Bay—frequently ranked among the most beautiful in the Caribbean and the world.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          'Today, St. John is more than just a tropical escape—it’s a shining example of nature preserved, history honored, and paradise made accessible to all.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Future<void> _handleItemTap(String item) async {
    final isEmail = item.contains('@');
    final isPhone = RegExp(r'^\+?[0-9\-\s\(\)]+$').hasMatch(item);
    if (isEmail) {
      final uri = Uri(scheme: 'mailto', path: item);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (isPhone) {
      final digits = item.replaceAll(RegExp(r'[^0-9\+]'), '');
      final uri = Uri(scheme: 'tel', path: digits);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(item)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
