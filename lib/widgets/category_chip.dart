import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';

class CategoryChip extends StatefulWidget {
  final PropertyType type;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  String get _label {
    switch (type) {
      case PropertyType.rental:
        return 'Rentals';
      case PropertyType.sale:
        return 'Sale';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.cottage:
        return 'Cottage';
      case PropertyType.house:
        return 'House';
      case PropertyType.combo:
        return 'Combo';
    }
  }

  IconData get _icon {
    switch (type) {
      case PropertyType.rental:
        return Icons.apartment_rounded;
      case PropertyType.sale:
        return Icons.shopping_cart_rounded;
      case PropertyType.villa:
        return Icons.villa_rounded;
      case PropertyType.cottage:
        return Icons.cabin_rounded;
      case PropertyType.house:
        return Icons.home_rounded;
      case PropertyType.combo:
        return Icons.category_rounded;
    }
  }

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.isSelected
                ? AppTheme.primaryColor
                : Theme.of(context).colorScheme.outline,
            width: widget.isSelected ? 0 : 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(
              widget._icon,
              size: 18,
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Text(
              widget._label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  
}
