import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_dialog.dart';
import 'edit_profile_page.dart';
import 'notifications_page.dart';
import 'help_support_page.dart';
import 'booking_history_page.dart';
import 'favorites_page.dart';
import 'recently_viewed_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            final userProfile = authProvider.userProfile;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    child: Column(
                      children: [
                        const SizedBox(height: AppTheme.spacingLarge),

                        if (user != null) ...[
                          Text(
                            (() {
                              var n = userProfile?.name ?? '';
                              if (n.trim().isEmpty) {
                                n = userProfile?.displayName ?? '';
                              }
                              if (n.trim().isEmpty) {
                                n = user.displayName ??
                                    (user.email?.split('@').first ?? 'User');
                              }
                              return n;
                            })(),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          Text(
                            user.email ?? '',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                          if ((userProfile?.phoneNumber?.isNotEmpty ?? false) ||
                              ((user.phoneNumber ?? '').isNotEmpty)) ...[
                            const SizedBox(height: AppTheme.spacingSmall),
                            Text(
                              (() {
                                final hasProfilePhone =
                                    userProfile?.phoneNumber?.isNotEmpty ??
                                        false;
                                return hasProfilePhone
                                    ? (userProfile?.phoneNumber ?? '')
                                    : (user.phoneNumber ?? '');
                              })(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                          const SizedBox(height: AppTheme.spacingMedium),
                          // KYC Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (userProfile?.isKYCVerified ?? false)
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (userProfile?.isKYCVerified ?? false)
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (userProfile?.isKYCVerified ?? false)
                                      ? Icons.verified_user
                                      : Icons.warning_amber,
                                  color: (userProfile?.isKYCVerified ?? false)
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (userProfile?.isKYCVerified ?? false)
                                      ? 'KYC Verified'
                                      : 'KYC Not Verified',
                                  style: TextStyle(
                                    color: (userProfile?.isKYCVerified ?? false)
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Guest User',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const LoginDialog(),
                              );
                            },
                            child: const Text('Sign In'),
                          ),
                        ],

                        const SizedBox(height: AppTheme.spacingXLarge),
                        // Menu Items

                        if (user != null)
                          _buildMenuItem(
                            context,
                            icon: Icons.edit,
                            title: 'Edit Profile',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                          ),
                        if (user != null)
                          _buildMenuItem(
                            context,
                            icon: Icons.calendar_month_outlined,
                            title: 'My Bookings',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BookingHistoryPage(),
                                ),
                              );
                            },
                          ),
                        _buildMenuItem(
                          context,
                          icon: Icons.bookmark_outline,
                          title: 'Saved Properties',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.history,
                          title: 'Recently Viewed',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RecentlyViewedPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportPage(),
                              ),
                            );
                          },
                        ),
                        if (user != null)
                          _buildMenuItem(
                            context,
                            icon: Icons.logout,
                            title: 'Logout',
                            onTap: () async {
                              await authProvider.signOut();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logged out successfully'),
                                  ),
                                );
                              }
                            },
                            isDestructive: true,
                          ),
                        if (user != null)
                          _buildMenuItem(
                            context,
                            icon: Icons.delete_outline,
                            title: 'Delete Account',
                            onTap: () => _showDeleteAccountDialog(context, authProvider),
                            isDestructive: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
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
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDestructive
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. '
          'All your data, bookings, and saved properties will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, authProvider);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, AuthProvider authProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await authProvider.deleteAccount();

      if (!context.mounted) return;

      Navigator.pop(context);

      if (success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        nav.pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to delete account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
