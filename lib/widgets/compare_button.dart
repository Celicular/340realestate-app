import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/comparison_provider.dart';
import '../pages/property_comparison_page.dart';

/// A compact compare button that shows the count of selected properties
/// and navigates to the comparison page when tapped.
class CompareButton extends StatelessWidget {
  const CompareButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ComparisonProvider>(
      builder: (context, comparisonProvider, child) {
        final count = comparisonProvider.selectedProperties.length;
        return GestureDetector(
          onTap: () {
            if (count >= 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PropertyComparisonPage(
                    properties: comparisonProvider.selectedProperties,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    count == 0
                        ? 'Add properties to compare from property cards'
                        : 'Add at least one more property to compare',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: count >= 2
                  ? AppTheme.primaryColor
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: count >= 2
                    ? AppTheme.primaryColor
                    : AppTheme.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: count >= 2
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.textPrimary),
                  size: 20,
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: count >= 2
                          ? Colors.white
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: count >= 2
                            ? AppTheme.primaryColor
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
