import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class FirestoreSchemaPage extends StatefulWidget {
  const FirestoreSchemaPage({super.key});

  @override
  State<FirestoreSchemaPage> createState() => _FirestoreSchemaPageState();
}

class _FirestoreSchemaPageState extends State<FirestoreSchemaPage> {
  final List<String> collections = [
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

  Map<String, Map<String, dynamic>> schemaData = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchSchema();
  }

  Future<void> _fetchSchema() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      for (String collectionName in collections) {
        try {
          final snapshot = await firestore
              .collection(collectionName)
              .limit(1)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final data = doc.data();
            
            Map<String, String> fields = {};
            data.forEach((key, value) {
              fields[key] = _getFirestoreType(value);
            });

            schemaData[collectionName] = {
              'exists': true,
              'fields': fields,
              'sampleData': data,
            };
          } else {
            schemaData[collectionName] = {
              'exists': true,
              'fields': {},
              'isEmpty': true,
            };
          }
        } catch (e) {
          schemaData[collectionName] = {
            'exists': false,
            'error': e.toString(),
          };
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Firestore Schema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSchema,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 20),
                        Text('Error: $error'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchSchema,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collectionName = collections[index];
                    final data = schemaData[collectionName];

                    if (data == null) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: Icon(
                          data['exists'] == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: data['exists'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          collectionName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          data['isEmpty'] == true
                              ? 'Empty collection'
                              : data['exists'] == true
                                  ? '${(data['fields'] as Map).length} fields'
                                  : 'Error accessing',
                          style: TextStyle(
                            color: data['isEmpty'] == true
                                ? Colors.orange
                                : AppTheme.textSecondary,
                          ),
                        ),
                        children: [
                          if (data['exists'] == true && data['isEmpty'] != true)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fields:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...(data['fields'] as Map<String, String>)
                                      .entries
                                      .map((entry) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    entry.key,
                                                    style: const TextStyle(
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  entry.value,
                                                  style: const TextStyle(
                                                    color: AppTheme.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      ,
                                ],
                              ),
                            ),
                          if (data['error'] != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Error: ${data['error']}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
