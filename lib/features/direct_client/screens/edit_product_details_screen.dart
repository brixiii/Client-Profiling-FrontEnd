import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditProductDetailsScreen extends StatefulWidget {
  final Map<String, String> product;

  const EditProductDetailsScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<EditProductDetailsScreen> createState() =>
      _EditProductDetailsScreenState();
}

class _EditProductDetailsScreenState extends State<EditProductDetailsScreen> {
  late final TextEditingController _modelCodeController;
  late final TextEditingController _contractDateController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _installationDateController;
  late final TextEditingController _purchaseOrderController;
  late final TextEditingController _deliveryReceiptController;
  late final TextEditingController _notesController;

  String? _supplierType;
  String? _employeeName;

  final List<String> _supplierTypes = ['Bulla Crave', 'Other Supplier'];
  final List<String> _employeeNames = [
    'Marion Brix Quiling',
    'Cecile Aviles',
    'Other Employee',
  ];

  @override
  void initState() {
    super.initState();
    _modelCodeController =
        TextEditingController(text: widget.product['modelCode'] ?? '');
    _contractDateController =
        TextEditingController(text: widget.product['contractDate'] ?? '');
    _deliveryDateController =
        TextEditingController(text: widget.product['deliveryDate'] ?? '');
    _installationDateController =
        TextEditingController(text: widget.product['installationDate'] ?? '');
    _purchaseOrderController =
        TextEditingController(text: widget.product['poNumber'] ?? '');
    _deliveryReceiptController =
        TextEditingController(text: widget.product['drNumber'] ?? '');
    _notesController = TextEditingController();

    final supplier = widget.product['supplierType'] ?? '';
    if (_supplierTypes.contains(supplier)) _supplierType = supplier;

    final employee = widget.product['employeeName'] ?? '';
    if (_employeeNames.contains(employee)) _employeeName = employee;
  }

  @override
  void dispose() {
    _modelCodeController.dispose();
    _contractDateController.dispose();
    _deliveryDateController.dispose();
    _installationDateController.dispose();
    _purchaseOrderController.dispose();
    _deliveryReceiptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
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
                    'Edit Product Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildField('Model Code', _modelCodeController,
                      hint: 'CWG27MDCRB'),
                  const SizedBox(height: 14),

                  _buildDateField('Contract Date', _contractDateController),
                  const SizedBox(height: 14),

                  _buildDateField('Delivery Date', _deliveryDateController),
                  const SizedBox(height: 14),

                  _buildDateField(
                      'Installation Date', _installationDateController),
                  const SizedBox(height: 14),

                  _buildField('Purchase Order', _purchaseOrderController,
                      hint: 'Enter PO Order'),
                  const SizedBox(height: 14),

                  _buildField('Delivery Receipt', _deliveryReceiptController,
                      hint: 'Enter DR Order'),
                  const SizedBox(height: 14),

                  _buildLabel('Supplier Type'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _supplierType,
                    items: _supplierTypes,
                    hint: 'Select Supplier Type',
                    onChanged: (v) => setState(() => _supplierType = v),
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Employee Name'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _employeeName,
                    items: _employeeNames,
                    hint: 'Select Employee',
                    onChanged: (v) => setState(() => _employeeName = v),
                  ),
                  const SizedBox(height: 14),

                  _buildField('Notes', _notesController,
                      hint: '', maxLines: 6),
                  const SizedBox(height: 24),
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
                  // TODO: save product data
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
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
        _buildLabel(label),
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

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'MM/DD/YYYY',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIcon: Icon(Icons.calendar_month, color: Colors.grey[600]),
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
          onTap: () => _pickDate(controller),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
