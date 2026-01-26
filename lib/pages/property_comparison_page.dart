import 'package:flutter/material.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

class PropertyComparisonPage extends StatelessWidget {
  final List<Property> properties;

  const PropertyComparisonPage({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    if (properties.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare Properties')),
        body: const Center(
          child: Text('Select at least 2 properties to compare'),
        ),
      );
    }

    final prop1 = properties[0];
    final prop2 = properties[1];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Properties'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Property Images
            Row(
              children: [
                Expanded(
                  child: Image.network(
                    prop1.imageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Image.network(
                    prop2.imageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Comparison Table
            _buildComparisonRow('Name', prop1.name, prop2.name),
            _buildComparisonRow('Price', prop1.formattedPrice, prop2.formattedPrice),
            _buildComparisonRow('Location', prop1.location, prop2.location),
            _buildComparisonRow(
              'Bedrooms',
              '${prop1.bedrooms}',
              '${prop2.bedrooms}',
            ),
            _buildComparisonRow(
              'Bathrooms',
              '${prop1.bathrooms}',
              '${prop2.bathrooms}',
            ),
            _buildComparisonRow(
              'Square Feet',
              '${prop1.sqft}',
              '${prop2.sqft}',
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Amenities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...prop1.amenities.map((amenity) => _buildAmenityRow(
                  amenity,
                  prop1.amenities.contains(amenity),
                  prop2.amenities.contains(amenity),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value1, String value2) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value1, textAlign: TextAlign.center)),
          Expanded(child: Text(value2, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildAmenityRow(String amenity, bool has1, bool has2) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(amenity)),
          Expanded(
            child: Icon(
              has1 ? Icons.check_circle : Icons.cancel,
              color: has1 ? Colors.green : Colors.red,
            ),
          ),
          Expanded(
            child: Icon(
              has2 ? Icons.check_circle : Icons.cancel,
              color: has2 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
