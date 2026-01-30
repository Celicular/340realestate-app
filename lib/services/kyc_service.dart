import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/kyc_document.dart';
import '../models/kyc_profile.dart';

/// KYC Service using Supabase for both storage and database
/// 
/// Required Supabase tables:
/// 
/// CREATE TABLE kyc_profiles (
///   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///   user_id TEXT UNIQUE NOT NULL,
///   full_name TEXT,
///   date_of_birth DATE,
///   address TEXT,
///   city TEXT,
///   state TEXT,
///   zip_code TEXT,
///   country TEXT,
///   created_at TIMESTAMPTZ DEFAULT NOW(),
///   updated_at TIMESTAMPTZ DEFAULT NOW()
/// );
/// 
/// CREATE TABLE kyc_documents (
///   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
///   user_id TEXT NOT NULL,
///   document_type TEXT NOT NULL,
///   document_url TEXT NOT NULL,
///   status TEXT DEFAULT 'pending',
///   rejection_reason TEXT,
///   uploaded_at TIMESTAMPTZ DEFAULT NOW(),
///   reviewed_at TIMESTAMPTZ,
///   metadata JSONB
/// );
///
class KYCService {
  // Supabase storage bucket name (must match exactly)
  static const String _kycBucket = 'kyc doc';

  // Get Supabase client
  SupabaseClient get _supabase => Supabase.instance.client;

  // Upload document using Supabase Storage
  Future<String> uploadDocument(String userId, File file, DocumentType type) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${type.name}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      debugPrint('📤 KYC Upload: bucket=$_kycBucket, path=$filePath');

      // Read file bytes
      final bytes = await file.readAsBytes();
      debugPrint('📤 KYC Upload: file size=${bytes.length} bytes');

      // Upload to Supabase Storage
      await _supabase.storage.from(_kycBucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileExt),
          upsert: true,
        ),
      );

      debugPrint('📤 KYC Upload: upload successful');

      // Get public URL
      final publicUrl = _supabase.storage.from(_kycBucket).getPublicUrl(filePath);
      debugPrint('📤 KYC Upload: publicUrl=$publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ KYC Upload Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  // Get content type based on file extension
  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // Create/Update KYC profile using Supabase
  Future<void> saveKYCProfile(KYCProfile profile) async {
    try {
      await _supabase.from('kyc_profiles').upsert({
        'user_id': profile.userId,
        'full_name': profile.fullName,
        'date_of_birth': profile.dateOfBirth.toIso8601String(),
        'address': profile.address,
        'city': profile.city,
        'state': profile.state,
        'zip_code': profile.zipCode,
        'country': profile.country,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error saving KYC profile: $e');
      rethrow;
    }
  }

  // Get KYC profile from Supabase
  Future<KYCProfile?> getKYCProfile(String userId) async {
    try {
      final response = await _supabase
          .from('kyc_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return KYCProfile(
        userId: response['user_id'] ?? '',
        fullName: response['full_name'] ?? '',
        dateOfBirth: DateTime.tryParse(response['date_of_birth'] ?? '') ?? DateTime.now(),
        address: response['address'] ?? '',
        city: response['city'] ?? '',
        state: response['state'] ?? '',
        zipCode: response['zip_code'] ?? '',
        country: response['country'] ?? '',
        createdAt: DateTime.tryParse(response['created_at'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error getting KYC profile: $e');
      return null;
    }
  }

  // Add document to Supabase
  Future<void> addDocument(KYCDocument document) async {
    try {
      await _supabase.from('kyc_documents').insert({
        'user_id': document.userId,
        'document_type': document.documentType.name,
        'document_url': document.documentUrl,
        'status': document.status.name,
        'uploaded_at': document.uploadedAt.toIso8601String(),
        'metadata': document.metadata,
      });
    } catch (e) {
      debugPrint('Error adding KYC document: $e');
      rethrow;
    }
  }

  // Get user documents from Supabase
  Future<List<KYCDocument>> getUserDocuments(String userId) async {
    try {
      final response = await _supabase
          .from('kyc_documents')
          .select()
          .eq('user_id', userId)
          .order('uploaded_at', ascending: false);
      
      return (response as List).map((doc) {
        return KYCDocument(
          id: doc['id'] ?? '',
          userId: doc['user_id'] ?? '',
          documentType: DocumentType.values.firstWhere(
            (e) => e.name == doc['document_type'],
            orElse: () => DocumentType.other,
          ),
          documentUrl: doc['document_url'] ?? '',
          status: VerificationStatus.values.firstWhere(
            (e) => e.name == doc['status'],
            orElse: () => VerificationStatus.pending,
          ),
          uploadedAt: DateTime.tryParse(doc['uploaded_at'] ?? '') ?? DateTime.now(),
          reviewedAt: doc['reviewed_at'] != null 
              ? DateTime.tryParse(doc['reviewed_at']) 
              : null,
          rejectionReason: doc['rejection_reason'],
          metadata: doc['metadata'] != null 
              ? Map<String, dynamic>.from(doc['metadata']) 
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting KYC documents: $e');
      return [];
    }
  }

  // Update document status
  Future<void> updateDocumentStatus(
    String documentId,
    VerificationStatus status,
    String? reason,
  ) async {
    try {
      await _supabase.from('kyc_documents').update({
        'status': status.name,
        if (reason != null) 'rejection_reason': reason,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);
    } catch (e) {
      debugPrint('Error updating document status: $e');
      rethrow;
    }
  }
}

