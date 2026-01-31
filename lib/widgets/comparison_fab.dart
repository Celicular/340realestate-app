import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comparison_provider.dart';
import '../pages/property_comparison_page.dart';

class ComparisonFAB extends StatelessWidget {
  const ComparisonFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ComparisonProvider>(
      builder: (context, comparisonProvider, child) {
        if (comparisonProvider.selectedCount == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () {
            if (comparisonProvider.canCompare) {
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
                const SnackBar(
                  content: Text('Select at least 2 properties to compare'),
                ),
              );
            }
          },
          icon: const Icon(Icons.compare_arrows),
          label: Text('Compare (${comparisonProvider.selectedCount})'),
          backgroundColor: comparisonProvider.canCompare
              ? Theme.of(context).primaryColor
              : Colors.grey,
        );
      },
    );
  }
}
