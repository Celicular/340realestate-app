import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/kyc_document.dart';
import '../models/kyc_profile.dart';

/// SECURITY NOTES FOR KYC SERVICE:
///
/// This service handles sensitive KYC (Know Your Customer) documents.
/// IMPORTANT: Ensure the following Firebase Security Rules are implemented:
///
/// 1. Firestore Security Rules for 'kyc_profiles' and 'kyc_documents':
///    - Users can only read/write their own KYC data
///    - Admin users can read all KYC data for verification
///    - Example rule:
///      ```
///      match /kyc_profiles/{userId} {
///        allow read, write: if request.auth.uid == userId;
///        allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
///      }
///      match /kyc_documents/{docId} {
///        allow read, write: if request.auth.uid == resource.data.userId;
///        allow read, update: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
///      }
///      ```
///
/// 2. Storage Security Rules for 'kyc_documents':
///    - Only authenticated users can upload to their own folder
///    - Files should be encrypted at rest (Firebase handles this automatically)
///    - Example rule:
///      ```
///      match /kyc_documents/{userId}/{document} {
///        allow read, write: if request.auth.uid == userId;
///        allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
///      }
///      ```
///
/// 3. Data Encryption:
///    - Firebase Storage encrypts data at rest automatically
///    - Use HTTPS for all transfers (handled by Firebase SDK)
///    - Consider client-side encryption for extra sensitive data
///
/// 4. Access Logging:
///    - Enable Firebase Audit Logs to track who accesses KYC data
///    - Monitor for unusual access patterns
///
/// 5. Data Retention:
///    - Consider auto-deleting documents after verification (with user consent)
///    - Implement periodic cleanup of expired KYC records
///
class KYCService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload document
  Future<String> uploadDocument(String userId, File file, DocumentType type) async {
    final fileName = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final ref = _storage.ref().child('kyc_documents/$userId/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Create/Update KYC profile
  Future<void> saveKYCProfile(KYCProfile profile) async {
    await _firestore
        .collection('kyc_profiles')
        .doc(profile.userId)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  // Get KYC profile
  Future<KYCProfile?> getKYCProfile(String userId) async {
    final doc = await _firestore.collection('kyc_profiles').doc(userId).get();
    return doc.exists ? KYCProfile.fromFirestore(doc) : null;
  }

  // Add document to Firestore
  Future<void> addDocument(KYCDocument document) async {
    await _firestore.collection('kyc_documents').add(document.toFirestore());
  }

  // Get user documents
  Future<List<KYCDocument>> getUserDocuments(String userId) async {
    final snapshot = await _firestore
        .collection('kyc_documents')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => KYCDocument.fromFirestore(doc)).toList();
  }

  // Update document status
  Future<void> updateDocumentStatus(
    String documentId,
    VerificationStatus status,
    String? reason,
  ) async {
    await _firestore.collection('kyc_documents').doc(documentId).update({
      'status': status.name,
      if (reason != null) 'rejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
