import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load profile data
      final profile = await _kycService.getKYCProfile(widget.userId);
      if (profile != null) {
        _nameController.text = profile.fullName;
        _addressController.text = profile.address;
        _cityController.text = profile.city;
      }
      
      // Load documents
      final docs = await _kycService.getUserDocuments(widget.userId);
      setState(() => _documents = docs);
    } catch (e) {
      debugPrint('Error loading KYC data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDocuments() async {
    final docs = await _kycService.getUserDocuments(widget.userId);
    setState(() => _documents = docs);
  }

  Future<void> _pickAndUploadDocument(DocumentType type) async {
    // Show dialog to choose between camera and file picker
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose from Files'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == 'camera') {
      await _captureFromCamera(type);
    } else {
      await _pickFromFiles(type);
    }
  }

  Future<void> _captureFromCamera(DocumentType type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() => _isLoading = true);
      try {
        final file = File(photo.path);
        final url = await _kycService.uploadDocument(widget.userId, file, type);

        final document = KYCDocument(
          id: '',
          userId: widget.userId,
          documentType: type,
          documentUrl: url,
          uploadedAt: DateTime.now(),
          metadata: {
            'fileName': photo.name,
            'fileSize': await file.length(),
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

  Future<void> _pickFromFiles(DocumentType type) async {
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
                    
                    // Passport Section
                    _buildDocumentSection(
                      type: DocumentType.passport,
                      label: 'Passport',
                      uploadedDoc: _documents.where((d) => d.documentType == DocumentType.passport).firstOrNull,
                    ),
                    const SizedBox(height: 16),
                    
                    // National ID Section
                    _buildDocumentSection(
                      type: DocumentType.nationalId,
                      label: 'National ID',
                      uploadedDoc: _documents.where((d) => d.documentType == DocumentType.nationalId).firstOrNull,
                    ),
                    
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

  Widget _buildDocumentSection({
    required DocumentType type,
    required String label,
    KYCDocument? uploadedDoc,
  }) {
    final hasDocument = uploadedDoc != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: hasDocument ? Colors.green.withOpacity(0.05) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDocument ? Icons.check_circle : Icons.description,
                color: hasDocument ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasDocument)
                _buildStatusBadge(uploadedDoc!.status),
            ],
          ),
          
          if (hasDocument) ...[
            const SizedBox(height: 12),
            // Document Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: uploadedDoc.documentUrl.endsWith('.pdf')
                  ? Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                            SizedBox(height: 4),
                            Text('PDF Document'),
                          ],
                        ),
                      ),
                    )
                  : Image.network(
                      uploadedDoc.documentUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Image load error: $error');
                        debugPrint('URL: ${uploadedDoc.documentUrl}');
                        return Container(
                          height: 100,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                const SizedBox(height: 4),
                                Text(
                                  'Unable to load image',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            // Uploaded info
            Text(
              'Uploaded on ${_formatDate(uploadedDoc.uploadedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // Re-upload button
            OutlinedButton.icon(
              onPressed: () => _pickAndUploadDocument(type),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Re-upload'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            // Upload button for new document
            OutlinedButton.icon(
              onPressed: () => _pickAndUploadDocument(type),
              icon: const Icon(Icons.upload_file),
              label: Text('Upload $label'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;
    
    switch (status) {
      case VerificationStatus.approved:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'Verified';
        icon = Icons.verified;
        break;
      case VerificationStatus.rejected:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'Under Verification';
        icon = Icons.hourglass_top;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
