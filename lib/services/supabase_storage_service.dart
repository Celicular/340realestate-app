
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Portfolio type for portfolio-images bucket
enum PortfolioType {
  land,       // landPortfolio folder
  residential // residentialPortfolio folder
}

class SupabaseStorageService {
  static const String _supabaseUrl = 'https://igahymbyfdfahtglpvcg.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_MdRCGAMP-LM5Qo97EYgN8A_Zzo27NGn';
  
  // Two buckets based on property type
  static const String _rentalBucket = 'rentalProperties';
  static const String _portfolioBucket = 'portfolio-images';

  static bool _isInitialized = false;
  
  /// Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _isInitialized = true;
    debugPrint('Supabase initialized successfully');
  }

  /// Get the Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  /// Pick image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  /// Pick image from camera
  static Future<XFile?> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  /// Pick multiple images from gallery
  static Future<List<XFile>> pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  /// Upload image for RENTAL property
  /// Path: rentalProperties/{propertyId}/urlUploads/{fileName}
  static Future<String?> uploadRentalPropertyImage({
    required XFile imageFile,
    required String propertyId,
    String? customFileName,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? '${propertyId}_$timestamp.$fileExt';
      final filePath = '$propertyId/urlUploads/$fileName';

      await client.storage.from(_rentalBucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      final publicUrl = client.storage
          .from(_rentalBucket)
          .getPublicUrl(filePath);

      debugPrint('Rental image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading rental image: $e');
      rethrow;
    }
  }

  /// Upload image for PORTFOLIO property (sale, villa, cottage, house, combo)
  /// Path: portfolio-images/{landPortfolio|residentialPortfolio}/{propertyId}/{fileName}
  static Future<String?> uploadPortfolioPropertyImage({
    required XFile imageFile,
    required String propertyId,
    required PortfolioType portfolioType,
    String? customFileName,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? '${propertyId}_$timestamp.$fileExt';
      
      // Determine folder based on portfolio type
      final folderName = portfolioType == PortfolioType.land 
          ? 'landPortfolio' 
          : 'residentialPortfolio';
      final filePath = '$folderName/$propertyId/$fileName';

      await client.storage.from(_portfolioBucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      final publicUrl = client.storage
          .from(_portfolioBucket)
          .getPublicUrl(filePath);

      debugPrint('Portfolio image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading portfolio image: $e');
      rethrow;
    }
  }

  /// Upload image based on property type (convenience method)
  /// Automatically routes to correct bucket
  static Future<String?> uploadPropertyImage({
    required XFile imageFile,
    required String propertyId,
    required bool isRental,
    PortfolioType portfolioType = PortfolioType.residential,
    String? customFileName,
  }) async {
    if (isRental) {
      return uploadRentalPropertyImage(
        imageFile: imageFile,
        propertyId: propertyId,
        customFileName: customFileName,
      );
    } else {
      return uploadPortfolioPropertyImage(
        imageFile: imageFile,
        propertyId: propertyId,
        portfolioType: portfolioType,
        customFileName: customFileName,
      );
    }
  }

  /// Upload multiple images for rental property
  static Future<List<String>> uploadMultipleRentalImages({
    required List<XFile> imageFiles,
    required String propertyId,
  }) async {
    final urls = <String>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadRentalPropertyImage(
        imageFile: imageFiles[i],
        propertyId: propertyId,
        customFileName: '${propertyId}_${i}_${DateTime.now().millisecondsSinceEpoch}.${imageFiles[i].path.split('.').last}',
      );
      if (url != null) {
        urls.add(url);
      }
    }
    
    return urls;
  }

  /// Upload multiple images for portfolio property
  static Future<List<String>> uploadMultiplePortfolioImages({
    required List<XFile> imageFiles,
    required String propertyId,
    required PortfolioType portfolioType,
  }) async {
    final urls = <String>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadPortfolioPropertyImage(
        imageFile: imageFiles[i],
        propertyId: propertyId,
        portfolioType: portfolioType,
        customFileName: '${propertyId}_${i}_${DateTime.now().millisecondsSinceEpoch}.${imageFiles[i].path.split('.').last}',
      );
      if (url != null) {
        urls.add(url);
      }
    }
    
    return urls;
  }

  /// Upload multiple images (convenience method)
  static Future<List<String>> uploadMultipleImages({
    required List<XFile> imageFiles,
    required String propertyId,
    required bool isRental,
    PortfolioType portfolioType = PortfolioType.residential,
  }) async {
    if (isRental) {
      return uploadMultipleRentalImages(
        imageFiles: imageFiles,
        propertyId: propertyId,
      );
    } else {
      return uploadMultiplePortfolioImages(
        imageFiles: imageFiles,
        propertyId: propertyId,
        portfolioType: portfolioType,
      );
    }
  }

  /// Delete image from rental bucket
  static Future<bool> deleteRentalPropertyImage({
    required String propertyId,
    required String fileName,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final filePath = '$propertyId/urlUploads/$fileName';
      await client.storage.from(_rentalBucket).remove([filePath]);
      debugPrint('Rental image deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting rental image: $e');
      return false;
    }
  }

  /// Delete image from portfolio bucket
  static Future<bool> deletePortfolioPropertyImage({
    required String propertyId,
    required String fileName,
    required PortfolioType portfolioType,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final folderName = portfolioType == PortfolioType.land 
          ? 'landPortfolio' 
          : 'residentialPortfolio';
      final filePath = '$folderName/$propertyId/$fileName';
      await client.storage.from(_portfolioBucket).remove([filePath]);
      debugPrint('Portfolio image deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting portfolio image: $e');
      return false;
    }
  }

  /// Delete all images for a rental property
  static Future<bool> deleteAllRentalPropertyImages(String propertyId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final folderPath = '$propertyId/urlUploads';
      final files = await client.storage.from(_rentalBucket).list(path: folderPath);
      
      if (files.isNotEmpty) {
        final filePaths = files.map((f) => '$folderPath/${f.name}').toList();
        await client.storage.from(_rentalBucket).remove(filePaths);
      }
      
      debugPrint('All rental images deleted for property: $propertyId');
      return true;
    } catch (e) {
      debugPrint('Error deleting rental property images: $e');
      return false;
    }
  }

  /// Delete all images for a portfolio property
  static Future<bool> deleteAllPortfolioPropertyImages({
    required String propertyId,
    required PortfolioType portfolioType,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final folderName = portfolioType == PortfolioType.land 
          ? 'landPortfolio' 
          : 'residentialPortfolio';
      final folderPath = '$folderName/$propertyId';
      final files = await client.storage.from(_portfolioBucket).list(path: folderPath);
      
      if (files.isNotEmpty) {
        final filePaths = files.map((f) => '$folderPath/${f.name}').toList();
        await client.storage.from(_portfolioBucket).remove(filePaths);
      }
      
      debugPrint('All portfolio images deleted for property: $propertyId');
      return true;
    } catch (e) {
      debugPrint('Error deleting portfolio property images: $e');
      return false;
    }
  }
}
