import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FilterButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppTheme.textTertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.tune,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
