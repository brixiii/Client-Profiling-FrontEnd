import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';

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
  final _addressController = TextEditingController();

  String? _selectedRole;
  bool _obscurePassword = true;

  final List<String> _roles = ['Super Admin', 'Admin', 'Salesperson', 'Technician'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
            ),
            const SizedBox(height: 14),

            // Username
            _buildLabel('Username'),
            _buildTextField(
              controller: _usernameController,
              hint: 'Enter Username',
            ),
            const SizedBox(height: 14),

            // Phone No.
            _buildLabel('Phone No.'),
            _buildTextField(
              controller: _phoneController,
              hint: '09XX-XXX-XXXX',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            // Email Address
            _buildLabel('Email Address'),
            _buildTextField(
              controller: _emailController,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Password
            _buildLabel('Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
              decoration: _inputDecoration('Enter your Password').copyWith(
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

            // Role dropdown
            _buildLabel('Role'),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              hint: const Text('Select Role',
                  style: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD))),
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v),
              validator: (v) => v == null ? 'Please select a role' : null,
              decoration: _inputDecoration(null),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Address
            _buildLabel('Address'),
            _buildTextField(
              controller: _addressController,
              hint: 'Enter your Address',
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Register Admin button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
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
                child: const Text('Register Admin'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: wire to backend when ready
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin registered successfully')),
      );
      Navigator.pop(context);
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'This field is required' : null
          : null,
      decoration: _inputDecoration(hint),
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
