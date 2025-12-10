import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_dialog.dart';
import 'edit_profile_page.dart';
import 'notifications_page.dart';
import 'help_support_page.dart';
import 'about_page.dart';
import 'booking_history_page.dart';

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
                        _buildMenuItem(
                          context,
                          icon: Icons.info_outline,
                          title: 'About',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AboutPage(contentType: 'us'),
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
}
