import 'package:flutter/material.dart';
import '../../../../../../shared/api/backend_api.dart';
import '../../../../../../shared/widgets/custom_app_bar.dart';

class AddResellerScreen extends StatefulWidget {
  const AddResellerScreen({Key? key}) : super(key: key);

  @override
  State<AddResellerScreen> createState() => _AddResellerScreenState();
}

class _AddResellerScreenState extends State<AddResellerScreen> {
  int _step = 0;

  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _nameController    = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController   = TextEditingController();
  final _phoneController   = TextEditingController();
  final _notesController   = TextEditingController();

  final BackendApi _api = BackendApi();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentKey {
    switch (_step) {
      case 0:  return _step0Key;
      case 1:  return _step1Key;
      default: return _step2Key;
    }
  }

  void _next() {
    if (!(_currentKey.currentState?.validate() ?? false)) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _showConfirmation();
    }
  }

  void _showConfirmation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _summaryRow('Company Name',
                  _nameController.text.isEmpty ? '-' : _nameController.text),
              _summaryRow('Address',
                  _addressController.text.isEmpty ? '-' : _addressController.text),
              _summaryRow('Email Address',
                  _emailController.text.isEmpty ? '-' : _emailController.text),
              _summaryRow('Phone No.',
                  _phoneController.text.isEmpty ? '-' : _phoneController.text),
              _summaryRow('Notes',
                  _notesController.text.isEmpty ? 'N/A' : _notesController.text),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close sheet
                    _submitReseller();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReseller() async {
    try {
      await _api.createReseller({
        'company_name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add reseller.')),
      );
    }
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Resellers',
        showMenuButton: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.account_circle_outlined,
                  color: Colors.black87),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Reseller',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // ── Step rows ──────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(3, (i) {
                      final isActive = i == _step;
                      final isLast   = i == 2;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: dot + connector
                            SizedBox(
                              width: 20,
                              child: Column(
                                children: [
                                  _StepDot(active: i <= _step),
                                  if (!isLast)
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          width: 2,
                                          color: i < _step
                                              ? const Color(0xFFFFC300)
                                              : Colors.grey[300],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right: fields (active) or spacer (inactive)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 8),
                                child: isActive
                                    ? _buildForm(i)
                                    : SizedBox(height: isLast ? 0 : 44),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // ── Bottom button ──────────────────────────────────────
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _step == 2
                        ? const Color(0xFFFFC300)
                        : const Color(0xFF2563EB),
                    foregroundColor:
                        _step == 2 ? Colors.black87 : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _step == 2 ? 'Submit' : 'Next',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Per-step form widgets ────────────────────────────────────────────────
  Widget _buildForm(int stepIndex) {
    switch (stepIndex) {
      // Step 1 — Company Name + Address
      case 0:
        return Form(
          key: _step0Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                controller: _nameController,
                hint: 'Company Name',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Company name is required'
                    : null,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: _addressController,
                hint: 'Address',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Address is required'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      // Step 2 — Email + Phone
      case 1:
        return Form(
          key: _step1Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                controller: _emailController,
                hint: 'Email Address (Optional)',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+')
                      .hasMatch(v.trim());
                  return ok ? null : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: _phoneController,
                hint: 'Phone No.',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Phone number is required';
                  final digits =
                      v.trim().replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 11)
                    return 'Phone number must be 11 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      // Step 3 — Notes
      default:
        return Form(
          key: _step2Key,
          child: Column(
            children: [
              _buildField(
                controller: _notesController,
                hint: 'Notes',
                maxLines: 5,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }
}

// ── Step dot ──────────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool active;

  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFFFC300) : Colors.grey[300],
      ),
    );
  }
}