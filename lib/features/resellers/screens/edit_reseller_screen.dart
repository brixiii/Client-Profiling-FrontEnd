import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditResellerScreen extends StatefulWidget {
  final Map<String, String> reseller;

  const EditResellerScreen({Key? key, required this.reseller}) : super(key: key);

  @override
  State<EditResellerScreen> createState() => _EditResellerScreenState();
}

class _EditResellerScreenState extends State<EditResellerScreen> {
  late final TextEditingController _companyNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _companyNameController =
        TextEditingController(text: widget.reseller['companyName'] ?? '');
    _addressController =
        TextEditingController(text: widget.reseller['address'] ?? '');
    _emailController =
        TextEditingController(text: widget.reseller['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.reseller['phoneNumber'] ?? '');
    _notesController =
        TextEditingController(text: widget.reseller['notes'] ?? '');
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Resellers',
        showMenuButton: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────────────────
                  const Text(
                    'Edit Resellers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Company Name ───────────────────────────────────
                  _buildLabel('Company name'),
                  _buildTextField(
                    controller: _companyNameController,
                    hint: 'Company name',
                  ),
                  const SizedBox(height: 14),

                  // ── Address ────────────────────────────────────────
                  _buildLabel('Address'),
                  _buildTextField(
                    controller: _addressController,
                    hint: 'Enter Address',
                  ),
                  const SizedBox(height: 14),

                  // ── Email Address ──────────────────────────────────
                  _buildLabel('Email Address'),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Enter Email Address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // ── Phone Number ───────────────────────────────────
                  _buildLabel('Phone Number'),
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'Enter Phone Number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // ── Notes ──────────────────────────────────────────
                  _buildLabel('Notes'),
                  _buildTextField(
                    controller: _notesController,
                    hint: '',
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),

          // ── Save Changes button ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: const Color(0xFFF5F7FA),
            child: ElevatedButton(
              onPressed: () => _saveChanges(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC300),
                foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save Changes'),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }
}
