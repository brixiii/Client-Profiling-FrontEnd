import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditOwnerScreen extends StatefulWidget {
  final Map<String, String> client;

  const EditOwnerScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<EditOwnerScreen> createState() => _EditOwnerScreenState();
}

class _EditOwnerScreenState extends State<EditOwnerScreen> {
  final _api = BackendApi();

  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorText;
  Map<String, String> _fieldErrors = {};

  int? _clientId;

  String? _companyName;
  String? _address;

  @override
  void initState() {
    super.initState();
    _clientId =
        int.tryParse(widget.client['client_id'] ?? widget.client['id'] ?? '');

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
    _notesController =
        TextEditingController(text: widget.client['notes'] ?? '');

    _companyName = widget.client['ccompanyname'];
    _address = widget.client['address'];

    _loadClient();
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

  Future<void> _loadClient() async {
    if (_clientId == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final client = await _api.getClientById(_clientId!);
      if (!mounted) return;

      setState(() {
        _firstNameController.text = client['cfirstname']?.toString() ?? '';
        _middleNameController.text = client['cmiddlename']?.toString() ?? '';
        _lastNameController.text = client['csurname']?.toString() ?? '';
        _emailController.text = client['cemail']?.toString() ?? '';
        _phoneController.text = client['cphonenum']?.toString() ?? '';
        _notesController.text = client['notes']?.toString() ?? '';
        _companyName = client['ccompanyname']?.toString();
        _address = client['address']?.toString();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to load client details.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveClient() async {
    if (_clientId == null) {
      setState(() => _errorText = 'Missing client id.');
      return;
    }

    final guardErrors = _validateOwnerForm();
    if (guardErrors.isNotEmpty) {
      setState(() {
        _fieldErrors = guardErrors;
        _errorText = 'Please fix the highlighted fields before saving.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
      _fieldErrors = {};
    });

    final payload = <String, dynamic>{
      'cfirstname': _firstNameController.text.trim(),
      'cmiddlename': _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      'csurname': _lastNameController.text.trim(),
      'ccompanyname': _companyName,
      'cemail': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'cphonenum': _phoneController.text.trim(),
      'address': _address,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      await _api.updateClient(id: _clientId!, payload: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner updated successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _fieldErrors = e.fieldErrors;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to update owner.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
                  if (_errorText != null) ...[
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _buildField('Full Name', _firstNameController,
                      hint: 'Enter first name'),
                  const SizedBox(height: 16),
                  _buildField('Middle name', _middleNameController,
                      hint: 'Enter Middle Name (Optional)'),
                  const SizedBox(height: 16),
                  _buildField('Last Name', _lastNameController,
                      hint: 'Enter last name'),
                  const SizedBox(height: 16),
                  _buildField('Email Address', _emailController,
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField('Phone Number', _phoneController,
                      hint: 'Enter phone number',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      maxLength: 11),
                  const SizedBox(height: 16),
                  _buildField('Notes', _notesController, hint: '', maxLines: 6),
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
                if (_isSaving || _isLoading) return;
                final guardErrors = _validateOwnerForm();
                if (guardErrors.isNotEmpty) {
                  setState(() {
                    _fieldErrors = guardErrors;
                    _errorText =
                        'Please fix the highlighted fields before saving.';
                  });
                  return;
                }
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
                  await _saveClient();
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
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            errorText: _fieldErrors[_toBackendKey(label)],
            counterText: '',
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

  String _toBackendKey(String label) {
    switch (label) {
      case 'Full Name':
        return 'cfirstname';
      case 'Middle name':
        return 'cmiddlename';
      case 'Last Name':
        return 'csurname';
      case 'Email Address':
        return 'cemail';
      case 'Phone Number':
        return 'cphonenum';
      case 'Notes':
        return 'notes';
      default:
        return '';
    }
  }

  Map<String, String> _validateOwnerForm() {
    final errors = <String, String>{};

    if (_firstNameController.text.trim().isEmpty) {
      errors['cfirstname'] = 'First name is required.';
    }
    if (_lastNameController.text.trim().isEmpty) {
      errors['csurname'] = 'Last name is required.';
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      errors['cphonenum'] = 'Phone number is required.';
    } else if (!RegExp(r'^\d{11}$').hasMatch(phone)) {
      errors['cphonenum'] = 'Phone number must be exactly 11 digits.';
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      errors['cemail'] = 'Enter a valid email address.';
    }

    return errors;
  }

  bool _isValidEmail(String email) {
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(email);
  }
}
