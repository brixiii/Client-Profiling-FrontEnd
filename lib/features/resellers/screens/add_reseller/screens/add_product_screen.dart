import 'package:flutter/material.dart';
import '../../../../../shared/api/backend_api.dart';
import '../../../../../shared/api/paginated_response.dart';
import '../../../../../shared/models/product.dart';
import '../../../../../shared/models/reseller.dart';
import '../../../../../shared/widgets/custom_app_bar.dart';

class AddProductScreen extends StatefulWidget {
  final Reseller reseller;

  const AddProductScreen({Key? key, required this.reseller}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 4;

  Map<String, String> _fieldErrors = {};

  // Step 0 — Product Selection
  String? _modelName;
  String? _supplierType;
  String? _machineType;
  final _modelCodeController = TextEditingController();
  String? _unit;

  // Step 1 — Order Details
  final _quantityController = TextEditingController(text: '1');
  final _poController = TextEditingController();
  final _drController = TextEditingController();
  final List<TextEditingController> _serialControllers = [
    TextEditingController()
  ];

  // Step 2 — Delivery Info
  final _deliveryAddressController = TextEditingController();
  DateTime? _deliveryDate;
  String? _logistic;
  final _customerRepController = TextEditingController();

  // Step 3 — Notes
  final _notesController = TextEditingController();

  final BackendApi _api = BackendApi();

  // ── API-driven option lists ──────────────────────────────────────────────
  List<Map<String, dynamic>> _applianceModelRows = [];
  final List<String> _modelNames = [];
  final List<String> _machineTypes = [];
  final List<String> _uomOptions = [];
  bool _isLoadingDependencies = false;

  static const _supplierTypes = ['Bulla Crave', 'Other'];
  static const _logistics = [
    'Pick-up', 'Door-to-Door', 'Freight', 'Courier', 'Air Cargo',
  ];

  static const _stepTitles = [
    'Product Selection',
    'Order Details',
    'Delivery Info',
    'Notes',
  ];

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  @override
  void dispose() {
    _modelCodeController.dispose();
    _quantityController.dispose();
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

  Future<void> _loadDependencies() async {
    setState(() => _isLoadingDependencies = true);

    try {
      final results = await Future.wait([
        _api.getApplianceModels(page: 1, perPage: 100).catchError((_) =>
            PaginatedResponse<Map<String, dynamic>>(
                data: const [],
                currentPage: 1,
                perPage: 100,
                total: 0,
                lastPage: 1,
                links: const [])),
        _api.getProducts(page: 1, perPage: 200).catchError((_) =>
            PaginatedResponse<Product>(
                data: const [],
                currentPage: 1,
                perPage: 200,
                total: 0,
                lastPage: 1,
                links: const [])),
      ]);

      if (!mounted) return;

      final applianceModels =
          (results[0] as PaginatedResponse<Map<String, dynamic>>).data;
      final products = (results[1] as PaginatedResponse<Product>).data;

      List<String> collectUnique(Iterable<String> values) {
        final byKey = <String, String>{};
        for (final raw in values) {
          final value = raw.trim();
          if (value.isEmpty) continue;
          byKey.putIfAbsent(value.toLowerCase(), () => value);
        }
        return byKey.values.toList()..sort();
      }

      final derivedModelNames = collectUnique(
          applianceModels.map((row) => _asString(row['model_name'])));
      final derivedUom =
          _sanitizeUomOptions(products.map((Product p) => p.unitsofmeasurement));

      setState(() {
        _applianceModelRows =
            applianceModels.map((row) => Map<String, dynamic>.from(row)).toList();
        _modelNames
          ..clear()
          ..addAll(derivedModelNames);
        _uomOptions
          ..clear()
          ..addAll(derivedUom);
        _isLoadingDependencies = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDependencies = false);
    }
  }

  // ── Appliance model dependency chain ──────────────────────────────────

  static const Map<String, _ApplianceTypeMeta> _applianceTypeMeta = {
    'washer': _ApplianceTypeMeta('Washer', 'washer_code'),
    'dryer': _ApplianceTypeMeta('Dryer', 'dryer_code'),
    'styler': _ApplianceTypeMeta('Styler', 'styler_code'),
    'payment_system':
        _ApplianceTypeMeta('Payment System', 'payment_system_code'),
  };

  void _onModelNameChanged(String? value) {
    setState(() {
      _modelName = value;
      _machineTypes
        ..clear()
        ..addAll(_machineTypesForModel(_modelName));
      if (!_machineTypes.contains(_machineType)) {
        _machineType = null;
      }
      _modelCodeController.text =
          _resolveModelCode(modelName: _modelName, applianceType: _machineType) ?? '';
    });
  }

  void _onMachineTypeChanged(String? value) {
    setState(() {
      _machineType = value;
      _modelCodeController.text =
          _resolveModelCode(modelName: _modelName, applianceType: _machineType) ?? '';
    });
  }

  List<String> _machineTypesForModel(String? modelName) {
    final model = (modelName ?? '').trim();
    if (model.isEmpty) return const [];
    final ordered = <String>[];
    for (final row in _applianceModelRows) {
      if (_asString(row['model_name']) != model) continue;
      for (final entry in _applianceTypeMeta.entries) {
        if (_asBool(row[entry.key])) {
          final label = entry.value.label;
          if (!ordered.contains(label)) ordered.add(label);
        }
      }
    }
    return ordered;
  }

  String? _resolveModelCode({
    required String? modelName,
    required String? applianceType,
  }) {
    final model = (modelName ?? '').trim();
    final typeLabel = (applianceType ?? '').trim();
    if (model.isEmpty || typeLabel.isEmpty) return null;

    String? key;
    for (final entry in _applianceTypeMeta.entries) {
      if (entry.value.label == typeLabel) {
        key = entry.key;
        break;
      }
    }
    if (key == null) return null;

    final meta = _applianceTypeMeta[key]!;
    for (final row in _applianceModelRows) {
      if (_asString(row['model_name']) != model) continue;
      if (!_asBool(row[key])) continue;
      final code = _asString(row[meta.codeField]);
      if (code.isNotEmpty) return code;
    }
    return null;
  }

  String _asString(dynamic raw) => (raw ?? '').toString().trim();

  bool _asBool(dynamic raw) {
    if (raw is bool) return raw;
    final value = (raw ?? '').toString().trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes';
  }

  List<String> _sanitizeUomOptions(Iterable<String> values) {
    const invalidValues = {'', '-', 'null', 'password', 'n/a', 'na', 'none'};
    final byKey = <String, String>{};
    for (final raw in values) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) continue;
      final normalized = cleaned.toLowerCase();
      if (invalidValues.contains(normalized)) continue;
      byKey.putIfAbsent(normalized, () => cleaned);
    }
    return byKey.values.toList()..sort();
  }

  bool _validateCurrentStep() {
    final errors = <String, String>{};
    if (_currentStep == 0) {
      if ((_modelName ?? '').trim().isEmpty) {
        errors['model_name'] = 'Model name is required.';
      }
      if ((_machineType ?? '').trim().isEmpty) {
        errors['appliance_type'] = 'Machine type is required.';
      }
      if (_modelCodeController.text.trim().isEmpty) {
        errors['model_code'] = 'Model code is required.';
      }
      if ((_unit ?? '').trim().isEmpty) {
        errors['unitsofmeasurement'] = 'UOM is required.';
      }
    }
    if (errors.isEmpty) {
      if (_fieldErrors.isNotEmpty) setState(() => _fieldErrors = {});
      return true;
    }
    setState(() => _fieldErrors = errors);
    return false;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _showConfirmDialog();
    }
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
              _summaryRow('Reseller', widget.reseller.companyName),
              _summaryRow('Model Name', _modelName ?? '-'),
              _summaryRow('Supplier Type', _supplierType ?? '-'),
              _summaryRow('Machine Type', _machineType ?? '-'),
              _summaryRow('Model Code',
                  _modelCodeController.text.isEmpty ? '-' : _modelCodeController.text),
              _summaryRow('UOM', _unit ?? '-'),
              _summaryRow('Quantity', _quantityController.text),
              _summaryRow('Purchase Order',
                  _poController.text.isEmpty ? '-' : _poController.text),
              _summaryRow('Delivery Receipt',
                  _drController.text.isEmpty ? '-' : _drController.text),
              _summaryRow('Serial/Unit Numbers', serials.isEmpty ? '-' : serials),
              _summaryRow('Delivery Address',
                  _deliveryAddressController.text.isEmpty ? '-' : _deliveryAddressController.text),
              _summaryRow(
                'Delivery Date',
                _deliveryDate == null
                    ? '-'
                    : '${_deliveryDate!.month}/${_deliveryDate!.day}/${_deliveryDate!.year}',
              ),
              _summaryRow('Logistic', _logistic ?? '-'),
              _summaryRow('Customer Representative',
                  _customerRepController.text.isEmpty ? '-' : _customerRepController.text),
              _summaryRow('Notes',
                  _notesController.text.isEmpty ? '-' : _notesController.text),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close sheet
                    _submitProduct();
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
      padding: const EdgeInsets.only(bottom: 14),
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

  Future<void> _submitProduct() async {
    try {
      final product = await _api.createResellerProduct({
        'model_name': _modelName ?? '',
        'appliance_type': _machineType ?? '',
        'model_code': _modelCodeController.text.trim(),
        'unitsofmeasurement': _unit ?? '',
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 1,
        'reseller_id': widget.reseller.id,
        'po_number': _poController.text.trim().isEmpty
            ? null : _poController.text.trim(),
        'dr_number': _drController.text.trim().isEmpty
            ? null : _drController.text.trim(),
        'delivery_date': _deliveryDate == null
            ? null
            : '${_deliveryDate!.year}-'
              '${_deliveryDate!.month.toString().padLeft(2, '0')}-'
              '${_deliveryDate!.day.toString().padLeft(2, '0')}',
        'delivery_address': _deliveryAddressController.text.trim().isEmpty
            ? null : _deliveryAddressController.text.trim(),
        'customer_representative': _customerRepController.text.trim().isEmpty
            ? null : _customerRepController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null : _notesController.text.trim(),
      });
      // Post each serial number separately — deduplicated
      final validSerials = _serialControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      for (final serial in validSerials) {
        await _api.createResellerProductSerial(
          resellerProductId: product.id,
          serialNumber: serial,
          supplierType: _supplierType ?? '',
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add product.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Step content ──────────────────────────────────────────────────────

  Widget addProductDetails() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            if (_isLoadingDependencies)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  color: Color(0xFFFFC300),
                  backgroundColor: Color(0xFFFFF9C4),
                ),
              ),
            _buildSearchableDropdownField(
                hint: 'Select Model Name',
                value: _modelName,
                items: _modelNames,
                onChanged: _onModelNameChanged,
                errorText: _fieldErrors['model_name']),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Supplier Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message:
                      'Select supplier type, Bulla Crave for direct supply / Other for indirect supply (Super Admin Only)',
                  child: const Icon(
                    Icons.help,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSearchableDropdownField(
                hint: 'Select supplier type',
                value: _supplierType,
                items: _supplierTypes,
                onChanged: (v) => setState(() => _supplierType = v)),
            const SizedBox(height: 12),
            _buildSearchableDropdownField(
                hint: 'Machine Type',
                value: _machineType,
                items: _machineTypes,
                onChanged: _onMachineTypeChanged,
                errorText: _fieldErrors['appliance_type']),
            const SizedBox(height: 12),
            _buildTextField(_modelCodeController,
                hint: 'Model Code',
                readOnly: true,
                errorText: _fieldErrors['model_code']),
            const SizedBox(height: 12),
            _buildSearchableDropdownField(
                hint: 'UOM',
                value: _unit,
                items: _uomOptions,
                onChanged: (v) => setState(() => _unit = v),
                errorText: _fieldErrors['unitsofmeasurement']),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildSpinnerField('Quantity', _quantityController),
            const SizedBox(height: 12),
            _buildTextField(_poController,
                hint: 'Purchase Order (Optional)'),
            const SizedBox(height: 12),
            _buildTextField(_drController,
                hint: 'Delivery Receipt (Optional)'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Serial/Unit Numbers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildIconButton(Icons.add, () {
                  setState(() =>
                      _serialControllers.add(TextEditingController()));
                }),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_serialControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(_serialControllers[i],
                          hint: 'Serial/Unit Number'),
                    ),
                    if (_serialControllers.length > 1) ...[
                      const SizedBox(width: 8),
                      _buildRedRemoveButton(() {
                        _serialControllers[i].dispose();
                        setState(() => _serialControllers.removeAt(i));
                      }),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildTextField(_deliveryAddressController,
                hint: 'Delivery Address'),
            const SizedBox(height: 12),
            _buildDateField('Delivery Date', _deliveryDate,
                (d) => setState(() => _deliveryDate = d)),
            const SizedBox(height: 12),
            _buildSearchableDropdownField(
                hint: 'Logistic',
                value: _logistic,
                items: _logistics,
                onChanged: (v) => setState(() => _logistic = v)),
            const SizedBox(height: 12),
            _buildTextField(_customerRepController,
                hint: 'Customer Representative'),
          ],
        );
      case 3:
        return _buildTextField(_notesController, hint: 'Notes', maxLines: 7);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Shared input helpers (matching add_buttons_screen style) ──────────

  Widget _buildTextField(
    TextEditingController controller, {
    String hint = '',
    int maxLines = 1,
    String? errorText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
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
              borderSide: BorderSide(
                color: errorText == null
                    ? Colors.grey[300]!
                    : const Color(0xFFB91C1C),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText == null
                    ? Colors.grey[300]!
                    : const Color(0xFFB91C1C),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText == null
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFB91C1C),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorText != null && errorText.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              errorText,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String? errorText,
  }) {
    final safeValue = items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: errorText == null
                    ? Colors.grey[300]!
                    : const Color(0xFFB91C1C)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
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
        ),
        if (errorText != null && errorText.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              errorText,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchableDropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showSearchPicker(
            hint: hint,
            items: items,
            selected: value,
            onSelected: onChanged,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFB91C1C)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          value != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
      ],
    );
  }

  void _showSearchPicker({
    required String hint,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenSearchPicker(
          hint: hint,
          items: items,
          selected: selected,
          onSelected: (item) {
            onSelected(item);
          },
        ),
      ),
    );
  }

