import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final String? hintText;
  final Function(String)? onChanged;

  const SearchBarWidget({
    super.key,
    this.onTap,
    this.hintText,
    this.onChanged,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If onChanged is provided, make it a real search field
    if (widget.onChanged != null) {
      return TextField(
        controller: _controller,
        onChanged: (v) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 250), () {
            widget.onChanged!(v);
          });
        },
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search rentals...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              );
            },
          ),
        ),
      );
    }

    // Otherwise, use the tap-only version
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Text(
                  widget.hintText ?? 'Search properties...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
