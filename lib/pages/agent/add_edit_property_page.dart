import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/property_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../models/property.dart';
import '../../widgets/map_location_picker.dart';
import 'agent_navigation.dart';

class AddEditPropertyPage extends StatefulWidget {
  final String? agentId;
  final Property? property; // For editing

  const AddEditPropertyPage({
    super.key,
    this.agentId,
    this.property,
  });

  @override
  State<AddEditPropertyPage> createState() => _AddEditPropertyPageState();
}

class _AddEditPropertyPageState extends State<AddEditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _sqftController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _selectedStatus = 'published';
  PropertyType _selectedType = PropertyType.house;
  double? _latitude;
  double? _longitude;
  String _locationAddress = '';
  
  // Image handling
  List<XFile> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  String? _mainImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property?.name ?? '');
    _descriptionController = TextEditingController(text: widget.property?.description ?? '');
    _locationController = TextEditingController(text: widget.property?.location ?? '');
    _priceController = TextEditingController(
      text: widget.property?.price.toString() ?? '',
    );
    _bedroomsController = TextEditingController(
      text: widget.property?.bedrooms.toString() ?? '',
    );
    _bathroomsController = TextEditingController(
      text: widget.property?.bathrooms.toString() ?? '',
    );
    _sqftController = TextEditingController(
      text: widget.property?.sqft.toString() ?? '',
    );
    
    if (widget.property != null) {
      _selectedStatus = widget.property!.status;
      _selectedType = widget.property!.type;
      _latitude = widget.property!.latitude;
      _longitude = widget.property!.longitude;
      if (widget.property!.location.isNotEmpty) {
        _locationAddress = widget.property!.location;
      }
      // Load existing image if present
      if (widget.property!.imageUrl.isNotEmpty) {
        _mainImageUrl = widget.property!.imageUrl;
        _uploadedImageUrls = [widget.property!.imageUrl];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _sqftController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      XFile? image;
      if (source == ImageSource.gallery) {
        image = await SupabaseStorageService.pickImageFromGallery();
      } else {
        image = await SupabaseStorageService.pickImageFromCamera();
      }
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final images = await SupabaseStorageService.pickMultipleImages();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeUploadedImage(int index) {
    setState(() {
      final removedUrl = _uploadedImageUrls.removeAt(index);
      if (_mainImageUrl == removedUrl && _uploadedImageUrls.isNotEmpty) {
        _mainImageUrl = _uploadedImageUrls.first;
      } else if (_uploadedImageUrls.isEmpty) {
        _mainImageUrl = null;
      }
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose Multiple Images'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.agentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent ID is required')),
      );
      return;
    }

    // Check if at least one image is available
    if (_selectedImages.isEmpty && _uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one property image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final propertyService = PropertyService();
      
      // Generate a temporary property ID for new properties
      final tempPropertyId = widget.property?.id ?? 
          'prop_${DateTime.now().millisecondsSinceEpoch}';
      
      // Upload new images to Supabase
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploadingImage = true);
        
        // NOTE: Using rentalProperties bucket for ALL property types
        // because portfolio-images bucket has restrictive RLS policies
        // To use portfolio-images, update the bucket's RLS policies in Supabase
        const isRental = true; // Force rental bucket for now
        
        for (final image in _selectedImages) {
          final url = await SupabaseStorageService.uploadPropertyImage(
            imageFile: image,
            propertyId: tempPropertyId,
            isRental: isRental,
            // For non-rental properties, default to residential portfolio
            portfolioType: PortfolioType.residential,
          );
          if (url != null) {
            _uploadedImageUrls.add(url);
          }
        }
        
        setState(() => _isUploadingImage = false);
      }
      
      // Set main image URL
      final imageUrl = _uploadedImageUrls.isNotEmpty 
          ? _uploadedImageUrls.first 
          : '';
      
      if (widget.property != null) {
        // Update existing property
        await propertyService.updateProperty(widget.property!.id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationAddress.isNotEmpty 
              ? _locationAddress 
              : _locationController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'bedrooms': int.parse(_bedroomsController.text.trim()),
          'bathrooms': int.parse(_bathroomsController.text.trim()),
          'sqft': int.parse(_sqftController.text.trim()),
          'imageUrl': imageUrl,
          'images': _uploadedImageUrls,
          'status': _selectedStatus,
          'type': _selectedType.name,
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property updated successfully')),
          );
          // Navigate back to agent portal explicitly
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AgentNavigation()),
            (route) => false,
          );
        }
      } else {
        // Create new property
        final property = Property(
          id: '', // Will be set by Firestore
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationAddress.isNotEmpty
              ? _locationAddress
              : _locationController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          bedrooms: int.parse(_bedroomsController.text.trim()),
          bathrooms: int.parse(_bathroomsController.text.trim()),
          sqft: int.parse(_sqftController.text.trim()),
          images: _uploadedImageUrls,
          amenities: [],
          type: _selectedType,
          status: _selectedStatus,
          agentId: widget.agentId,
          createdBy: widget.agentId,
          latitude: _latitude,
          longitude: _longitude,
        );

        await propertyService.createProperty(property);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property created successfully')),
          );
          // Navigate back to agent portal explicitly
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AgentNavigation()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialAddress: _locationAddress.isNotEmpty 
              ? _locationAddress 
              : _locationController.text.trim(),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationAddress = result['address'] ?? '';
        if (_locationAddress.isNotEmpty) {
          _locationController.text = _locationAddress;
        }
      });
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Property Images *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Image'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Show uploaded images
        if (_uploadedImageUrls.isNotEmpty) ...[
          Text(
            'Uploaded Images',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedImageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _uploadedImageUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeUploadedImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Main',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Show selected (not yet uploaded) images
        if (_selectedImages.isNotEmpty) ...[
          Text(
            'New Images (will be uploaded)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeSelectedImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Empty state
        if (_uploadedImageUrls.isEmpty && _selectedImages.isEmpty)
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[400]!,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add property images',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.property != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Property' : 'Add Property'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              _buildImageSection(),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Property Name *',
                  hintText: 'Modern Luxury Villa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe the property...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  hintText: 'City, State',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: _openMapPicker,
                    tooltip: 'Pick location on map',
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price *',
                  hintText: '500000',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bedroomsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bedrooms *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bathrooms *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _sqftController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Square Feet *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<PropertyType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Property Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                items: PropertyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProperty,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploadingImage 
                                  ? 'Uploading Images...' 
                                  : 'Saving...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isEditing ? 'Update Property' : 'Create Property',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