  Widget _buildSpinnerField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: label,
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  final val = int.tryParse(controller.text) ?? 0;
                  controller.text = '${val + 1}';
                },
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Icon(Icons.keyboard_arrow_up, size: 18),
                ),
              ),
              InkWell(
                onTap: () {
                  final val = int.tryParse(controller.text) ?? 2;
                  if (val > 1) controller.text = '${val - 1}';
                },
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Icon(Icons.keyboard_arrow_down, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String hint,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) {
    final display =
        value != null ? '${value.month}/${value.day}/${value.year}' : '';
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                display.isEmpty ? hint : display,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      display.isEmpty ? Colors.grey[400] : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildRedRemoveButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
        ),
        child: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }

  // ── Step dot ──────────────────────────────────────────────────────────

  Widget _buildStepDot(int step) {
    final isCompleted = step < _currentStep;
    final isCurrent = step == _currentStep;
    return Container(
      width: 28,
      height: 28,
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
          ? const Icon(Icons.check, color: Colors.white, size: 16)
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
                      widget.reseller.companyName,
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
                            width: 28,
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        addProductDetails(),
                                        const SizedBox(height: 16),
                                      ],
                                    )
                                  : const SizedBox(height: 44),
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
              height: 52,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == _totalSteps - 1
                      ? const Color(0xFFFFC300)
                      : const Color(0xFF2563EB),
                  foregroundColor: _currentStep == _totalSteps - 1
                      ? Colors.black87
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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

class _ApplianceTypeMeta {
  final String label;
  final String codeField;

  const _ApplianceTypeMeta(this.label, this.codeField);
}

// ── Full-screen search picker ─────────────────────────────────────────────
class _FullScreenSearchPicker extends StatefulWidget {
  final String hint;
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FullScreenSearchPicker({
    required this.hint,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_FullScreenSearchPicker> createState() =>
      _FullScreenSearchPickerState();
}

class _FullScreenSearchPickerState extends State<_FullScreenSearchPicker> {
  String _query = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.hint,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search ${widget.hint}...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return ListTile(
                  title: Text(item, style: const TextStyle(fontSize: 14)),
                  trailing: item == widget.selected
                      ? const Icon(Icons.check, color: Color(0xFFFFC300))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelected(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}