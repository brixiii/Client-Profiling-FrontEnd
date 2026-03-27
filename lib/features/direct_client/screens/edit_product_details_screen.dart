import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/product.dart';

class EditProductDetailsScreen extends StatefulWidget {
  final Map<String, String> product;

  const EditProductDetailsScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<EditProductDetailsScreen> createState() =>
      _EditProductDetailsScreenState();
}

class _EditProductDetailsScreenState extends State<EditProductDetailsScreen> {
  final _api = BackendApi();

  late final TextEditingController _modelCodeController;
  late final TextEditingController _contractDateController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _installationDateController;
  late final TextEditingController _purchaseOrderController;
  late final TextEditingController _deliveryReceiptController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorText;
  Map<String, String> _fieldErrors = {};

  int? _productId;
  int? _clientId;
  int? _employeeId;
  String _unitsofmeasurement = '';
  List<Map<String, dynamic>> _applianceModelRows = const [];
  String? _selectedModelName;
  String? _selectedMachineType;

  List<Employee> _employees = const [];

  String? _employeeName;

  final List<String> _modelNames = [];
  final List<String> _machineTypes = [];
  final List<String> _employeeNames = [];

  @override
  void initState() {
    super.initState();
    _productId = int.tryParse(widget.product['id'] ?? '');
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

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final applianceModelsPage =
          await _api.getApplianceModels(page: 1, perPage: 100);
      final employeesPage = await _api.getEmployees(page: 1, perPage: 100);
      _applianceModelRows = applianceModelsPage.data
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      _employees = employeesPage.data;

      _modelNames
        ..clear()
        ..addAll(
          _applianceModelRows
              .map((row) => _asString(row['model_name']))
              .where((name) => name.isNotEmpty)
              .toSet(),
        );
      _modelNames.sort();

      _employeeNames
        ..clear()
        ..addAll(_employees
            .map((e) => e.name.isNotEmpty ? e.name : 'Employee ${e.id}'));

      if (_productId != null) {
        final product = await _api.getProductById(_productId!);

        _selectedModelName = product.modelName.trim();
        _unitsofmeasurement = product.unitsofmeasurement;
        _selectedMachineType = product.applianceType.trim();
        _clientId = product.clientId;
        _employeeId = product.employeeId;

        _machineTypes
          ..clear()
          ..addAll(_machineTypesForModel(_selectedModelName));

        if (_selectedMachineType != null &&
            !_machineTypes.contains(_selectedMachineType)) {
          _selectedMachineType = null;
        }

        final resolvedCode = _resolveModelCode(
          modelName: _selectedModelName,
          applianceType: _selectedMachineType,
        );
        _modelCodeController.text = resolvedCode ?? product.modelCode;
        _contractDateController.text = _displayDate(product.contractDate);
        _deliveryDateController.text = _displayDate(product.deliveryDate);
        _installationDateController.text =
            _displayDate(product.installmentDate);
        _notesController.text = product.notes;
        if (_selectedModelName != null &&
            !_modelNames.contains(_selectedModelName)) {
          _modelNames.add(_selectedModelName!);
          _modelNames.sort();
        }

        final matched = _employees.where((e) => e.id == _employeeId).toList();
        if (matched.isNotEmpty) {
          _employeeName = matched.first.name;
          if (!_employeeNames.contains(_employeeName)) {
            _employeeNames.add(_employeeName!);
          }
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to load product details.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  if (_errorText != null) ...[
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildLabel('Model Name'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _selectedModelName,
                    items: _modelNames,
                    hint: 'Select Model Name',
                    backendKey: 'model_name',
                    onChanged: _onModelNameChanged,
                  ),
                  const SizedBox(height: 14),
                  _buildLabel('Machine Type'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _selectedMachineType,
                    items: _machineTypes,
                    hint: 'Select Machine Type',
                    backendKey: 'appliance_type',
                    onChanged: _onMachineTypeChanged,
                  ),
                  const SizedBox(height: 14),
                  _buildField('Model Code', _modelCodeController,
                      hint: 'Auto-filled from model + machine', readOnly: true),
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
                  _buildLabel('Employee Name'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _employeeName,
                    items: _employeeNames,
                    hint: 'Select Employee',
                    onChanged: (v) => setState(() => _employeeName = v),
                  ),
                  const SizedBox(height: 14),
                  _buildField('Notes', _notesController, hint: '', maxLines: 6),
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
                if (_isSaving || _isLoading) return;
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
                  await _saveProduct();
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
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_productId == null) {
      setState(() => _errorText = 'Missing product id.');
      return;
    }

    final selectedEmployee =
        _employees.where((e) => e.name == _employeeName).toList();
    if (selectedEmployee.isNotEmpty) {
      _employeeId = selectedEmployee.first.id;
    }

    final guardErrors = <String, String>{};
    if ((_selectedModelName ?? '').trim().isEmpty) {
      guardErrors['model_name'] = 'Model name is required.';
    }
    if ((_selectedMachineType ?? '').trim().isEmpty) {
      guardErrors['appliance_type'] = 'Machine type is required.';
    }
    final expectedCode = _resolveModelCode(
      modelName: _selectedModelName,
      applianceType: _selectedMachineType,
    );
    if ((expectedCode ?? '').trim().isEmpty) {
      guardErrors['model_code'] =
          'Model code does not match selected model/type.';
    }

    if (guardErrors.isNotEmpty) {
      setState(() {
        _fieldErrors = guardErrors;
        _errorText = 'Please fix product model fields.';
      });
      return;
    }

    _modelCodeController.text = expectedCode!;

    final payload = {
      'model_name': (_selectedModelName ?? '').trim(),
      'unitsofmeasurement': _unitsofmeasurement,
      'contract_date': _apiDate(_contractDateController.text),
      'delivery_date': _apiDate(_deliveryDateController.text),
      'installment_date': _apiDate(_installationDateController.text),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'client_id': _clientId,
      'model_code': _modelCodeController.text.trim(),
      'appliance_type': (_selectedMachineType ?? '').trim(),
      'employee_id': _employeeId,
    };

    setState(() {
      _isSaving = true;
      _errorText = null;
      _fieldErrors = {};
    });

    try {
      await _api.updateProduct(id: _productId!, payload: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully.')),
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
      setState(() => _errorText = 'Failed to update product.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _displayDate(String value) {
    if (value.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('MM/dd/yyyy').format(parsed);
  }

  String? _apiDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    DateTime? fromDisplay;
    try {
      fromDisplay = DateFormat('MM/dd/yyyy').parseStrict(text);
    } catch (_) {
      fromDisplay = null;
    }
    if (fromDisplay != null) {
      return DateFormat('yyyy-MM-dd').format(fromDisplay);
    }
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return DateFormat('yyyy-MM-dd').format(parsed);
    }
    return text;
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
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            errorText: _fieldErrors[_toBackendKey(label)],
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
            errorText: _fieldErrors[_toBackendKey(label)],
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
    String? backendKey,
  }) {
    final safeValue = items.contains(value) ? value : null;
    final errorText = backendKey == null ? null : _fieldErrors[backendKey];

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
                  : const Color(0xFFB91C1C),
            ),
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
              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
      ],
    );
  }

