import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _emailSynced = false;
  // removed flag; prefill logic uses fill-if-empty in build

  @override
  void initState() {
    super.initState();
    final userProfile =
        Provider.of<AuthProvider>(context, listen: false).userProfile;
    final authUser = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(
      text: (userProfile?.name.isNotEmpty ?? false)
          ? (userProfile?.name ?? '')
          : ((userProfile?.displayName.isNotEmpty ?? false)
              ? (userProfile?.displayName ?? '')
              : (authUser?.displayName ?? '')),
    );
    _emailController = TextEditingController(
      text: userProfile?.email ?? authUser?.email ?? '',
    );
    _phoneController =
        TextEditingController(text: userProfile?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      final success = await authProvider.updateProfile({
        'displayName': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      });

      if (!context.mounted) return;

      if (success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        nav.pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;
    final authUser = authProvider.user;

    final currentName = _nameController.text.trim();
    final currentEmail = _emailController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final candidateName = (userProfile != null && userProfile.name.isNotEmpty)
        ? userProfile.name
        : ((userProfile != null && userProfile.displayName.isNotEmpty)
            ? userProfile.displayName
            : (authUser?.displayName ?? ''));
    final candidateEmail = (authUser?.email?.isNotEmpty ?? false)
        ? (authUser?.email ?? '')
        : (userProfile?.email ?? '');
    final candidatePhone =
        userProfile?.phoneNumber ?? authUser?.phoneNumber ?? '';

    if (currentName.isEmpty && candidateName.isNotEmpty) {
      _nameController.text = candidateName;
    }
    if (candidateEmail.isNotEmpty && currentEmail != candidateEmail) {
      _emailController.text = candidateEmail;
    }
    if (currentPhone.isEmpty && candidatePhone.isNotEmpty) {
      _phoneController.text = candidatePhone;
    }

    if (!_emailSynced && (authUser?.email?.isNotEmpty ?? false)) {
      final authEmail = authUser!.email!;
      final profileEmail = userProfile?.email ?? '';
      if (authEmail != profileEmail) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<AuthProvider>(context, listen: false)
              .updateProfile({'email': authEmail});
        });
      }
      _emailSynced = true;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Form Fields
                _buildTextField(
                  context,
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildTextField(
                  context,
                  controller: _emailController,
                  label: 'Email',
                  hint: '',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true, // Email update usually requires more steps
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildTextField(
                  context,
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+1 234 567 8900',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                // Removed Address field as it's not in the User model

                const SizedBox(height: AppTheme.spacingXLarge),
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _saveProfile,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.textSecondary),
            filled: true,
            fillColor: readOnly
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              borderSide: BorderSide(
                color: AppTheme.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              borderSide: BorderSide(
                color: AppTheme.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Removed photo change feature
}
