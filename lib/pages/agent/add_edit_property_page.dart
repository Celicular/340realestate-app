import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/property_service.dart';
import '../../models/property.dart';
import '../../widgets/map_location_picker.dart';

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
  late TextEditingController _imageUrlController;

  bool _isLoading = false;
  String _selectedStatus = 'published';
  PropertyType _selectedType = PropertyType.house;
  double? _latitude;
  double? _longitude;
  String _locationAddress = '';

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
    _imageUrlController = TextEditingController(text: widget.property?.imageUrl ?? '');
    
    if (widget.property != null) {
      _selectedStatus = widget.property!.status;
      _selectedType = widget.property!.type;
      _latitude = widget.property!.latitude;
      _longitude = widget.property!.longitude;
      if (widget.property!.location.isNotEmpty) {
        _locationAddress = widget.property!.location;
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
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.agentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent ID is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final propertyService = PropertyService();
      
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
          'imageUrl': _imageUrlController.text.trim(),
          'status': _selectedStatus,
          'type': _selectedType.name,
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property updated successfully')),
          );
          Navigator.of(context).pop(true);
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
          imageUrl: _imageUrlController.text.trim(),
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
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL *',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
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
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
