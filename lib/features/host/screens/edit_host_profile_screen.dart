import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/host_service.dart';
import '../../../core/models/host_model.dart';

class EditHostProfileScreen extends StatefulWidget {
  final HostModel? hostProfile;

  const EditHostProfileScreen({super.key, this.hostProfile});

  @override
  State<EditHostProfileScreen> createState() => _EditHostProfileScreenState();
}

class _EditHostProfileScreenState extends State<EditHostProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _propertyNameController;
  late TextEditingController _propertyAddressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _propertyNameController =
        TextEditingController(text: widget.hostProfile?.propertyName ?? '');
    _propertyAddressController =
        TextEditingController(text: widget.hostProfile?.propertyAddress ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _propertyNameController.dispose();
    _propertyAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) throw 'User not found';

      // 1. Update User Profile (Name, Phone)
      if (user.name != _nameController.text ||
          user.phone != _phoneController.text) {
        await AuthService.updateProfile(
          userId: user.id,
          name: _nameController.text,
          phone: _phoneController.text,
        );
        // Refresh local user data
        await authProvider.loadUserData();
      }

      // 2. Update/Create Host Profile (Property Name, Address)
      // Use existing ID if updating, or empty if creating new
      final hostId = widget.hostProfile?.id ?? '';

      final hostModel = HostModel(
        id: hostId,
        userId: user.id,
        propertyName: _propertyNameController.text,
        propertyAddress: _propertyAddressController.text,
        latitude: widget.hostProfile?.latitude ?? 0.0,
        longitude: widget.hostProfile?.longitude ?? 0.0,
        propertyImages: widget.hostProfile?.propertyImages ?? [],
        description: widget.hostProfile?.description,
        isVerified: widget.hostProfile?.isVerified ?? false,
        createdAt: widget.hostProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await HostService.saveHostProfile(hostModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 32),
              Text(
                'Property Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _propertyNameController,
                decoration: const InputDecoration(
                  labelText: 'Property Name (e.g. Wedding at Marriot)',
                  prefixIcon: Icon(Icons.home_work_outlined),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Property Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _propertyAddressController,
                decoration: const InputDecoration(
                  labelText: 'Property Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
