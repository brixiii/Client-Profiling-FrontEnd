import 'package:flutter/material.dart';
import '../models/serial_number_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditSerialNumberScreen extends StatefulWidget {
  final SerialNumberModel item;
  final int editIndex;

  const EditSerialNumberScreen({
    Key? key,
    required this.item,
    this.editIndex = 0,
  }) : super(key: key);

  @override
  State<EditSerialNumberScreen> createState() => _EditSerialNumberScreenState();
}

class _EditSerialNumberScreenState extends State<EditSerialNumberScreen> {
  late TextEditingController _serialNumberController;
  late TextEditingController _productModelController;

  @override
  void initState() {
    super.initState();
    final codes = widget.item.serialCodes;
    _serialNumberController = TextEditingController(
      text: codes.length > widget.editIndex ? codes[widget.editIndex] : '',
    );
    _productModelController =
        TextEditingController(text: widget.item.productModel);
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _productModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Edit Serial',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 24),

                  // Serial Number field
                  _buildLabel('Serial Number'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _serialNumberController,
                    hint: 'Enter Serial Number',
                  ),
                  const SizedBox(height: 16),

                  // Product Model field
                  _buildLabel('Product Model'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _productModelController,
                    hint: 'Enter Product Model',
                  ),
                ],
              ),
            ),
          ),

          // Save Changes button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final codes = List<String>.from(widget.item.serialCodes);
                  if (codes.length > widget.editIndex) {
                    codes[widget.editIndex] =
                        _serialNumberController.text.trim();
                  }
                  final updated = widget.item.copyWith(
                    productModel: _productModelController.text.trim(),
                    serialCodes: codes,
                  );
                  Navigator.of(context).pop(updated);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87));
  }

  Widget _buildTextField(TextEditingController controller,
      {required String hint}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }
}
