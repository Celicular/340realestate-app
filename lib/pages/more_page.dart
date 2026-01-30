import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'mortgage_calculator_page.dart';
import 'agents_page.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_support_page.dart';
import 'terms_page.dart';
import 'privacy_policy_page.dart';
import 'favorites_page.dart';
import 'recently_viewed_page.dart';
import 'chatbot_page.dart';
import 'kyc_verification_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Tools',
            items: [
              _MenuItem(
                icon: Icons.calculate,
                title: 'Mortgage Calculator',
                subtitle: 'Calculate your monthly payments',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MortgageCalculatorPage(),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.verified_user,
                title: 'KYC Verification',
                subtitle: 'Verify your identity',
                onTap: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final userId = authProvider.user?.uid;
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KYCVerificationPage(userId: userId),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'About',
            items: [
              _MenuItem(
                icon: Icons.location_city,
                title: 'About St. John',
                subtitle: 'Discover the island',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AboutPage(contentType: 'stjohn'),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.info,
                title: 'About Us',
                subtitle: 'Our story and mission',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutPage(contentType: 'us'),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.people,
                title: 'Meet Our Team',
                subtitle: 'Our real estate experts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgentsPage(),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.help,
                title: 'FAQ',
                subtitle: 'Frequently asked questions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Legal',
            items: [
              _MenuItem(
                icon: Icons.description,
                title: 'Terms and Conditions',
                subtitle: 'Read our terms',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsPage(),
                    ),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.privacy_tip,
                title: 'Privacy and Data',
                subtitle: 'How we protect your data',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'App',
            items: [
              _MenuItem(
                icon: Icons.star,
                title: 'Rate This App',
                subtitle: 'Share your feedback',
                onTap: () {
                  // TODO: Open app store for rating
                },
              ),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'About the App',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  // TODO: Show app info dialog
                },
              ),
              _MenuItem(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppTheme.textTertiary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children:
                items.map((item) => _buildMenuItem(context, item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textTertiary,
      ),
      onTap: item.onTap,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
