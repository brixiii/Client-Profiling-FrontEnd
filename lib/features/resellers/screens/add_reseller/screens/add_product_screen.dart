import 'package:flutter/material.dart';
import '../../../../../shared/widgets/custom_app_bar.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, String> reseller;

  const AddProductScreen({Key? key, required this.reseller}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 4;

  // Step 1 — Product Selection
  String? _modelName;
  String? _supplierType;
  String? _machineType;
  String? _modelCode;
  String? _unit;

  // Step 2 — Order Details
  int _quantity = 1;
  final _poController = TextEditingController();
  final _drController = TextEditingController();
  final List<TextEditingController> _serialControllers = [
    TextEditingController()
  ];

  // Step 3 — Delivery Info
  final _deliveryAddressController = TextEditingController();
  DateTime? _deliveryDate;
  String? _logistic;
  final _customerRepController = TextEditingController();

  // Step 4 — Notes
  final _notesController = TextEditingController();

  static const _modelNames = [
    'Model A', 'Model B', 'Model C', 'Model D', 'Model E'
  ];
  static const _supplierTypes = ['Offer', 'Standard', 'Direct'];
  static const _machineTypes = ['Desktop', 'Laptop', 'Printer', 'Server', 'Other'];
  static const _modelCodes = [
    'CWC027MOCR8', 'CWC028MOCR8', 'CWC029MOCR8', 'Other'
  ];
  static const _unitTypes = ['UCM', 'Itemized', 'Bundle'];
  static const _logistics = [
    'Pick-up', 'Door-to-Door', 'Freight', 'Courier', 'Air Cargo'
  ];

  static const _stepTitles = [
    'Product Selection',
    'Order Details',
    'Delivery Info',
    'Notes',
  ];
  static const _stepSubtitles = [
    'Select model and product details',
    'Enter quantity and order numbers',
    'Enter delivery details',
    'Add any additional notes',
  ];

  @override
  void dispose() {
    _poController.dispose();
    _drController.dispose();
    for (final c in _serialControllers) {
      c.dispose();
    }
    _deliveryAddressController.dispose();
    _customerRepController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _showConfirmDialog();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  void _showConfirmDialog() {
    final serials = _serialControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');

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
        child: SingleChildScrollView(
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
              const Text(
                'Confirm Product',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const SizedBox(height: 16),
              _summaryRow('Reseller', widget.reseller['companyName'] ?? ''),
              _summaryRow('Model Name', _modelName ?? 'N/A'),
              _summaryRow('Supplier Type', _supplierType ?? 'N/A'),
              _summaryRow('Machine Type', _machineType ?? 'N/A'),
              _summaryRow('Model Code', _modelCode ?? 'N/A'),
              _summaryRow('Unit', _unit ?? 'N/A'),
              _summaryRow('Quantity', '$_quantity'),
              _summaryRow('Purchase Order', _poController.text.isEmpty ? 'N/A' : _poController.text),
              _summaryRow('Delivery Receipt', _drController.text.isEmpty ? 'N/A' : _drController.text),
              _summaryRow('Serial/Unit Numbers', serials.isEmpty ? 'N/A' : serials),
              _summaryRow('Delivery Address',
                  _deliveryAddressController.text.isEmpty ? 'N/A' : _deliveryAddressController.text),
              _summaryRow(
                'Delivery Date',
                _deliveryDate == null
                    ? 'N/A'
                    : '${_deliveryDate!.month}/${_deliveryDate!.day}/${_deliveryDate!.year}',
              ),
              _summaryRow('Logistic', _logistic ?? 'N/A'),
              _summaryRow('Customer Representative',
                  _customerRepController.text.isEmpty ? 'N/A' : _customerRepController.text),
              _summaryRow('Notes', _notesController.text.isEmpty ? 'N/A' : _notesController.text),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product added successfully'),
                        backgroundColor: Color(0xFF2563EB),
                      ),
                    );
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
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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

  // ── Step content builders ──────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        _buildDropdown(
          value: _modelName,
          items: _modelNames,
          hint: 'Select Model Name',
          icon: Icons.devices_outlined,
          onChanged: (val) => setState(() => _modelName = val),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          value: _supplierType,
          items: _supplierTypes,
          hint: 'Supplier Type',
          icon: Icons.category_outlined,
          onChanged: (val) => setState(() => _supplierType = val),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          value: _machineType,
          items: _machineTypes,
          hint: 'Machine Type',
          icon: Icons.computer_outlined,
          onChanged: (val) => setState(() => _machineType = val),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          value: _modelCode,
          items: _modelCodes,
          hint: 'Model Code',
          icon: Icons.qr_code_outlined,
          onChanged: (val) => setState(() => _modelCode = val),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          value: _unit,
          items: _unitTypes,
          hint: 'UCM',
          icon: Icons.inventory_2_outlined,
          onChanged: (val) => setState(() => _unit = val),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        // Quantity stepper
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_quantity > 1) setState(() => _quantity--);
                },
                color: Colors.grey[600],
              ),
              Expanded(
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantity++),
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _poController,
          hint: 'Purchase Order',
          icon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _drController,
          hint: 'Delivery Receipt',
          icon: Icons.assignment_outlined,
        ),
        const SizedBox(height: 14),
        // Serial/Unit Number list with + button
        ...List.generate(_serialControllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _serialControllers[i],
                    decoration: InputDecoration(
                      hintText: 'Serial/Unit Number',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                ),
                if (i == _serialControllers.length - 1) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _serialControllers.add(TextEditingController());
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildTextField(
          controller: _deliveryAddressController,
          hint: 'Delivery Address',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        // Delivery Date picker
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _deliveryDate == null
                        ? 'Delivery Date'
                        : '${_deliveryDate!.month}/${_deliveryDate!.day}/${_deliveryDate!.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _deliveryDate == null
                          ? Colors.grey[400]
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildDropdown(
          value: _logistic,
          items: _logistics,
          hint: 'Logistic',
          icon: Icons.local_shipping_outlined,
          onChanged: (val) => setState(() => _logistic = val),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _customerRepController,

          hint: 'Customer Representative',
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        TextField(
          controller: _notesController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Notes',
            hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          ),
        ),
      ],
    );
  }

  // ── Shared input helpers ───────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
    );
  }

  // ── Step dot ──────────────────────────────────────────────────────────

  Widget _buildStepDot(int step) {
    final isCompleted = step < _currentStep;
    final isCurrent = step == _currentStep;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent
            ? const Color(0xFFFFC300)
            : Colors.grey[300],
        boxShadow: isCompleted || isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFFFFC300).withOpacity(0.4),
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

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Add Product',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC300).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFC300).withOpacity(0.5)),
                ),
                child: Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8860B),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reseller badge
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_outlined,
                      size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.reseller['companyName'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Vertical stepper ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_totalSteps, (step) {
                    final bool isActive = step == _currentStep;
                    final bool isLast = step == _totalSteps - 1;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: dot + connector
                          SizedBox(
                            width: 30,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: step <= _currentStep
                                      ? () =>
                                          setState(() => _currentStep = step)
                                      : null,
                                  child: _buildStepDot(step),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        color: step < _currentStep
                                            ? const Color(0xFFFFC300)
                                            : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right: form or spacer
                          Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(bottom: isLast ? 0 : 8),
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
                                        _buildStepContent(step),
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

            // ── Bottom button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == _totalSteps - 1
                      ? const Color(0xFFFFC300)
                      : const Color(0xFF2563EB),
                  foregroundColor: _currentStep == _totalSteps - 1
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentStep == _totalSteps - 1 ? 'Submit' : 'Next',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


