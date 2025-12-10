import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Script to fetch and display the current Firestore database schema
/// Run with: dart run lib/scripts/fetch_firestore_schema.dart
void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('🔍 Fetching Firestore Schema from realestate-d23eb...\n');
  print('=' * 80);
  
  final firestore = FirebaseFirestore.instance;
  
  // Actual collections from your Firebase Console
  final actualCollections = [
    'agents',
    'blogs',
    'connectwithus',
    'contacts',
    'landPortfolio',
    'properties',
    'rentalProperties',
    'rentals',
    'residentialPortfolio',
    'reviews',
    'team_members',
    'users',
  ];

  print('\n📊 FIRESTORE DATABASE SCHEMA\n');
  print('Project ID: realestate-d23eb');
  print('Total Collections: ${actualCollections.length}\n');
  print('=' * 80);

  for (String collectionName in actualCollections) {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .limit(3)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('\n✅ Collection: "$collectionName"');
        print('   📄 Documents found: ${snapshot.docs.length}');
        
        // Analyze all documents to get complete field list
        Set<String> allFields = {};
        Map<String, Set<String>> fieldTypes = {};
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          data.forEach((key, value) {
            allFields.add(key);
            String type = _getFirestoreType(value);
            fieldTypes.putIfAbsent(key, () => {});
            fieldTypes[key]!.add(type);
          });
        }
        
        print('   📋 Fields (${allFields.length}):');
        for (String field in allFields.toList()..sort()) {
          String types = fieldTypes[field]!.join(' | ');
          print('      • $field: $types');
        }
        
        // Show sample document
        print('\n   📝 Sample Document:');
        final sampleData = snapshot.docs.first.data();
        final prettyJson = const JsonEncoder.withIndent('   ').convert(sampleData);
        print('   $prettyJson');
        
      } else {
        print('\n⚠️  Collection: "$collectionName" - Empty (no documents)');
      }
    } catch (e) {
      print('\n❌ Collection: "$collectionName" - Error: $e');
    }
    print('\n${'-' * 80}');
  }

  print('\n${'=' * 80}');
  print('✨ Schema fetch complete!\n');
}

String _getFirestoreType(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return 'string';
  if (value is int) return 'number (int)';
  if (value is double) return 'number (double)';
  if (value is bool) return 'boolean';
  if (value is Timestamp) return 'timestamp';
  if (value is List) return 'array';
  if (value is Map) return 'map';
  if (value is GeoPoint) return 'geopoint';
  return value.runtimeType.toString();
}
