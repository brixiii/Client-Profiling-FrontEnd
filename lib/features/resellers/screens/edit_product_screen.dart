import 'package:flutter/material.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/models/reseller_product.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditProductScreen extends StatefulWidget {
  final ResellerProduct product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final TextEditingController _modelCodeController;
  late final TextEditingController _supplierTypeController;
  late final TextEditingController _uomController;
  late final TextEditingController _quantityController;
  late final TextEditingController _poNumberController;
  late final TextEditingController _drNumberController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _deliveryAddressController;
  late final TextEditingController _logisticsController;
  late final TextEditingController _customerRepController;

  final BackendApi _api = BackendApi();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _modelCodeController =
        TextEditingController(text: p.modelCode);
    _supplierTypeController =
        TextEditingController(text: p.supplierType);
    _uomController =
        TextEditingController(text: p.unitsOfMeasurement);
    _quantityController =
        TextEditingController(text: '${p.quantity}');
    _poNumberController =
        TextEditingController(text: p.poNumber);
    _drNumberController =
        TextEditingController(text: p.drNumber);
    _deliveryDateController =
        TextEditingController(text: p.deliveryDate);
    _deliveryAddressController =
        TextEditingController(text: p.deliveryAddress);
    _logisticsController =
        TextEditingController();
    _customerRepController =
        TextEditingController(text: p.customerRepresentative);
  }

  @override
  void dispose() {
    _modelCodeController.dispose();
    _supplierTypeController.dispose();
    _uomController.dispose();
    _quantityController.dispose();
    _poNumberController.dispose();
    _drNumberController.dispose();
    _deliveryDateController.dispose();
    _deliveryAddressController.dispose();
    _logisticsController.dispose();
    _customerRepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.product.modelName;

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
                  // ── Company name header ────────────────────────────
                  if (companyName.isNotEmpty) ...[
                    Text(
                      '($companyName)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Model Code ─────────────────────────────────────
                  _buildLabel('Model Code'),
                  _buildTextField(controller: _modelCodeController, hint: 'Model Code'),
                  const SizedBox(height: 14),

                  // ── Supplier Type ──────────────────────────────────
                  _buildLabel('Supplier Type'),
                  _buildTextField(controller: _supplierTypeController, hint: 'Supplier Type'),
                  const SizedBox(height: 14),

                  // ── UOM ────────────────────────────────────────────
                  _buildLabel('UOM'),
                  _buildTextField(controller: _uomController, hint: 'UOM'),
                  const SizedBox(height: 14),

                  // ── Quantity ───────────────────────────────────────
                  _buildLabel('Quantity'),
                  _buildTextField(
                    controller: _quantityController,
                    hint: 'Quantity',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),

                  // ── PO Number ──────────────────────────────────────
                  _buildLabel('PO Number'),
                  _buildTextField(controller: _poNumberController, hint: 'PO Number'),
                  const SizedBox(height: 14),

                  // ── DR Number ──────────────────────────────────────
                  _buildLabel('DR Number'),
                  _buildTextField(controller: _drNumberController, hint: 'DR Number'),
                  const SizedBox(height: 14),

                  // ── Delivery Date ──────────────────────────────────
                  _buildLabel('Delivery Date'),
                  _buildDateField(),
                  const SizedBox(height: 14),

                  // ── Delivery Address ───────────────────────────────
                  _buildLabel('Delivery Address'),
                  _buildTextField(
                    controller: _deliveryAddressController,
                    hint: 'Enter Address',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),

                  // ── Logistic ───────────────────────────────────────
                  _buildLabel('Logistic'),
                  _buildTextField(controller: _logisticsController, hint: 'Logistic'),
                  const SizedBox(height: 14),

                  // ── Customer Representative ────────────────────────
                  _buildLabel('Customer Representative'),
                  _buildTextField(controller: _customerRepController, hint: 'Customer Representative'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Save Changes button ──────────────────────────────────
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Save Changes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              try {
                await _api.updateResellerProduct(
                  id: widget.product.id,
                  payload: {
                    'model_code': _modelCodeController.text.trim(),
                    'unitsofmeasurement': _uomController.text.trim(),
                    'quantity': int.tryParse(_quantityController.text.trim()) ??
                        widget.product.quantity,
                    'po_number': _poNumberController.text.trim().isEmpty
                        ? null : _poNumberController.text.trim(),
                    'dr_number': _drNumberController.text.trim().isEmpty
                        ? null : _drNumberController.text.trim(),
                    'delivery_date': _deliveryDateController.text.trim().isEmpty
                        ? null : _deliveryDateController.text.trim(),
                    'delivery_address': _deliveryAddressController.text.trim().isEmpty
                        ? null : _deliveryAddressController.text.trim(),
                    'customer_representative': _customerRepController.text.trim().isEmpty
                        ? null : _customerRepController.text.trim(),
                  },
                );
                if (!mounted) return;
                Navigator.pop(context, true);
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save changes.')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(_deliveryDateController.text) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          _deliveryDateController.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(
          controller: _deliveryDateController,
          hint: 'YYYY-MM-DD',
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
        ),
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
    Widget? suffixIcon,
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
        suffixIcon: suffixIcon,
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
