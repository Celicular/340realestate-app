import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../providers/auth_provider.dart';
import '../widgets/login_dialog.dart';
import '../widgets/floating_chatbot.dart';
import 'home_page.dart';
import 'rentals_page.dart';
import 'buy_page.dart';
import 'profile_page.dart';
import 'more_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  DateTime? _lastLoginPrompt;
  bool _showingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _maybePromptLogin();
        _startLoginPromptTimer();
      });
    });
  }

  void _startLoginPromptTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 5));
      if (!mounted) return false;
      _maybePromptLogin();
      return true;
    });
  }

  void _maybePromptLogin() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final hasCurrentUser = authProv.isAuthenticated ||
        (auth.FirebaseAuth.instance.currentUser != null);
    if (hasCurrentUser) return;
    final now = DateTime.now();
    if (_showingDialog) return;
    if (_lastLoginPrompt != null &&
        now.difference(_lastLoginPrompt!).inMinutes < 5) {
      return;
    }
    _lastLoginPrompt = now;
    _showingDialog = true;
    showDialog(
      context: context,
      builder: (context) => const LoginDialog(),
    ).then((_) {
      _showingDialog = false;
    });
  }

  final List<Widget> _pages = [
    const HomePage(),
    const RentalsPage(),
    const BuyPage(),
    const ProfilePage(),
    const MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return FloatingChatbot(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(
              color: AppTheme.cardShadowColor,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: AppTheme.spacingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.apartment_rounded,
                  label: 'Rentals',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.storefront_rounded,
                  label: 'For Sale',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
