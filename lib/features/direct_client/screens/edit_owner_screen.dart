import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditOwnerScreen extends StatefulWidget {
  final Map<String, String> client;

  const EditOwnerScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<EditOwnerScreen> createState() => _EditOwnerScreenState();
}

class _EditOwnerScreenState extends State<EditOwnerScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final name = widget.client['contactPerson'] ?? '';
    final parts = name.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.last : '';

    _firstNameController = TextEditingController(text: firstName);
    _middleNameController = TextEditingController();
    _lastNameController = TextEditingController(text: lastName);
    _emailController =
        TextEditingController(text: widget.client['contactEmail'] ?? '');
    _phoneController =
        TextEditingController(text: widget.client['contactNo'] ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Owner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildField('Full Name', _firstNameController,
                      hint: 'Glenda'),
                  const SizedBox(height: 16),

                  _buildField('Middle name', _middleNameController,
                      hint: 'Enter Middle Name (Optional)'),
                  const SizedBox(height: 16),

                  _buildField('Last Name', _lastNameController,
                      hint: 'Valeroso'),
                  const SizedBox(height: 16),

                  _buildField('Email Address', _emailController,
                      hint: 'glendavaleroso25@gmail.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),

                  _buildField('Phone Number', _phoneController,
                      hint: '0966-135-9282',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),

                  _buildField('Notes', _notesController,
                      hint: '', maxLines: 6),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Save Changes button pinned at bottom
          Container(
            width: double.infinity,
            color: const Color(0xFFF5F7FA),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ElevatedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Save Changes'),
                    content: const Text(
                        'Are you sure you want to save these changes?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC300),
                          foregroundColor: Colors.black,
                          elevation: 0,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // TODO: save logic
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC300),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
