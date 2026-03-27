import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/models/user.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/api_exception.dart';

class EditAdminScreen extends StatefulWidget {
  final User user;

  const EditAdminScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditAdminScreen> createState() => _EditAdminScreenState();
}

class _EditAdminScreenState extends State<EditAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  String? _selectedRole;
  Map<String, String?> _apiErrors = {};

  final List<String> _roles = ['Super Admin', 'Admin'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstname);
    _middleNameController = TextEditingController(text: widget.user.middlename);
    _lastNameController = TextEditingController(text: widget.user.surname);
    _usernameController = TextEditingController(text: widget.user.username);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
    _addressController = TextEditingController(text: widget.user.address);
    _selectedRole = widget.user.role.isNotEmpty ? widget.user.role : null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
            Text(
              'Edit ${widget.user.role}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('First Name'),
            _buildTextField(
              controller: _firstNameController,
              apiError: _apiErrors['firstname'],
              onClearError: () => setState(() => _apiErrors.remove('firstname')),
            ),
            const SizedBox(height: 14),

            _buildLabel('Middle Name'),
            _buildTextField(controller: _middleNameController, required: false),
            const SizedBox(height: 14),

            _buildLabel('Last Name'),
            _buildTextField(
              controller: _lastNameController,
              apiError: _apiErrors['surname'],
              onClearError: () => setState(() => _apiErrors.remove('surname')),
            ),
            const SizedBox(height: 14),

            _buildLabel('Username'),
            _buildTextField(
              controller: _usernameController,
              apiError: _apiErrors['username'],
              onClearError: () => setState(() => _apiErrors.remove('username')),
            ),
            const SizedBox(height: 14),

            _buildLabel('Phone No.'),
            _buildTextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              apiError: _apiErrors['phone'],
              onClearError: () => setState(() => _apiErrors.remove('phone')),
            ),
            const SizedBox(height: 14),

            _buildLabel('Email Address'),
            _buildTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              apiError: _apiErrors['email'],
              onClearError: () => setState(() => _apiErrors.remove('email')),
            ),
            const SizedBox(height: 14),

            _buildLabel('Role'),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedRole = v;
                _apiErrors.remove('role');
              }),
              validator: (v) => v == null ? 'Please select a role' : null,
              decoration: _inputDecoration().copyWith(errorText: _apiErrors['role']),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            _buildLabel('Address'),
            _buildTextField(
              controller: _addressController,
              maxLines: 2,
              apiError: _apiErrors['address'],
              onClearError: () => setState(() => _apiErrors.remove('address')),
            ),
            const SizedBox(height: 32),

            // Update Admin button
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
                    : const Text('Update Admin'),
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
      await BackendApi().updateUser(
        id: widget.user.id,
        payload: {
          'firstname': _firstNameController.text.trim(),
          'middlename': _middleNameController.text.trim(),
          'surname': _lastNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'address': _addressController.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin updated successfully')),
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
        const SnackBar(content: Text('Failed to update. Please try again.')),
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
      decoration: _inputDecoration().copyWith(errorText: apiError),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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
