import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseConnectionTest extends StatefulWidget {
  const FirebaseConnectionTest({super.key});

  @override
  State<FirebaseConnectionTest> createState() => _FirebaseConnectionTestState();
}

class _FirebaseConnectionTestState extends State<FirebaseConnectionTest> {
  String _status = 'Testing Firebase connection...';
  bool _isConnected = false;
  final Map<String, dynamic> _results = {};

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test 1: Firebase Core
      setState(() {
        _status = 'Testing Firebase Core...';
      });
      
      final app = Firebase.app();
      _results['Firebase Core'] = '✅ Connected (${app.name})';
      _results['Project ID'] = app.options.projectId;

      // Test 2: Firestore
      setState(() {
        _status = 'Testing Firestore...';
      });
      
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('_test_').limit(1).get();
      _results['Firestore'] = '✅ Connected';

      // Test 3: Auth
      setState(() {
        _status = 'Testing Firebase Auth...';
      });
      
      final auth = FirebaseAuth.instance;
      _results['Auth'] = '✅ Connected';
      _results['Current User'] = auth.currentUser?.email ?? 'Not signed in';

      // Test 4: Check collections
      setState(() {
        _status = 'Checking collections...';
      });

      // Check properties collection
      final propertiesSnapshot = await firestore.collection('properties').limit(1).get();
      _results['Properties Collection'] = propertiesSnapshot.docs.isEmpty 
          ? '⚠️ Empty (0 documents)' 
          : '✅ Has data (${propertiesSnapshot.docs.length}+ documents)';

      // Check rentalProperties collection
      final rentalsSnapshot = await firestore.collection('rentalProperties').limit(1).get();
      _results['Rentals Collection'] = rentalsSnapshot.docs.isEmpty 
          ? '⚠️ Empty (0 documents)' 
          : '✅ Has data (${rentalsSnapshot.docs.length}+ documents)';

      // Check users collection
      final usersSnapshot = await firestore.collection('users').limit(1).get();
      _results['Users Collection'] = usersSnapshot.docs.isEmpty 
          ? '⚠️ Empty (0 documents)' 
          : '✅ Has data (${usersSnapshot.docs.length}+ documents)';

      setState(() {
        _status = 'All tests completed!';
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _results['Error'] = '❌ $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: _isConnected ? Colors.green : Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (!_isConnected)
                      const CircularProgressIndicator()
                    else
                      const Icon(Icons.check_circle, color: Colors.green, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _results.entries.map((entry) {
                  return Card(
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: Text(entry.value.toString()),
                      leading: Icon(
                        entry.value.toString().startsWith('✅') 
                            ? Icons.check_circle 
                            : entry.value.toString().startsWith('⚠️')
                                ? Icons.warning
                                : Icons.error,
                        color: entry.value.toString().startsWith('✅') 
                            ? Colors.green 
                            : entry.value.toString().startsWith('⚠️')
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
