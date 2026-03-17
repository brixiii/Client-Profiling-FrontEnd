import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';

/// Screen 4 — Add a new Product Model.
/// Reached from the "+ Add Model" button in ProductModelScreen.
class AddProductModelScreen extends StatefulWidget {
  const AddProductModelScreen({Key? key}) : super(key: key);

  @override
  State<AddProductModelScreen> createState() => _AddProductModelScreenState();
}

class _AddProductModelScreenState extends State<AddProductModelScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _washerController = TextEditingController();
  final _dryerController = TextEditingController();
  final _stylerController = TextEditingController();
  final _paymentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _washerController.dispose();
    _dryerController.dispose();
    _stylerController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Build the new model — TODO: pass to real data layer
    final newModel = ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      brand: '',
      category: '',
      description: '',
      washerCode: _washerController.text.trim(),
      dryerCode: _dryerController.text.trim(),
      stylerCode: _stylerController.text.trim(),
      paymentSystem: _paymentController.text.trim(),
    );

    // Return the new model to the calling screen
    Navigator.of(context).pop(newModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section heading ──────────────────────────────────
                const Text(
                  'Add Product Model',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Form card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Model Name
                      _FieldLabel('Model Name'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Enter Model Name',
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Washer
                      _FieldLabel('Washer'),
                      _buildTextFieldWithPlus(
                        controller: _washerController,
                        hint: 'Enter Washer Code',
                        onAdd: () {
                          // TODO: open washer code picker
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dryer
                      _FieldLabel('Dryer'),
                      _buildTextFieldWithPlus(
                        controller: _dryerController,
                        hint: 'Enter Dryer Code',
                        onAdd: () {
                          // TODO: open dryer code picker
                        },
                      ),
                      const SizedBox(height: 16),

                      // Styler
                      _FieldLabel('Styler'),
                      _buildTextField(
                        controller: _stylerController,
                        hint: 'Enter Styler Code',
                      ),
                      const SizedBox(height: 16),

                      // Payment System
                      _FieldLabel('Payment System'),
                      _buildTextField(
                        controller: _paymentController,
                        hint: 'Payment System Code',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Submit button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithPlus({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBCFFA)),
            ),
            child: const Icon(Icons.add,
                color: Color(0xFF2563EB), size: 20),
          ),
        ),
      ],
    );
  }
}

// ── Small label widget ───────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),
    );
  }
}
