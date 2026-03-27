import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditProductModelScreen extends StatefulWidget {
  final ProductModel item;

  const EditProductModelScreen({Key? key, required this.item})
      : super(key: key);

  @override
  State<EditProductModelScreen> createState() =>
      _EditProductModelScreenState();
}

class _EditProductModelScreenState extends State<EditProductModelScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    // Show whichever code field is populated, falling back to modelCode
    _codeController = TextEditingController(
      text: widget.item.washerCode.isNotEmpty
          ? widget.item.washerCode
          : widget.item.dryerCode.isNotEmpty
              ? widget.item.dryerCode
              : widget.item.stylerCode.isNotEmpty
                  ? widget.item.stylerCode
                  : widget.item.modelCode,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _codeLabel {
    if (widget.item.washerCode.isNotEmpty) return 'Washer Code';
    if (widget.item.dryerCode.isNotEmpty) return 'Dryer Code';
    if (widget.item.stylerCode.isNotEmpty) return 'Styler Code';
    return 'Model Code';
  }

  void _saveChanges() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final code = _codeController.text.trim();
    final updated = widget.item.copyWith(
      name: _nameController.text.trim(),
      modelCode: widget.item.washerCode.isEmpty &&
              widget.item.dryerCode.isEmpty &&
              widget.item.stylerCode.isEmpty
          ? code
          : null,
      washerCode:
          widget.item.washerCode.isNotEmpty ? code : widget.item.washerCode,
      dryerCode:
          widget.item.dryerCode.isNotEmpty ? code : widget.item.dryerCode,
      stylerCode:
          widget.item.stylerCode.isNotEmpty ? code : widget.item.stylerCode,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Inventory',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // â”€â”€ Heading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      const Text(
                        'Edit Product Model',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // â”€â”€ Model Name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _FieldLabel('Model Name'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Enter Model Name',
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // â”€â”€ Code field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _FieldLabel(_codeLabel),
                      _buildTextField(
                        controller: _codeController,
                        hint: 'Enter $_codeLabel',
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // â”€â”€ Save Changes button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C518),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE74C3C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
        ),
      ),
    );
  }
}

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
          color: Colors.black87,
        ),
      ),
    );
  }
}