  void _onModelNameChanged(String? value) {
    setState(() {
      _selectedModelName = value;
      _machineTypes
        ..clear()
        ..addAll(_machineTypesForModel(_selectedModelName));

      if (!_machineTypes.contains(_selectedMachineType)) {
        _selectedMachineType = null;
      }

      _modelCodeController.text = _resolveModelCode(
            modelName: _selectedModelName,
            applianceType: _selectedMachineType,
          ) ??
          '';
    });
  }

  void _onMachineTypeChanged(String? value) {
    setState(() {
      _selectedMachineType = value;
      _modelCodeController.text = _resolveModelCode(
            modelName: _selectedModelName,
            applianceType: _selectedMachineType,
          ) ??
          '';
    });
  }

  List<String> _machineTypesForModel(String? modelName) {
    final model = _asString(modelName);
    if (model.isEmpty) return const [];

    final types = <String>[];
    for (final row in _applianceModelRows) {
      if (_asString(row['model_name']) != model) continue;
      for (final entry in _applianceTypeMeta.entries) {
        if (_asBool(row[entry.key])) {
          if (!types.contains(entry.value.label)) {
            types.add(entry.value.label);
          }
        }
      }
    }
    return types;
  }

  String? _resolveModelCode({
    required String? modelName,
    required String? applianceType,
  }) {
    final model = _asString(modelName);
    final typeLabel = _asString(applianceType);
    if (model.isEmpty || typeLabel.isEmpty) return null;

    final key = _applianceKeyForLabel(typeLabel);
    if (key == null) return null;
    final meta = _applianceTypeMeta[key];
    if (meta == null) return null;

    for (final row in _applianceModelRows) {
      if (_asString(row['model_name']) != model) continue;
      if (!_asBool(row[key])) continue;
      final code = _asString(row[meta.codeField]);
      if (code.isNotEmpty) return code;
    }
    return null;
  }

  String? _applianceKeyForLabel(String label) {
    for (final entry in _applianceTypeMeta.entries) {
      if (entry.value.label == label) return entry.key;
    }
    return null;
  }

  String _asString(dynamic raw) => (raw ?? '').toString().trim();

  bool _asBool(dynamic raw) {
    if (raw is bool) return raw;
    final v = (raw ?? '').toString().trim().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }

  static const Map<String, _ApplianceTypeMeta> _applianceTypeMeta = {
    'washer': _ApplianceTypeMeta('Washer', 'washer_code'),
    'dryer': _ApplianceTypeMeta('Dryer', 'dryer_code'),
    'styler': _ApplianceTypeMeta('Styler', 'styler_code'),
    'payment_system':
        _ApplianceTypeMeta('Payment System', 'payment_system_code'),
  };

  String _toBackendKey(String label) {
    switch (label) {
      case 'Model Code':
        return 'model_code';
      case 'Contract Date':
        return 'contract_date';
      case 'Delivery Date':
        return 'delivery_date';
      case 'Installation Date':
        return 'installment_date';
      case 'Notes':
        return 'notes';
      default:
        return '';
    }
  }
}

class _ApplianceTypeMeta {
  final String label;
  final String codeField;

  const _ApplianceTypeMeta(this.label, this.codeField);
}
