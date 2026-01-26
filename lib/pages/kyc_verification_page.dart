import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/kyc_service.dart';
import '../services/push_notification_service.dart';
import '../models/kyc_document.dart';
import '../models/kyc_profile.dart';

class KYCVerificationPage extends StatefulWidget {
  final String userId;

  const KYCVerificationPage({super.key, required this.userId});

  @override
  State<KYCVerificationPage> createState() => _KYCVerificationPageState();
}

class _KYCVerificationPageState extends State<KYCVerificationPage> {
  final _kycService = KYCService();
  final _notificationService = PushNotificationService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = false;
  List<KYCDocument> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _kycService.getUserDocuments(widget.userId);
    setState(() => _documents = docs);
  }

  Future<void> _pickAndUploadDocument(DocumentType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final file = File(result.files.single.path!);
        final url = await _kycService.uploadDocument(widget.userId, file, type);

        final document = KYCDocument(
          id: '',
          userId: widget.userId,
          documentType: type,
          documentUrl: url,
          uploadedAt: DateTime.now(),
          metadata: {
            'fileName': result.files.single.name,
            'fileSize': result.files.single.size,
          },
        );

        await _kycService.addDocument(document);
        await _loadDocuments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final profile = KYCProfile(
        userId: widget.userId,
        fullName: _nameController.text,
        dateOfBirth: DateTime.now(),
        address: _addressController.text,
        city: _cityController.text,
        state: '',
        zipCode: '',
        country: 'USA',
        createdAt: DateTime.now(),
      );

      await _kycService.saveKYCProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Documents',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildDocumentButton(DocumentType.passport, 'Upload Passport'),
                    const SizedBox(height: 8),
                    _buildDocumentButton(DocumentType.nationalId, 'Upload National ID'),
                    const SizedBox(height: 16),
                    if (_documents.isNotEmpty) ...[
                      const Text('Uploaded Documents:'),
                      ..._documents.map((doc) => ListTile(
                            title: Text(doc.documentTypeDisplay),
                            subtitle: Text(doc.statusDisplay),
                            trailing: Icon(
                              doc.status == VerificationStatus.approved
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: doc.status == VerificationStatus.approved
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          )),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Submit for Review'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDocumentButton(DocumentType type, String label) {
    return OutlinedButton.icon(
      onPressed: () => _pickAndUploadDocument(type),
      icon: const Icon(Icons.upload_file),
      label: Text(label),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
