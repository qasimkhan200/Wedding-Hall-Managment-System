import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_widgets.dart';
import '../widgets/auth_text_field.dart';
import 'login_screen.dart';
import '../../host/screens/host_main_screen.dart';
import '../../vendor/screens/vendor_main_screen.dart';
import '../../rider/screens/rider_main_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../admin/screens/admin_main_screen.dart';

class RoleBasedRegisterScreen extends StatefulWidget {
  final String role;

  const RoleBasedRegisterScreen({super.key, required this.role});

  @override
  State<RoleBasedRegisterScreen> createState() =>
      _RoleBasedRegisterScreenState();
}

class _RoleBasedRegisterScreenState extends State<RoleBasedRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // Vendor specific fields
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  File? _cnicImage;
  File? _logoImage;
  File? _coverImage;
  final _categoryController = TextEditingController(); // Simplified for now

  // Rider specific fields
  String _vehicleType = 'bike';
  final _vehicleNumberController = TextEditingController();
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Vendor
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    // Rider
    _vehicleNumberController.dispose();
    super.dispose();
  }

  String get _roleTitle {
    switch (widget.role) {
      case AppConstants.roleHost:
        return 'Host';
      case AppConstants.roleVendor:
        return 'Vendor';
      case AppConstants.roleRider:
        return 'Rider';
      case AppConstants.roleAdmin:
        return 'Admin';
      default:
        return 'User';
    }
  }

  String get _roleIcon {
    switch (widget.role) {
      case AppConstants.roleHost:
        return '👰';
      case AppConstants.roleVendor:
        return '🏪';
      case AppConstants.roleRider:
        return '🛵';
      case AppConstants.roleAdmin:
        return '👨‍💼';
      default:
        return '👤';
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'cnic':
            _cnicImage = File(image.path);
            break;
          case 'logo':
            _logoImage = File(image.path);
            break;
          case 'cover':
            _coverImage = File(image.path);
            break;
          case 'license':
            _licenseImage = File(image.path);
            break;
        }
      });
    }
  }

  Widget _buildImagePicker(String label, File? imageFile, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _pickImage(type),
          child: Container(
            height: 150.h,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.grey.shade50,
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 40.sp, color: AppColors.primary),
                      SizedBox(height: 8.h),
                      Text('Tap to upload',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildVendorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: _businessNameController,
          label: 'Business Name',
          hint: 'Enter business name',
          prefixIcon: Icons.store_outlined,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter business name' : null,
        ),
        SizedBox(height: ResponsiveUtils.mdHeight),
        AuthTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Brief description of your business',
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter description' : null,
        ),
        SizedBox(height: ResponsiveUtils.mdHeight),
        AuthTextField(
          controller: _addressController,
          label: 'Business Address',
          hint: 'Enter your business address',
          prefixIcon: Icons.location_on_outlined,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter address' : null,
        ),
        SizedBox(height: ResponsiveUtils.mdHeight),
        AuthTextField(
          controller: _categoryController,
          label: 'Category',
          hint: 'e.g., Groceries, Pharmacy',
          prefixIcon: Icons.category_outlined,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a category' : null,
        ),
        SizedBox(height: ResponsiveUtils.mdHeight),
        _buildImagePicker('CNIC Image', _cnicImage, 'cnic'),
        _buildImagePicker('Business Logo', _logoImage, 'logo'),
        _buildImagePicker('Cover Image', _coverImage, 'cover'),
      ],
    );
  }

  Widget _buildRiderFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _vehicleType,
          items: ['bike', 'car', 'van']
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _vehicleType = val!),
          decoration: InputDecoration(
            labelText: 'Vehicle Type',
            prefixIcon: const Icon(Icons.directions_bike),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.mdHeight),
        AuthTextField(
          controller: _vehicleNumberController,
          label: 'Vehicle Number',
          hint: 'Enter vehicle registration number',
          prefixIcon: Icons.confirmation_number_outlined,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter vehicle number' : null,
        ),
        SizedBox(height: ResponsiveUtils.mdHeight),
        _buildImagePicker('CNIC Image', _cnicImage, 'cnic'),
        _buildImagePicker('License Image', _licenseImage, 'license'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: AppColors.textPrimary), // Ensure back button is visible
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.paddingXl,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ResponsiveText(
                    _roleIcon,
                    style:
                        TextStyle(fontSize: ResponsiveUtils.headline1 + 10.sp),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.mdHeight),
                ResponsiveText(
                  '$_roleTitle Registration',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                // DEBUG: Remove before production
                // Center(child: Text('Debug Role: ${widget.role}', style: TextStyle(color: Colors.red))),
                SizedBox(height: ResponsiveUtils.smHeight),
                ResponsiveText(
                  'Create your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                SizedBox(height: ResponsiveUtils.xlHeight),
                AuthTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.mdHeight),
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.mdHeight),
                AuthTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.mdHeight),
                SizedBox(height: ResponsiveUtils.mdHeight),
                // Role Specific Fields
                Builder(
                  builder: (context) {
                    final normalizedRole = widget.role.trim().toLowerCase();
                    if (normalizedRole == AppConstants.roleVendor) {
                      return _buildVendorFields();
                    } else if (normalizedRole == AppConstants.roleRider) {
                      return _buildRiderFields();
                    }
                    return const SizedBox.shrink();
                  },
                ),
                SizedBox(height: ResponsiveUtils.mdHeight),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.mdHeight),
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: ResponsiveUtils.mdHeight),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.xlHeight),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ResponsiveButton(
                      text: 'Register',
                      onPressed: authProvider.isLoading || !_agreeToTerms
                          ? null
                          : _handleRegister,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                SizedBox(height: ResponsiveUtils.xlHeight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ResponsiveText(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                RoleBasedLoginScreen(role: widget.role),
                          ),
                        );
                      },
                      child: ResponsiveText(
                        'Login',
                        style: TextStyle(fontSize: ResponsiveUtils.body2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final normalizedRole = widget.role.trim().toLowerCase();

    // Prevent admin registration through UI
    if (normalizedRole == AppConstants.roleAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Admin accounts cannot be created through registration. Please contact system administrator.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Role-specific validation
    if (normalizedRole == AppConstants.roleVendor) {
      if (_cnicImage == null) {
        _showSnackBar('Please upload CNIC image');
        return;
      }
      if (_logoImage == null) {
        _showSnackBar('Please upload Business Logo');
        return;
      }
      // Cover image optional
    } else if (normalizedRole == AppConstants.roleRider) {
      if (_cnicImage == null) {
        _showSnackBar('Please upload CNIC image');
        return;
      }
      if (_licenseImage == null) {
        _showSnackBar('Please upload License image');
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    bool success = false;

    if (normalizedRole == AppConstants.roleVendor) {
      success = await authProvider.registerVendor(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        businessName: _businessNameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        categories: _categoryController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        cnicImage: _cnicImage,
        logoImage: _logoImage,
        coverImage: _coverImage,
      );
    } else if (normalizedRole == AppConstants.roleRider) {
      success = await authProvider.registerRider(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleType: _vehicleType,
        vehicleNumber: _vehicleNumberController.text.trim(),
        cnicImage: _cnicImage,
        licenseImage: _licenseImage,
      );
    } else {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: widget.role,
      );
    }

    if (success && mounted) {
      // Show appropriate message based on role
      if (normalizedRole == AppConstants.roleVendor ||
          normalizedRole == AppConstants.roleRider) {
        // Vendor/Rider need approval
        _showPendingApprovalDialog();
      } else {
        // Host can proceed directly
        _navigateToHome();
      }
    } else if (mounted && authProvider.error != null) {
      _showSnackBar(authProvider.error!);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Text(
          'Your ${_roleTitle.toLowerCase()} account has been created successfully.\n\n'
          'Your account is pending admin approval. You will be able to login once an admin approves your account.\n\n'
          'You will receive a notification once approved.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => RoleBasedLoginScreen(role: widget.role)),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Widget screen;
    switch (widget.role) {
      case AppConstants.roleHost:
        screen = const HostMainScreen();
        break;
      case AppConstants.roleVendor:
        screen = const VendorMainScreen();
        break;
      case AppConstants.roleRider:
        screen = const RiderMainScreen();
        break;
      case AppConstants.roleAdmin:
        screen = const AdminMainScreen();
        break;
      default:
        screen = const HostMainScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
