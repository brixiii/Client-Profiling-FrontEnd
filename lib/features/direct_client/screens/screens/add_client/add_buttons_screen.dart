import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/custom_app_bar.dart';
import '../../../../../shared/api/backend_api.dart';
import '../../../../../shared/api/api_exception.dart';
import '../../../../../shared/api/paginated_response.dart';
import '../../../../../shared/models/availed_service.dart';
import '../../../../../shared/models/employee.dart';
import '../../../../../shared/models/product.dart';
import '../../../../../shared/models/shop.dart';

enum AddMode { client, product, service, shop }

class AddButtonsScreen extends StatefulWidget {
  final AddMode mode;
  final int? initialClientId;
  final int? initialShopId;

  const AddButtonsScreen({
    Key? key,
    required this.mode,
    this.initialClientId,
    this.initialShopId,
  }) : super(key: key);

  @override
  State<AddButtonsScreen> createState() => _AddButtonsScreenState();
}

class _AddButtonsScreenState extends State<AddButtonsScreen> {
  final _api = BackendApi();

  int currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingDependencies = false;
  String? _globalError;
  Map<String, String> _fieldErrors = {};

  int? _selectedClientId;
  String? _selectedClientTypeId;
  int? _selectedEmployeeId;
  int? _selectedShopId;
  String? _selectedServiceTypeId;

  List<Employee> _employees = const [];
  List<Map<String, dynamic>> _serviceTypeRows = const [];

  // ── Client controllers ───────────────────────────────────────────────────
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _clientNotesController = TextEditingController();

  // ── Product controllers ──────────────────────────────────────────────────
  String? _modelName;
  String? _categoryType;
  String? _machineType;
  String? _modelCode;
  String? _uom;
  final _quantityController = TextEditingController(text: '1');
  final _modelCodeController = TextEditingController();
  List<Map<String, dynamic>> _applianceModelRows = const [];
  final _purchaseOrderController = TextEditingController();
  final _deliveryReceiptController = TextEditingController();
  final _serialNumberController = TextEditingController();
  DateTime? _contractDate;
  DateTime? _deliveryDate;
  DateTime? _installationDate;
  final _laborPlanController = TextEditingController();
  final _productNotesController = TextEditingController();

  // ── Shop controllers ───────────────────────────────────────────────────
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  String? _shopType;
  final _pinCoordsController = TextEditingController();
  final _googleMapsController = TextEditingController();
  final _shopContactPersonController = TextEditingController();
  final _shopContactNoController = TextEditingController();
  final _shopViberNoController = TextEditingController();
  final _shopContactEmailController = TextEditingController();
  final _shopNotesController = TextEditingController();

  // ── Service controllers ──────────────────────────────────────────────────
  final _reportNoController = TextEditingController();
  String? _subType;
  String? _chosenFileName;
  final _serviceOrderReportNoController = TextEditingController();
  String? _serviceType;
  String? _selectedSerialNumber;
  String? _selectedSparePart;
  final _serviceQuantityController = TextEditingController(text: '1');
  DateTime? _serviceDate;
  final List<String?> _selectedTechnicians = [null];
  final List<String> _technicianOptions = [];
  final _serviceNotesController = TextEditingController();

