import 'package:flutter/material.dart';
import '../../../../../../shared/widgets/custom_app_bar.dart';

class AddResellerScreen extends StatefulWidget {
  const AddResellerScreen({Key? key}) : super(key: key);

  @override
  State<AddResellerScreen> createState() => _AddResellerScreenState();
}

class _AddResellerScreenState extends State<AddResellerScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step metadata
  static const _stepTitles = [
    'Company Name',
    'Address',
    'Email Address',
    'Phone Number',
  ];

  static const _stepSubtitles = [
    'Enter the registered company name',
    'Enter the company address',
    'Enter a valid email address',
    'Enter the contact phone number',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Advance step or submit on the last step
  void _nextStep() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _showConfirmDialog();
    }
  }

  void _showConfirmDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
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
            _summaryRow('Email',
                _emailController.text.isEmpty ? '-' : _emailController.text),
            _summaryRow('Phone No.',
                _phoneController.text.isEmpty ? '-' : _phoneController.text),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.pop(context); // go back to resellers screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC300),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Confirm',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Build the input for the current step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTextField(
          controller: _nameController,
          hint: 'e.g. TechFlow Solutions',
          icon: Icons.business_outlined,
          label: 'Company Name',
          required: true,
        );
      case 1:
        return _buildTextField(
          controller: _addressController,
          hint: 'e.g. #3 Mon el Drive Subd., Brgy. San Antonio',
          icon: Icons.location_on_outlined,
          label: 'Address',
          maxLines: 3,
          required: true,
        );
      case 2:
        return _buildTextField(
          controller: _emailController,
          hint: 'e.g. contact@company.com',
          icon: Icons.email_outlined,
          label: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          required: true,
        );
      case 3:
        return _buildTextField(
          controller: _phoneController,
          hint: 'e.g. +1 (555) 123-4567',
          icon: Icons.phone_outlined,
          label: 'Phone Number',
          keyboardType: TextInputType.phone,
          required: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '$label is required'
                  : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Add Reseller',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF2563EB).withOpacity(0.4)),
                ),
                child: Text(
                  'Step ${_currentStep + 1} of 4',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Step content card ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(4, (step) {
                      final bool isActive = step == _currentStep;
                      final bool isLast = step == 3;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: circle + connector stretching to row height
                            SizedBox(
                              width: 30,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: step <= _currentStep
                                        ? () => setState(() => _currentStep = step)
                                        : null,
                                    child: _buildStepDot(step),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          width: 2,
                                          color: step < _currentStep
                                              ? const Color(0xFF2563EB)
                                              : Colors.grey[300],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right: form content when active, spacer otherwise
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                                child: isActive
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _stepTitles[step],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _stepSubtitles[step],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          _buildStepContent(),
                                          const SizedBox(height: 16),
                                        ],
                                      )
                                    : const SizedBox(height: 46),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // ── Bottom: Back + Next/Submit ─────────────────────────
              Row(
                children: [
                  // Next / Add Reseller button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStep == 3 ? 'Add Reseller' : 'Next',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Numbered step dot — completed / active / inactive
  Widget _buildStepDot(int step) {
    final isCompleted = step < _currentStep;
    final isCurrent = step == _currentStep;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent
            ? const Color(0xFF2563EB)
            : Colors.grey[300],
        boxShadow: isCompleted || isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: isCompleted
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? Colors.white : Colors.black38,
                ),
              ),
            ),
    );
  }

}
