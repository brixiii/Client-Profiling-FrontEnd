import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/api_exception.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({Key? key}) : super(key: key);

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;
  Map<String, String?> _apiErrors = {};

  final _api = BackendApi();
  final List<String> _roles = ['Super Admin', 'Admin'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Admin',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Heading
            const Text(
              'Add Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // First Name
            _buildLabel('First Name'),
            _buildTextField(
              controller: _firstNameController,
              hint: 'Enter First Name',
              apiError: _apiErrors['firstname'],
              onClearError: () => setState(() => _apiErrors.remove('firstname')),
            ),
            const SizedBox(height: 14),

            // Middle Name
            _buildLabel('Middle Name'),
            _buildTextField(
              controller: _middleNameController,
              hint: 'Enter Middle Name (Optional)',
              required: false,
            ),
            const SizedBox(height: 14),

            // Last Name
            _buildLabel('Last Name'),
            _buildTextField(
              controller: _lastNameController,
              hint: 'Enter Last Name',
              apiError: _apiErrors['surname'],
              onClearError: () => setState(() => _apiErrors.remove('surname')),
            ),
            const SizedBox(height: 14),

            // Username
            _buildLabel('Username'),
            _buildTextField(
              controller: _usernameController,
              hint: 'Enter Username',
              apiError: _apiErrors['username'],
              onClearError: () => setState(() => _apiErrors.remove('username')),
            ),
            const SizedBox(height: 14),

            // Phone No.
            _buildLabel('Phone No.'),
            _buildTextField(
              controller: _phoneController,
              hint: '09XX-XXX-XXXX',
              keyboardType: TextInputType.phone,
              apiError: _apiErrors['phone'],
              onClearError: () => setState(() => _apiErrors.remove('phone')),
            ),
            const SizedBox(height: 14),

            // Email Address
            _buildLabel('Email Address'),
            _buildTextField(
              controller: _emailController,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              apiError: _apiErrors['email'],
              onClearError: () => setState(() => _apiErrors.remove('email')),
            ),
            const SizedBox(height: 14),

            // Password
            _buildLabel('Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() => _apiErrors.remove('password')),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
              decoration: _inputDecoration('Enter your Password').copyWith(
                errorText: _apiErrors['password'],
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Confirm Password
            _buildLabel('Confirm Password'),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onChanged: (_) => setState(() => _apiErrors.remove('password_confirmation')),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
              decoration: _inputDecoration('Re-enter your Password').copyWith(
                errorText: _apiErrors['password_confirmation'],
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Role dropdown
            _buildLabel('Role'),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              hint: const Text('Select Role',
                  style: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD))),
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedRole = v;
                _apiErrors.remove('role');
              }),
              validator: (v) => v == null ? 'Please select a role' : null,
              decoration: _inputDecoration(null).copyWith(errorText: _apiErrors['role']),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Address
            _buildLabel('Address'),
            _buildTextField(
              controller: _addressController,
              hint: 'Enter your Address',
              maxLines: 2,
              apiError: _apiErrors['address'],
              onClearError: () => setState(() => _apiErrors.remove('address')),
            ),
            const SizedBox(height: 32),

            // Register Admin button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register Admin'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _api.createUser({
        'firstname': _firstNameController.text.trim(),
        'middlename': _middleNameController.text.trim(),
        'surname': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
        'role': _selectedRole,
        'address': _addressController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin registered successfully')),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fieldErrors.isNotEmpty) {
        setState(() => _apiErrors = Map.from(e.fieldErrors));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to register admin. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
    String? apiError,
    VoidCallback? onClearError,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onClearError != null ? (_) => onClearError() : null,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'This field is required' : null
          : null,
      decoration: _inputDecoration(hint).copyWith(errorText: apiError),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}