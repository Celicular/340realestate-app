import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';
// Removed developer/testing pages per request

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
              _buildSettingItem(
                context,
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle: _themeSubtitle(
                    Provider.of<ThemeProvider>(context).appThemeMode),
                onTap: () {
                  _showThemeDialog(context);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.color_lens_outlined,
                title: 'App Color',
                subtitle: _colorSubtitle(
                    Provider.of<ThemeProvider>(context).seedColor),
                onTap: () {
                  _showColorDialog(context);
                },
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
              Text(
                'Privacy & Security',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildSettingItem(
                context,
                icon: Icons.lock_outline,
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
              _buildSettingItem(
                context,
                icon: Icons.security,
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
              // Removed Biometric Authentication
              const SizedBox(height: AppTheme.spacingXLarge),
              Text(
                'About',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildSettingItem(
                context,
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              _buildSettingItem(
                context,
                icon: Icons.update,
                title: 'Check for Updates',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You are using the latest version'),
                    ),
                  );
                },
              ),
              // Removed View Firestore Schema, Test Firebase Connection, Analyze Firestore Collections
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final current = themeProvider.appThemeMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              trailing: current == AppThemeMode.light
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
              trailing: current == AppThemeMode.dark
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System'),
              trailing: current == AppThemeMode.system
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Auto (12h rotation)'),
              trailing: current == AppThemeMode.auto
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.auto);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final options = <Map<String, dynamic>>[
      {'label': 'Sand', 'color': const Color(0xFFF6D7B0)},
      {'label': 'Ocean', 'color': const Color(0xFF3B82F6)},
      {'label': 'Forest', 'color': const Color(0xFF10B981)},
      {'label': 'Sunset', 'color': const Color(0xFFEF4444)},
      {'label': 'Lavender', 'color': const Color(0xFFA78BFA)},
      {'label': 'Coral', 'color': const Color(0xFFFF7F50)},
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select App Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final Color c = opt['color'] as Color;
            final String label = opt['label'] as String;
            final bool selected =
                Provider.of<ThemeProvider>(context).seedColor == c;
            return ListTile(
              leading: CircleAvatar(backgroundColor: c),
              title: Text(label),
              trailing: selected
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                themeProvider.setSeedColor(c);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _colorSubtitle(Color color) {
    final hex =
        color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}';
  }

  String _themeSubtitle(AppThemeMode mode) {
    if (mode == AppThemeMode.light) return 'Light';
    if (mode == AppThemeMode.dark) return 'Dark';
    if (mode == AppThemeMode.auto) return 'Auto (12h rotation)';
    return 'System';
  }
}
