import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  // List of all collections
  final collections = [
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

  print('=' * 80);
  print('FIRESTORE COLLECTIONS ANALYSIS');
  print('=' * 80);
  print('');

  for (final collectionName in collections) {
    print('\n${'=' * 80}');
    print('COLLECTION: $collectionName');
    print('=' * 80);
    
    try {
      final snapshot = await firestore.collection(collectionName).limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        print('⚠️  EMPTY - No documents found');
        continue;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      
      print('✅ Document ID: ${doc.id}');
      print('\nFIELDS:');
      print('-' * 80);
      
      _printFields(data, 0);
      
    } catch (e) {
      print('❌ ERROR: $e');
    }
  }
  
  print('\n${'=' * 80}');
  print('ANALYSIS COMPLETE');
  print('=' * 80);
}

void _printFields(Map<String, dynamic> data, int indent) {
  final indentStr = '  ' * indent;
  
  data.forEach((key, value) {
    if (value == null) {
      print('$indentStr- $key: null');
    } else if (value is Map) {
      print('$indentStr- $key: (map)');
      _printFields(value as Map<String, dynamic>, indent + 1);
    } else if (value is List) {
      print('$indentStr- $key: (array) [${value.length} items]');
      if (value.isNotEmpty) {
        final first = value[0];
        if (first is Map) {
          print('$indentStr  First item:');
          _printFields(first as Map<String, dynamic>, indent + 2);
        } else {
          print('$indentStr  First item: $first (${first.runtimeType})');
        }
      }
    } else if (value is Timestamp) {
      print('$indentStr- $key: ${value.toDate()} (timestamp)');
    } else {
      print('$indentStr- $key: $value (${value.runtimeType})');
    }
  });
}
