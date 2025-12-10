import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class CollectionAnalyzerPage extends StatefulWidget {
  const CollectionAnalyzerPage({super.key});

  @override
  State<CollectionAnalyzerPage> createState() => _CollectionAnalyzerPageState();
}

class _CollectionAnalyzerPageState extends State<CollectionAnalyzerPage> {
  final List<String> _collections = [
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

  final Map<String, Map<String, dynamic>> _collectionData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyzeCollections();
  }

  Future<void> _analyzeCollections() async {
    final firestore = FirebaseFirestore.instance;
    
    for (final collection in _collections) {
      try {
        final snapshot = await firestore.collection(collection).limit(1).get();
        
        if (snapshot.docs.isNotEmpty) {
          _collectionData[collection] = snapshot.docs.first.data();
        } else {
          _collectionData[collection] = {'_empty': true};
        }
      } catch (e) {
        _collectionData[collection] = {'_error': e.toString()};
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Collection Analyzer'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _collections.length,
              itemBuilder: (context, index) {
                final collection = _collections[index];
                final data = _collectionData[collection];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      collection,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      data?['_empty'] == true
                          ? 'Empty collection'
                          : data?['_error'] != null
                              ? 'Error loading'
                              : '${data?.keys.length ?? 0} fields',
                      style: TextStyle(
                        color: data?['_empty'] == true || data?['_error'] != null
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    children: [
                      if (data?['_empty'] == true)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('⚠️ No documents found in this collection'),
                        )
                      else if (data?['_error'] != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '❌ Error: ${data!['_error']}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildFieldsTree(data!, 0),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFieldsTree(Map<String, dynamic> data, int indent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final indentPadding = EdgeInsets.only(left: indent * 16.0);
        
        if (entry.value == null) {
          return Padding(
            padding: indentPadding,
            child: Text('• ${entry.key}: null'),
          );
        } else if (entry.value is Map) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: indentPadding,
                child: Text(
                  '• ${entry.key}: (map)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _buildFieldsTree(entry.value as Map<String, dynamic>, indent + 1),
            ],
          );
        } else if (entry.value is List) {
          final list = entry.value as List;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: indentPadding,
                child: Text(
                  '• ${entry.key}: (array) [${list.length} items]',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (list.isNotEmpty && list[0] is Map)
                Padding(
                  padding: EdgeInsets.only(left: (indent + 1) * 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('First item:', style: TextStyle(fontStyle: FontStyle.italic)),
                      _buildFieldsTree(list[0] as Map<String, dynamic>, indent + 2),
                    ],
                  ),
                ),
            ],
          );
        } else if (entry.value is Timestamp) {
          return Padding(
            padding: indentPadding,
            child: Text('• ${entry.key}: ${(entry.value as Timestamp).toDate()} (timestamp)'),
          );
        } else {
          return Padding(
            padding: indentPadding,
            child: Text('• ${entry.key}: ${entry.value} (${entry.value.runtimeType})'),
          );
        }
      }).toList(),
    );
  }
}
