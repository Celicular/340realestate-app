import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/property.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _baseUrl = EnvConfig.openRouterBaseUrl;
  final String _apiKey = EnvConfig.openRouterApiKey;
  final String _model = EnvConfig.aiModel;

  /// Generate AI response based on user message and available properties
  Future<String> generateResponse(
    String userMessage,
    List<Property> properties, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Build property context for the AI
      final propertyContext = _buildPropertyContext(properties);

      // Build messages array
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '''You are a helpful real estate assistant for 340 Real Estate.
Your job is to help users find their perfect property.

AVAILABLE PROPERTIES:
$propertyContext

INSTRUCTIONS:
- Be friendly, professional, and concise
- When users ask about properties, search through the available listings
- Recommend properties based on their requirements (price, bedrooms, location, amenities)
- If you find matching properties, mention them by name with key details
- If no properties match, suggest they adjust their criteria
- Help with property comparisons when asked
- Answer general real estate questions
- Format property recommendations clearly with bullet points
- Always include property names and prices in recommendations'''
        },
      ];

      // Add conversation history if available
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }

      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': EnvConfig.appUrl,
          'X-Title': EnvConfig.appName,
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Sorry, I couldn\'t generate a response.';
      } else {
        print('AI API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I\'m having trouble connecting right now. Please try again.';
      }
    } catch (e) {
      print('AI Service Error: $e');
      return 'Sorry, something went wrong. Please try again.';
    }
  }

  /// Build property context string for AI
  String _buildPropertyContext(List<Property> properties) {
    if (properties.isEmpty) {
      return 'No properties currently available.';
    }

    final buffer = StringBuffer();
    for (int i = 0; i < properties.length && i < 50; i++) {
      final p = properties[i];
      buffer.writeln('''
Property ${i + 1}: ${p.name}
- Price: ${p.formattedPrice}
- Location: ${p.location}
- Bedrooms: ${p.bedrooms}, Bathrooms: ${p.bathrooms}
- Size: ${p.sqft} sqft
- Type: ${p.type.name}
- Amenities: ${p.amenities.join(', ')}
''');
    }
    return buffer.toString();
  }

  /// Search properties based on natural language query
  List<Property> searchProperties(String query, List<Property> allProperties) {
    final queryLower = query.toLowerCase();
    final results = <Property>[];

    // Extract potential filters from query
    final priceMatch = RegExp(r'(\d+)k|(\d+),?000|under (\d+)').firstMatch(queryLower);
    int? maxPrice;
    if (priceMatch != null) {
      final match = priceMatch.group(1) ?? priceMatch.group(2) ?? priceMatch.group(3);
      if (match != null) {
        maxPrice = int.parse(match) * (priceMatch.group(1) != null ? 1000 : 1);
      }
    }

    final bedroomMatch = RegExp(r'(\d+)\s*(?:bed|bedroom|br|bhk)').firstMatch(queryLower);
    int? bedrooms;
    if (bedroomMatch != null) {
      bedrooms = int.parse(bedroomMatch.group(1)!);
    }

    // Filter properties
    for (final property in allProperties) {
      bool matches = true;

      // Check price
      if (maxPrice != null && property.price > maxPrice) {
        matches = false;
      }

      // Check bedrooms
      if (bedrooms != null && property.bedrooms != bedrooms) {
        matches = false;
      }

      // Check location keywords
      final locationKeywords = ['brooklyn', 'manhattan', 'queens', 'bronx', 'downtown', 'uptown'];
      for (final keyword in locationKeywords) {
        if (queryLower.contains(keyword) && !property.location.toLowerCase().contains(keyword)) {
          matches = false;
          break;
        }
      }

      // Check property type
      if (queryLower.contains('rent') && property.type != PropertyType.rental) {
        matches = false;
      }
      if ((queryLower.contains('buy') || queryLower.contains('sale')) &&
          property.type == PropertyType.rental) {
        matches = false;
      }

      // Check amenities
      final amenityKeywords = ['pool', 'gym', 'parking', 'garden', 'balcony'];
      for (final amenity in amenityKeywords) {
        if (queryLower.contains(amenity)) {
          final hasAmenity = property.amenities.any(
            (a) => a.toLowerCase().contains(amenity),
          );
          if (!hasAmenity) {
            matches = false;
            break;
          }
        }
      }

      if (matches) {
        results.add(property);
      }
    }

    // If no specific filters matched, do a general text search
    if (results.isEmpty) {
      for (final property in allProperties) {
        if (property.name.toLowerCase().contains(queryLower) ||
            property.location.toLowerCase().contains(queryLower) ||
            property.description.toLowerCase().contains(queryLower)) {
          results.add(property);
        }
      }
    }

    return results.take(5).toList();
  }
}