  // ── UI option lists ──────────────────────────────────────────────────────
  final List<String> _modelNames = [];
  final List<String> _categoryTypes = [];
  final List<String> _machineTypes = [];
  final List<String> _uomOptions = [];
  final List<String> _shopTypes = [];
  final Map<String, String> _shopTypeIds = {};
  final List<String> _subTypes = [];
  final List<String> _serviceTypes = [];
  final List<String> _serialNumbers = [];
  final List<String> _spareParts = [];
  static const List<String> _supplierTypeOptions = [
    'Bulla Crave',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _clientNotesController.dispose();
    _modelCodeController.dispose();
    _quantityController.dispose();
    _purchaseOrderController.dispose();
    _deliveryReceiptController.dispose();
    _serialNumberController.dispose();
    _laborPlanController.dispose();
    _productNotesController.dispose();
    _reportNoController.dispose();
    _serviceOrderReportNoController.dispose();
    _serviceQuantityController.dispose();
    _serviceNotesController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _pinCoordsController.dispose();
    _googleMapsController.dispose();
    _shopContactPersonController.dispose();
    _shopContactNoController.dispose();
    _shopViberNoController.dispose();
    _shopContactEmailController.dispose();
    _shopNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadDependencies() async {
    setState(() {
      _isLoadingDependencies = true;
      _globalError = null;
    });

    try {
      // Run all dependency fetches in parallel; each is isolated so a single
      // failing endpoint does not prevent the others from loading.
      final results = await Future.wait([
        _api.getClients(page: 1, perPage: 100).catchError((_) =>
            PaginatedResponse<Map<String, dynamic>>(
                data: const [],
                currentPage: 1,
                perPage: 100,
                total: 0,
                lastPage: 1,
                links: const [])),
        _api.getEmployees(page: 1, perPage: 100).catchError((_) =>
            PaginatedResponse<Employee>(
                data: const [],
                currentPage: 1,
                perPage: 100,
                total: 0,
                lastPage: 1,
                links: const [])),
        _api.getShops(page: 1, perPage: 100).catchError((_) =>
            PaginatedResponse<Shop>(
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
        _api.getApplianceModels(page: 1, perPage: 100).catchError((_) =>
            PaginatedResponse<Map<String, dynamic>>(
                data: const [],
                currentPage: 1,
                perPage: 100,
                total: 0,
                lastPage: 1,
                links: const [])),
        _api.getAvailedServices(page: 1, perPage: 200).catchError((_) =>
            PaginatedResponse<AvailedService>(
                data: const [],
                currentPage: 1,
                perPage: 200,
                total: 0,
                lastPage: 1,
                links: const [])),
        _api.getServiceTypes(page: 1, perPage: 100).catchError((_) =>
            PaginatedResponse<Map<String, dynamic>>(
                data: const [],
                currentPage: 1,
                perPage: 100,
                total: 0,
                lastPage: 1,
                links: const [])),
      ]);

      if (!mounted) return;

      final clients =
          (results[0] as PaginatedResponse<Map<String, dynamic>>).data;
      final employees = (results[1] as PaginatedResponse<Employee>).data;
      final shops = (results[2] as PaginatedResponse<Shop>).data;
      final products = (results[3] as PaginatedResponse<Product>).data;
      final applianceModels =
          (results[4] as PaginatedResponse<Map<String, dynamic>>).data;
      final availedServices =
          (results[5] as PaginatedResponse<AvailedService>).data;
      final serviceTypes =
          (results[6] as PaginatedResponse<Map<String, dynamic>>).data;
      final validServiceTypeRows = serviceTypes
          .where((row) {
            final serviceTypeName = row['setypename']?.toString().trim() ?? '';
            final id = row['id']?.toString().trim() ?? '';
            return serviceTypeName.isNotEmpty && id.isNotEmpty;
          })
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      List<String> collectUnique(Iterable<String> values) {
        final byKey = <String, String>{};
        for (final raw in values) {
          final value = raw.trim();
          if (value.isEmpty) continue;
          final key = value.toLowerCase();
          byKey.putIfAbsent(key, () => value);
        }
        final out = byKey.values.toList()..sort();
        return out;
      }

      final availableClientIds = clients
          .map((row) => int.tryParse((row['id'] ?? '').toString()))
          .whereType<int>()
          .toSet();
      final availableClientTypeIds = clients
          .map((row) {
            final raw = row['client_type_id'];
            return (raw ?? '').toString().trim();
          })
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final derivedResellerTypes = collectUnique(
        clients.map((row) {
          final candidates = [
            row['reseller_type_name'],
            row['reseller_type'],
            row['client_type_name'],
            row['client_type'],
          ];

          for (final candidate in candidates) {
            final text = (candidate ?? '').toString().trim();
            if (text.isNotEmpty) return text;
          }
          return '';
        }),
      );
      final availableShopIds = shops.map((shop) => shop.id).toSet();
      final derivedShopTypes = <String, String>{
        for (final shop in shops)
          if (shop.shopTypeId.trim().isNotEmpty && shop.shopTypeId != '0')
            shop.shopTypeId: shop.shopTypeId,
      };
      final derivedModelNames = collectUnique(
          applianceModels.map((row) => _asString(row['model_name'])));
      final derivedApplianceTypes =
          collectUnique(products.map((Product p) => p.applianceType));
      final derivedUom = _sanitizeUomOptions(
        products.map((Product p) => p.unitsofmeasurement),
      );
      final derivedSerialNumbers = collectUnique(
        availedServices.map((AvailedService s) => s.serialNumberId),
      );
      final derivedServiceTypes = validServiceTypeRows
          .map((row) => row['setypename']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      setState(() {
        _employees = employees;
        _serviceTypeRows = validServiceTypeRows;
        _applianceModelRows = applianceModels
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

        _modelNames
          ..clear()
          ..addAll(derivedModelNames);
        _categoryTypes
          ..clear()
          ..addAll(
            derivedResellerTypes.isNotEmpty
                ? derivedResellerTypes
                : availableClientTypeIds,
          );
        _machineTypes
          ..clear()
          ..addAll(derivedApplianceTypes);
        _uomOptions
          ..clear()
          ..addAll(derivedUom);
        _serialNumbers
          ..clear()
          ..addAll(derivedSerialNumbers);

        _shopTypeIds
          ..clear()
          ..addAll(derivedShopTypes);
        _shopTypes
          ..clear()
          ..addAll(_shopTypeIds.keys);

        final initialClientId = widget.initialClientId;
        if (initialClientId != null) {
          _selectedClientId = initialClientId;
        } else {
          _selectedClientId = availableClientIds.contains(_selectedClientId)
              ? _selectedClientId
              : null;
        }

        _selectedClientTypeId =
            availableClientTypeIds.contains(_selectedClientTypeId)
                ? _selectedClientTypeId
                : (availableClientTypeIds.isNotEmpty
                    ? availableClientTypeIds.first
                    : null);
        _selectedEmployeeId = employees.isNotEmpty ? employees.first.id : null;

        final initialShopId = widget.initialShopId;
        if (initialShopId != null) {
          _selectedShopId = initialShopId;
        } else {
          _selectedShopId = availableShopIds.contains(_selectedShopId)
              ? _selectedShopId
              : null;
        }

        _modelName = _modelNames.contains(_modelName) ? _modelName : null;
        _categoryType =
            _supplierTypeOptions.contains(_categoryType) ? _categoryType : null;

        _machineTypes
          ..clear()
          ..addAll(_machineTypesForModel(_modelName));
        _machineType =
            _machineTypes.contains(_machineType) ? _machineType : null;
        _modelCode = _resolveModelCode(
          modelName: _modelName,
          applianceType: _machineType,
        );
        _modelCodeController.text = _modelCode ?? '';
        _uom = _uomOptions.contains(_uom) ? _uom : null;
        _shopType = _shopTypes.contains(_shopType)
            ? _shopType
            : (_shopTypes.isNotEmpty ? _shopTypes.first : null);
        _selectedSerialNumber = _serialNumbers.contains(_selectedSerialNumber)
            ? _selectedSerialNumber
            : null;
        _selectedSparePart = _spareParts.contains(_selectedSparePart)
            ? _selectedSparePart
            : null;
        _subType = _subTypes.contains(_subType) ? _subType : null;

        if (_serviceTypeRows.isNotEmpty) {
          _selectedServiceTypeId =
              _serviceTypeIdFromRow(_serviceTypeRows.first);
        } else {
          _selectedServiceTypeId = null;
        }

        _technicianOptions
          ..clear()
          ..addAll(
            employees
                .map((e) => e.name.isNotEmpty ? e.name : 'Employee ${e.id}')
                .toList(),
          );
        _selectedTechnicians[0] =
            _technicianOptions.isNotEmpty ? _technicianOptions.first : null;

        _serviceTypes
          ..clear()
          ..addAll(derivedServiceTypes);
        if (_serviceTypes.isNotEmpty) {
          _serviceType = _serviceTypes.first;
        } else {
          _serviceType = null;
        }

        _isLoadingDependencies = false;
      });
    } catch (_) {
      // Unexpected error outside per-call isolation (e.g. setState after dispose).
      if (!mounted) return;
      setState(() => _isLoadingDependencies = false);
    }
  }

  void _nextStep() {
    if (!_validateStepBeforeProceed()) {
      return;
    }

    if (currentStep < 3) {
      setState(() => currentStep++);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateStepBeforeProceed() {
    final errors = <String, String>{};

    switch (widget.mode) {
      case AddMode.client:
        if (currentStep == 0) {
          if (_firstNameController.text.trim().isEmpty) {
            errors['cfirstname'] = 'First name is required.';
          }
          if (_lastNameController.text.trim().isEmpty) {
            errors['csurname'] = 'Last name is required.';
          }
        }
        if (currentStep == 2) {
          _validateRequiredPhone(
            key: 'cphonenum',
            label: 'Phone number',
            value: _phoneController.text,
            errors: errors,
          );
        }
        break;
      case AddMode.product:
        if (currentStep == 0) {
          if ((_modelName ?? '').trim().isEmpty) {
            errors['model_name'] = 'Model name is required.';
          }
          if ((_machineType ?? '').trim().isEmpty) {
            errors['appliance_type'] = 'Machine type is required.';
          }
          if ((_modelCode ?? '').trim().isEmpty) {
            errors['model_code'] = 'Model code is required.';
          }
          if ((_uom ?? '').trim().isEmpty) {
            errors['unitsofmeasurement'] = 'UOM is required.';
          }
        }
        if (currentStep == 2 && _contractDate == null) {
          errors['contract_date'] = 'Contract date is required.';
        }
        break;
      case AddMode.service:
        if (currentStep == 0 && (_selectedServiceTypeId ?? '').trim().isEmpty) {
          errors['service_type_id'] = 'Service type is required.';
        }
        if (currentStep == 1 && _serviceDate == null) {
          errors['service_date'] = 'Service date is required.';
        }
        break;
      case AddMode.shop:
        if (currentStep == 0) {
          if (_shopNameController.text.trim().isEmpty) {
            errors['shopname'] = 'Shop name is required.';
          }
          if (_shopAddressController.text.trim().isEmpty) {
            errors['saddress'] = 'Shop address is required.';
          }
          if ((_shopTypeIds[_shopType] ?? '').trim().isEmpty) {
            errors['shop_type_id'] = 'Shop type is required.';
          }
        }
        if (currentStep == 2) {
          if (_shopContactPersonController.text.trim().isEmpty) {
            errors['scontactperson'] = 'Contact person is required.';
          }
          _validateRequiredPhone(
            key: 'scontactnum',
            label: 'Contact number',
            value: _shopContactNoController.text,
            errors: errors,
          );
          _validateRequiredPhone(
            key: 'svibernum',
            label: 'Viber number',
            value: _shopViberNoController.text,
            errors: errors,
          );
          final email = _shopContactEmailController.text.trim();
          if (email.isNotEmpty && !_isValidEmail(email)) {
            errors['semailaddress'] = 'Enter a valid email address.';
          }
        }
        break;
    }

    if (errors.isEmpty) {
      if (_fieldErrors.isNotEmpty || _globalError != null) {
        setState(() {
          _fieldErrors = {};
          _globalError = null;
        });
      }
      return true;
    }

    setState(() {
      _fieldErrors = errors;
      _globalError = 'Please fix the highlighted fields before proceeding.';
    });
    return false;
  }

  bool _validateAllBeforeConfirm() {
    Map<String, String> errors;
    switch (widget.mode) {
      case AddMode.client:
        errors = _validateClient();
        break;
      case AddMode.product:
        errors = _validateProduct();
        break;
      case AddMode.service:
        errors = _validateService();
        break;
      case AddMode.shop:
        errors = _validateShop();
        break;
    }

    if (errors.isEmpty) {
      return true;
    }

    setState(() {
      _fieldErrors = errors;
      _globalError = 'Please fix the highlighted fields before submitting.';
    });
    return false;
  }

  // ── ADD CLIENT STEP CONTENT ──────────────────────────────────────────────

  Widget addClientDetails() {
    const titles = [
      'Personal Information',
      'Company Details',
      'Contact Details',
      'Additional Notes',
    ];

    Widget content;
    switch (currentStep) {
      case 0:
        content = Column(
          children: [
            _buildTextField(_firstNameController,
                hint: 'First Name', errorText: _fieldErrors['cfirstname']),
            const SizedBox(height: 16),
            _buildTextField(_middleNameController, hint: 'Middle Name'),
            const SizedBox(height: 16),
            _buildTextField(_lastNameController,
                hint: 'Last Name', errorText: _fieldErrors['csurname']),
          ],
        );
        break;
      case 1:
        content = _buildTextField(_companyNameController, hint: 'Company Name');
        break;
      case 2:
        content = Column(
          children: [
            _buildTextField(_emailController, hint: 'Email Address (Optional)'),
            const SizedBox(height: 16),
            _buildTextField(_phoneController,
                hint: 'Phone Number',
                errorText: _fieldErrors['cphonenum'],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                maxLength: 11),
            if (_fieldErrors['client_type_id'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _fieldErrors['client_type_id']!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
          ],
        );
        break;
      case 3:
        content =
            _buildTextField(_clientNotesController, hint: 'Notes', maxLines: 6);
        break;
      default:
        content = const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titles[currentStep],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        content,
      ],
    );
  }

  // ── ADD PRODUCT STEP CONTENT ─────────────────────────────────────────────

  Widget addProductDetails() {
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            _buildDropdown('Select Model Name', _modelName, _modelNames,
                (v) => _onModelNameChanged(v),
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
            _buildDropdown('Select supplier type', _categoryType,
                _supplierTypeOptions, (v) => setState(() => _categoryType = v)),
            const SizedBox(height: 12),
            _buildDropdown('Machine Type', _machineType, _machineTypes,
                (v) => _onMachineTypeChanged(v),
                errorText: _fieldErrors['appliance_type']),
            const SizedBox(height: 12),
            _buildTextField(
              _modelCodeController,
              hint: 'Model Code',
              readOnly: true,
              errorText: _fieldErrors['model_code'],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
                'UOM', _uom, _uomOptions, (v) => setState(() => _uom = v),
                errorText: _fieldErrors['unitsofmeasurement']),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildSpinnerField('Quantity', _quantityController),
            const SizedBox(height: 12),
            _buildTextField(_purchaseOrderController,
                hint: 'Purchase Order (Optional)'),
            const SizedBox(height: 12),
            _buildTextField(_deliveryReceiptController,
                hint: 'Delivery Receipt (Optional)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_serialNumberController,
                      hint: 'Serial Number'),
                ),
                const SizedBox(width: 8),
                _buildIconButton(Icons.add, () {}),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildDateField('Contract Date', _contractDate,
                (d) => setState(() => _contractDate = d)),
            if (_fieldErrors['contract_date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _fieldErrors['contract_date']!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            const SizedBox(height: 12),
            _buildDateField('Delivery Date', _deliveryDate,
                (d) => setState(() => _deliveryDate = d)),
            const SizedBox(height: 12),
            _buildDateField('Installation Date', _installationDate,
                (d) => setState(() => _installationDate = d)),
            const SizedBox(height: 12),
            _buildTextField(_laborPlanController,
                hint: 'Sales Person', errorText: _fieldErrors['employee_id']),
          ],
        );
      case 3:
        return _buildTextField(_productNotesController,
            hint: 'Notes', maxLines: 7);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── ADD SERVICE STEP CONTENT ─────────────────────────────────────────────

  Widget addServicesDetails() {
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            // Choose File button
            InkWell(
              onTap: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.isNotEmpty) {
                  setState(() => _chosenFileName = result.files.single.name);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _chosenFileName ?? 'Choose File',
                        style: TextStyle(
                          fontSize: 14,
                          color: _chosenFileName != null
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                    Icon(Icons.attach_file, size: 18, color: Colors.grey[500]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown('Sub Type', _subType, _subTypes,
                (v) => setState(() => _subType = v)),
            const SizedBox(height: 12),
            _buildTextField(_serviceOrderReportNoController,
                hint: 'Service Order Report No.'),
            const SizedBox(height: 12),
            _buildDropdown('Select Service Type', _serviceType, _serviceTypes,
                (v) {
              setState(() {
                _serviceType = v;
                final idx = _serviceTypes.indexOf(v ?? '');
                if (idx >= 0 && idx < _serviceTypeRows.length) {
                  _selectedServiceTypeId =
                      _serviceTypeIdFromRow(_serviceTypeRows[idx]);
                }
              });
            }, errorText: _fieldErrors['service_type_id']),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildDropdown(
                'Select Serial Number',
                _selectedSerialNumber,
                _serialNumbers,
                (v) => setState(() => _selectedSerialNumber = v)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                      'Select Spare Part',
                      _selectedSparePart,
                      _spareParts,
                      (v) => setState(() => _selectedSparePart = v)),
                ),
                const SizedBox(width: 8),
                _buildIconButton(Icons.add, () {}),
              ],
            ),
            const SizedBox(height: 12),
            _buildSpinnerField('Quantity', _serviceQuantityController),
            const SizedBox(height: 12),
            _buildDateField('Service Date', _serviceDate,
                (d) => setState(() => _serviceDate = d)),
            if (_fieldErrors['service_date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _fieldErrors['service_date']!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add More Serial Number',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._selectedTechnicians.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDropdown(
                  'Technician',
                  _selectedTechnicians[i],
                  _technicianOptions,
                  (v) => setState(() {
                    _selectedTechnicians[i] = v;
                    final match = _employees.cast<Employee?>().firstWhere(
                          (e) => e != null && e.name == v,
                          orElse: () => null,
                        );
                    _selectedEmployeeId = match?.id;
                  }),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedTechnicians.add(null)),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+ Add More', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );
      case 3:
        return _buildTextField(_serviceNotesController,
            hint: 'Notes', maxLines: 7);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── ADD SHOP STEP CONTENT ─────────────────────────────────────────────────

  Widget addShopDetails() {
    switch (currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shop Information',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 14),
            _buildTextField(_shopNameController,
                hint: 'Shop Name', errorText: _fieldErrors['shopname']),
            const SizedBox(height: 12),
            _buildTextField(_shopAddressController,
                hint: 'Shop Address', errorText: _fieldErrors['saddress']),
            const SizedBox(height: 12),
            _buildDropdown('Shop Type', _shopType, _shopTypes,
                (v) => setState(() => _shopType = v),
                errorText: _fieldErrors['shop_type_id']),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 14),
            _buildTextField(_pinCoordsController, hint: 'Pin Coordinates'),
            const SizedBox(height: 12),
            _buildTextField(_googleMapsController, hint: 'Google Maps Link'),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Information',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 14),
            _buildTextField(_shopContactPersonController,
                hint: 'Contact Person',
                errorText: _fieldErrors['scontactperson']),
            const SizedBox(height: 12),
            _buildTextField(_shopContactNoController,
                hint: 'Contact No.',
                errorText: _fieldErrors['scontactnum'],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                maxLength: 11),
            const SizedBox(height: 12),
            _buildTextField(_shopViberNoController,
                hint: 'Viber No.',
                errorText: _fieldErrors['svibernum'],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                maxLength: 11),
            const SizedBox(height: 12),
            _buildTextField(_shopContactEmailController,
                hint: 'Email Address',
                errorText: _fieldErrors['semailaddress']),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Additional Notes',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 14),
            _buildTextField(_shopNotesController, hint: 'Notes', maxLines: 7),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isClient = widget.mode == AddMode.client;
    final bool isLastStep = currentStep == 3;

    final String title = isClient
        ? 'Add Client'
        : widget.mode == AddMode.product
            ? 'Add Product'
            : widget.mode == AddMode.service
                ? 'Add Service'
                : 'Add Shop';

    // Client uses blue indicators; product/service use amber
    final Color activeColor =
        isClient ? const Color(0xFF2563EB) : const Color(0xFFFFC300);

    return Scaffold(
      backgroundColor: isClient ? Colors.white : const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
                if (isClient) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF2563EB).withOpacity(0.35)),
                    ),
                    child: Text(
                      'Step ${currentStep + 1} of 4',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Stepper
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(4, (step) {
                    final bool isActive = step == currentStep;
                    final bool isLast = step == 3;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: circle + connector
                          SizedBox(
                            width: 28,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: step <= currentStep
                                      ? () => setState(() => currentStep = step)
                                      : null,
                                  child: _buildStepIndicator(step, activeColor),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        color: step < currentStep
                                            ? activeColor
                                            : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: isClient ? 24 : 20),

                          // Right: form content
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                              child: isActive
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildActiveContent(),
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

            // Bottom button
            if (isClient)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isLoadingDependencies
                      ? null
                      : (isLastStep ? _showConfirmDialog : _nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastStep ? 'Add Client' : 'Next',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else if (isLastStep)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isLoadingDependencies
                      ? null
                      : _showConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Submit',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isLoadingDependencies
                      ? null
                      : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Next',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

            if (_globalError != null) ...[
              const SizedBox(height: 12),
              Text(
                _globalError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog() {
    if (!_validateStepBeforeProceed()) {
      return;
    }
    if (!_validateAllBeforeConfirm()) {
      return;
    }

    List<Widget> rows;

    switch (widget.mode) {
      case AddMode.client:
        final nameParts = [
          _firstNameController.text,
          _middleNameController.text,
          _lastNameController.text,
        ].where((s) => s.isNotEmpty).join(' ');
        rows = [
          _summaryRow('Name', nameParts.isEmpty ? '-' : nameParts),
          _summaryRow(
              'Company Name',
              _companyNameController.text.isEmpty
                  ? '-'
                  : _companyNameController.text),
          _summaryRow('Email',
              _emailController.text.isEmpty ? '-' : _emailController.text),
          _summaryRow('Phone No.',
              _phoneController.text.isEmpty ? '-' : _phoneController.text),
        ];
        break;
      case AddMode.product:
        rows = [
          _summaryRow('Model Name', _modelName ?? '-'),
          _summaryRow('Supplier Type', _categoryType ?? '-'),
          _summaryRow('Machine Type', _machineType ?? '-'),
          _summaryRow('Model Code', _modelCode ?? '-'),
          _summaryRow('UOM', _uom ?? '-'),
          _summaryRow('Quantity', _quantityController.text),
          _summaryRow(
              'Purchase Order',
              _purchaseOrderController.text.isEmpty
                  ? '-'
                  : _purchaseOrderController.text),
          _summaryRow(
              'Delivery Receipt',
              _deliveryReceiptController.text.isEmpty
                  ? '-'
                  : _deliveryReceiptController.text),
        ];
        break;
      case AddMode.service:
        rows = [
          _summaryRow('File', _chosenFileName ?? '-'),
          _summaryRow('Sub Type', _subType ?? '-'),
          _summaryRow('Service Type', _serviceType ?? '-'),
          _summaryRow('Serial Number', _selectedSerialNumber ?? '-'),
          _summaryRow('Spare Part', _selectedSparePart ?? '-'),
          _summaryRow('Quantity', _serviceQuantityController.text),
        ];
        break;
      case AddMode.shop:
        rows = [
          _summaryRow(
              'Shop Name',
              _shopNameController.text.isEmpty
                  ? '-'
                  : _shopNameController.text),
          _summaryRow(
              'Shop Address',
              _shopAddressController.text.isEmpty
                  ? '-'
                  : _shopAddressController.text),
          _summaryRow('Shop Type', _shopType ?? '-'),
          _summaryRow(
              'Contact Person',
              _shopContactPersonController.text.isEmpty
                  ? '-'
                  : _shopContactPersonController.text),
          _summaryRow(
              'Contact No.',
              _shopContactNoController.text.isEmpty
                  ? '-'
                  : _shopContactNoController.text),
          _summaryRow(
              'Email',
              _shopContactEmailController.text.isEmpty
                  ? '-'
                  : _shopContactEmailController.text),
        ];
        break;
    }

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
            ...rows,
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _submitCurrentMode();
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCurrentMode() async {
    if (widget.mode == AddMode.client) {
      await _submitClient();
      return;
    }

    if (widget.mode == AddMode.product) {
      await _submitProduct();
      return;
    }

    if (widget.mode == AddMode.service) {
      await _submitService();
      return;
    }

    if (widget.mode == AddMode.shop) {
      await _submitShop();
      return;
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _submitClient() async {
    setState(() {
      _globalError = null;
      _fieldErrors = {};
    });

    final guardErrors = _validateClient();
    if (guardErrors.isNotEmpty) {
      setState(() {
        _fieldErrors = guardErrors;
        _globalError = 'Please complete required client fields.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _globalError = null;
    });

    final payload = <String, dynamic>{
      'cfirstname': _firstNameController.text.trim(),
      'cmiddlename': _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      'csurname': _lastNameController.text.trim(),
      'client_type_id': _selectedClientTypeId,
      'ccompanyname': _companyNameController.text.trim().isEmpty
          ? null
          : _companyNameController.text.trim(),
      'cemail': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'cphonenum': _phoneController.text.trim(),
      'notes': _clientNotesController.text.trim().isEmpty
          ? null
          : _clientNotesController.text.trim(),
      'address': null,
    };

    try {
      await _api.createClient(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client added successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _applyApiValidationErrors(e, fallbackMessage: 'Failed to add client.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _globalError = 'Failed to add client.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitShop() async {
    setState(() {
      _globalError = null;
      _fieldErrors = {};
    });

    final guardErrors = _validateShop();
    if (guardErrors.isNotEmpty) {
      setState(() {
        _fieldErrors = guardErrors;
        _globalError = 'Please complete required shop fields.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _globalError = null;
    });

    final selectedShopTypeId = _shopTypeIds[_shopType]?.trim();

    final payload = <String, dynamic>{
      'shopname': _shopNameController.text.trim(),
      'saddress': _shopAddressController.text.trim(),
      'shop_type_id': selectedShopTypeId,
      'pin_location': _pinCoordsController.text.trim().isEmpty
          ? null
          : _pinCoordsController.text.trim(),
      'location_link': _googleMapsController.text.trim().isEmpty
          ? null
          : _googleMapsController.text.trim(),
      'scontactperson': _shopContactPersonController.text.trim(),
      'scontactnum': _shopContactNoController.text.trim(),
      'svibernum': _shopViberNoController.text.trim(),
      'semailaddress': _shopContactEmailController.text.trim().isEmpty
          ? null
          : _shopContactEmailController.text.trim(),
      'notes': _shopNotesController.text.trim().isEmpty
          ? null
          : _shopNotesController.text.trim(),
      'client_id': _resolveScopedClientId(),
    };

    try {
      await _api.createShop(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop added successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _applyApiValidationErrors(e, fallbackMessage: 'Failed to add shop.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _globalError = 'Failed to add shop.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitProduct() async {
    setState(() {
      _globalError = null;
      _fieldErrors = {};
    });

    final guardErrors = _validateProduct();
    if (guardErrors.isNotEmpty) {
      setState(() {
        _fieldErrors = guardErrors;
        _globalError = 'Please complete required product fields.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _globalError = null;
    });

    final payload = <String, dynamic>{
      'model_name': (_modelName ?? '').trim(),
      'unitsofmeasurement': (_uom ?? '').trim(),
      'contract_date': _formatDate(_contractDate),
      'delivery_date': _formatDate(_deliveryDate),
      'installment_date': _formatDate(_installationDate),
      'notes': _productNotesController.text.trim().isEmpty
          ? null
          : _productNotesController.text.trim(),
      'client_id': _resolveScopedClientId(),
      'model_code': (_modelCode ?? '').trim(),
      'appliance_type': (_machineType ?? '').trim(),
      'employee_id': _selectedEmployeeId,
    };

    final scopedShopId = _resolveScopedShopId();
    if (scopedShopId == null) {
      setState(() {
        _globalError = 'Shop is required before adding product.';
        _fieldErrors = {
          ..._fieldErrors,
          'shop_id': 'Shop is required.',
        };
      });
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;

    try {
      final createdProduct = await _api.createProduct(payload);

      await _api.createShopProduct({
        'shop_id': scopedShopId,
        'client_id': _resolveScopedClientId(),
        'product_id': createdProduct.id,
        'quantity': quantity < 1 ? 1 : quantity,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      final productError = e.fieldErrors['product_id']?.toLowerCase() ?? '';
      final isDuplicateLink =
          e.statusCode == 422 && productError.contains('already linked');

      if (isDuplicateLink) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This product is already linked to the selected shop.'),
          ),
        );
      }
      _applyApiValidationErrors(e, fallbackMessage: 'Failed to add product.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _globalError = 'Failed to add product.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitService() async {
    setState(() {
      _globalError = null;
      _fieldErrors = {};
    });

    final guardErrors = _validateService();
    if (guardErrors.isNotEmpty) {
      setState(() {
        _fieldErrors = guardErrors;
        _globalError = 'Please complete required service fields.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _globalError = null;
    });

    final payload = <String, dynamic>{
      'notes': _serviceNotesController.text.trim().isEmpty
          ? null
          : _serviceNotesController.text.trim(),
      'service_date': _formatDate(_serviceDate),
      'image': _chosenFileName,
      'serial_number_id': _selectedSerialNumber,
      'control_number': _serviceOrderReportNoController.text.trim().isEmpty
          ? null
          : _serviceOrderReportNoController.text.trim(),
      'service_type_id': (_selectedServiceTypeId ?? '').trim(),
      'employee_id': _selectedEmployeeId,
      'client_id': _resolveScopedClientId(),
      'shop_id': _resolveScopedShopId(),
    };

    try {
      await _api.createAvailedService(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service added successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _applyApiValidationErrors(e, fallbackMessage: 'Failed to add service.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _globalError = 'Failed to add service.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  int? _resolveScopedClientId() {
    return widget.initialClientId ?? _selectedClientId;
  }

  int? _resolveScopedShopId() {
    return widget.initialShopId ?? _selectedShopId;
  }

  Map<String, String> _validateClient() {
    final errors = <String, String>{};
    if (_firstNameController.text.trim().isEmpty) {
      errors['cfirstname'] = 'First name is required.';
    }
    if (_lastNameController.text.trim().isEmpty) {
      errors['csurname'] = 'Last name is required.';
    }
    _validateRequiredPhone(
      key: 'cphonenum',
      label: 'Phone number',
      value: _phoneController.text,
      errors: errors,
    );
    if ((_selectedClientTypeId ?? '').trim().isEmpty) {
      errors['client_type_id'] = 'Client type is required.';
    }
    return errors;
  }

  Map<String, String> _validateProduct() {
    final errors = <String, String>{};
    if ((_modelName ?? '').trim().isEmpty) {
      errors['model_name'] = 'Model name is required.';
    }
    if ((_uom ?? '').trim().isEmpty) {
      errors['unitsofmeasurement'] = 'UOM is required.';
    }
    if (_contractDate == null) {
      errors['contract_date'] = 'Contract date is required.';
    }
    if (_resolveScopedClientId() == null) {
      errors['client_id'] = 'Client is required.';
    }
    if (_resolveScopedShopId() == null) {
      errors['shop_id'] = 'Shop is required.';
    }
    if ((_modelCode ?? '').trim().isEmpty) {
      errors['model_code'] = 'Model code is required.';
    }
    if ((_machineType ?? '').trim().isEmpty) {
      errors['appliance_type'] = 'Appliance type is required.';
    }
    final expectedCode = _resolveModelCode(
      modelName: _modelName,
      applianceType: _machineType,
    );
    if ((_machineType ?? '').trim().isNotEmpty &&
        (expectedCode == null || expectedCode.trim().isEmpty)) {
      errors['model_code'] = 'Model code does not match selected model/type.';
    }
    if (_selectedEmployeeId == null) {
      errors['employee_id'] = 'Employee is required.';
    }
    return errors;
  }

  void _onModelNameChanged(String? value) {
    setState(() {
      _modelName = value;
      _machineTypes
        ..clear()
        ..addAll(_machineTypesForModel(_modelName));

      if (!_machineTypes.contains(_machineType)) {
        _machineType = null;
      }

      _modelCode = _resolveModelCode(
        modelName: _modelName,
        applianceType: _machineType,
      );
      _modelCodeController.text = _modelCode ?? '';
    });
  }

  void _onMachineTypeChanged(String? value) {
    setState(() {
      _machineType = value;
      _modelCode = _resolveModelCode(
        modelName: _modelName,
        applianceType: _machineType,
      );
      _modelCodeController.text = _modelCode ?? '';
    });
  }

  List<String> _machineTypesForModel(String? modelName) {
    final model = (modelName ?? '').trim();
    if (model.isEmpty) return const [];

    final ordered = <String>[];
    for (final row in _applianceModelRows) {
      if (_asString(row['model_name']) != model) continue;

      for (final entry in _applianceTypeMeta.entries) {
        final key = entry.key;
        if (_asBool(row[key])) {
          final label = entry.value.label;
          if (!ordered.contains(label)) {
            ordered.add(label);
          }
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
    final value = (raw ?? '').toString().trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes';
  }

  static const Map<String, _ApplianceTypeMeta> _applianceTypeMeta = {
    'washer': _ApplianceTypeMeta('Washer', 'washer_code'),
    'dryer': _ApplianceTypeMeta('Dryer', 'dryer_code'),
    'styler': _ApplianceTypeMeta('Styler', 'styler_code'),
    'payment_system':
        _ApplianceTypeMeta('Payment System', 'payment_system_code'),
  };

  Map<String, String> _validateService() {
    final errors = <String, String>{};
    if (_serviceDate == null) {
      errors['service_date'] = 'Service date is required.';
    }
    if ((_selectedServiceTypeId ?? '').trim().isEmpty) {
      errors['service_type_id'] = 'Service type is required.';
    }
    if (_resolveScopedClientId() == null) {
      errors['client_id'] = 'Client is required.';
    }
    return errors;
  }

  Map<String, String> _validateShop() {
    final errors = <String, String>{};
    if (_shopNameController.text.trim().isEmpty) {
      errors['shopname'] = 'Shop name is required.';
    }
    if (_shopAddressController.text.trim().isEmpty) {
      errors['saddress'] = 'Shop address is required.';
    }
    _validateRequiredPhone(
      key: 'svibernum',
      label: 'Viber number',
      value: _shopViberNoController.text,
      errors: errors,
    );
    if (_shopContactPersonController.text.trim().isEmpty) {
      errors['scontactperson'] = 'Contact person is required.';
    }
    _validateRequiredPhone(
      key: 'scontactnum',
      label: 'Contact number',
      value: _shopContactNoController.text,
      errors: errors,
    );
    if ((_shopTypeIds[_shopType] ?? '').trim().isEmpty) {
      errors['shop_type_id'] = 'Shop type is required.';
    }
    if (_resolveScopedClientId() == null) {
      errors['client_id'] = 'Client is required.';
    }
    final email = _shopContactEmailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      errors['semailaddress'] = 'Enter a valid email address.';
    }
    return errors;
  }

  bool _isValidEmail(String email) {
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(email);
  }

  void _validateRequiredPhone({
    required String key,
    required String label,
    required String value,
    required Map<String, String> errors,
  }) {
    final text = value.trim();
    if (text.isEmpty) {
      errors[key] = '$label is required.';
      return;
    }
    if (!RegExp(r'^\d{11}$').hasMatch(text)) {
      errors[key] = '$label must be exactly 11 digits.';
    }
  }

  List<String> _sanitizeUomOptions(Iterable<String> values) {
    const invalidValues = {
      '',
      '-',
      'null',
      'password',
      'n/a',
      'na',
      'none',
    };

    final byKey = <String, String>{};
    for (final raw in values) {
      final cleaned = raw.trim();
      if (cleaned.isEmpty) continue;
      final normalized = cleaned.toLowerCase();
      if (invalidValues.contains(normalized)) continue;
      byKey.putIfAbsent(normalized, () => cleaned);
    }

    final out = byKey.values.toList()..sort();
    return out;
  }

  void _applyApiValidationErrors(ApiException e,
      {required String fallbackMessage}) {
    setState(() {
      _globalError = e.message.trim().isEmpty ? fallbackMessage : e.message;
      _fieldErrors = Map<String, String>.from(e.fieldErrors);
    });
  }

  String _serviceTypeIdFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    return id?.toString() ?? '';
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

  Widget _buildActiveContent() {
    switch (widget.mode) {
      case AddMode.client:
        return addClientDetails();
      case AddMode.product:
        return addProductDetails();
      case AddMode.service:
        return addServicesDetails();
      case AddMode.shop:
        return addShopDetails();
    }
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  Widget _buildStepIndicator(int step, Color activeColor) {
    final bool isCompleted = step < currentStep;
    final bool isCurrent = step == currentStep;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent ? activeColor : Colors.grey[300],
        boxShadow: (isCompleted || isCurrent) && widget.mode == AddMode.client
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.35),
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

  Widget _buildTextField(
    TextEditingController controller, {
    String hint = '',
    int maxLines = 1,
    String? errorText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
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
              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items,
      ValueChanged<String?> onChanged,
      {String? errorText}) {
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
              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
      ],
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
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Icon(Icons.keyboard_arrow_up, size: 18),
                ),
              ),
              InkWell(
                onTap: () {
                  final val = int.tryParse(controller.text) ?? 2;
                  if (val > 1) controller.text = '${val - 1}';
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: display.isEmpty ? Colors.grey[400] : Colors.black87,
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
}

class _ApplianceTypeMeta {
  final String label;
  final String codeField;

  const _ApplianceTypeMeta(this.label, this.codeField);
}
