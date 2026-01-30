import 'package:flutter/material.dart';
import '../models/property.dart';

class ComparisonProvider extends ChangeNotifier {
  final List<Property> _selectedProperties = [];
  static const int maxComparisonCount = 2;

  List<Property> get selectedProperties => _selectedProperties;
  int get selectedCount => _selectedProperties.length;
  bool get canCompare => _selectedProperties.length >= 2;

  bool isSelected(String propertyId) {
    return _selectedProperties.any((p) => p.id == propertyId);
  }

  bool canAddMore() {
    return _selectedProperties.length < maxComparisonCount;
  }

  void toggleProperty(Property property) {
    final index = _selectedProperties.indexWhere((p) => p.id == property.id);
    if (index != -1) {
      _selectedProperties.removeAt(index);
    } else {
      if (_selectedProperties.length < maxComparisonCount) {
        _selectedProperties.add(property);
      }
    }
    notifyListeners();
  }

  void clearAll() {
    _selectedProperties.clear();
    notifyListeners();
  }

  void removeProperty(String propertyId) {
    _selectedProperties.removeWhere((p) => p.id == propertyId);
    notifyListeners();
  }
}
