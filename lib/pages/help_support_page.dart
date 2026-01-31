import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';
import 'about_page.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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
          'Help & Support',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Support
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 60,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    Text(
                      'Need Help?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Our support team is here to help you',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showContactDialog(context);
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
              // FAQ Section
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildFAQItem(
                context,
                question: 'How do I search for properties?',
                answer:
                    'Use the search bar on the home page or browse by category. You can filter by type, price range, location, and more.',
              ),
              _buildFAQItem(
                context,
                question: 'How do I save properties to favorites?',
                answer:
                    'Tap the heart icon on any property card or details page to add it to your favorites. Access them from your profile.',
              ),
              _buildFAQItem(
                context,
                question: 'How do I contact a real estate agent?',
                answer:
                    'On any property details page, tap the "Contact Agent" button at the bottom to send a message or schedule a viewing.',
              ),
              _buildFAQItem(
                context,
                question: 'Can I filter properties by price?',
                answer:
                    'Yes! Use the filter button next to the search bar to set your price range, property type, bedrooms, and other preferences.',
              ),
              _buildFAQItem(
                context,
                question: 'How do I update my profile?',
                answer:
                    'Go to Profile > Edit Profile to update your personal information, contact details, and profile picture.',
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
              // Quick Links
              Text(
                'Quick Links',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildLinkItem(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              _buildLinkItem(
                context,
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsPage(),
                    ),
                  );
                },
              ),
              _buildLinkItem(
                context,
                icon: Icons.info_outline,
                title: 'About 340 Real Estate',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
      required String question,
      required String answer,
    }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.outline,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose how you\'d like to contact us:'),
            const SizedBox(height: AppTheme.spacingLarge),
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              title: const Text('Email'),
              subtitle: const Text('340realestateco@gmail.com'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri(scheme: 'mailto', path: '340realestateco@gmail.com'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
              title: const Text('Phone'),
              subtitle: const Text('+1 340-643-6068'),
              onTap: () {
                Navigator.pop(context);
                final digits = '+13406436068';
                launchUrl(
                  Uri(scheme: 'tel', path: digits),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
