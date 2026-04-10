import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/custom_app_bar.dart';
import '../../../../../shared/api/backend_api.dart';
import '../../../../../shared/data/philippine_address_data.dart' show PhilippineFullAddressData;
import '../../../../../shared/api/api_exception.dart';
import '../../../../../shared/api/paginated_response.dart';
import 'map_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../shared/models/employee.dart';
import '../../../../../shared/models/product.dart';
import '../../../../../shared/models/shop.dart';
import '../../../../service_type/models/service_type_model.dart';
import '../../../../serial_number/models/serial_number_model.dart';
import '../../../../spare_parts/models/spare_part_model.dart';

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
  final List<TextEditingController> _productSerialControllers = [
    TextEditingController()
  ];
  DateTime? _contractDate;
  DateTime? _deliveryDate;
  DateTime? _installationDate;
  final _laborPlanController = TextEditingController();
  String? _salesPersonName;
  final _productNotesController = TextEditingController();

  // ── Shop controllers ───────────────────────────────────────────────────
  final _shopNameController = TextEditingController();
  String? _shopRegion;
  String? _shopProvince;
  String? _shopCity;
  String? _shopBarangay;
  final _shopStreetController = TextEditingController();
  final _shopAddressController = TextEditingController();
  String? _shopType;
  final _pinCoordsController = TextEditingController();
  final _googleMapsController = TextEditingController();
  final _shopContactPersonController = TextEditingController();
  final _shopContactNoController = TextEditingController();
  final _shopViberNoController = TextEditingController();
  final _shopContactEmailController = TextEditingController();
  final _shopNotesController = TextEditingController();
  bool _isGeocoding = false;

  // ── Service controllers ──────────────────────────────────────────────────
  final _reportNoController = TextEditingController();
  String? _subType;
  PlatformFile? _pickedFile;
  final _serviceOrderReportNoController = TextEditingController();
  String? _serviceType;
  DateTime? _serviceDate;
  final List<String?> _selectedTechnicians = [null];
  final List<String> _technicianOptions = [];
  final _serviceNotesController = TextEditingController();
  // Service — dynamic rows
  final List<int?> _serviceSerialIds = [null];
  final List<_SparePartRow> _serviceSparePartRows = [_SparePartRow()];
  List<SerialNumberModel> _serialNumberModels = const [];
  List<SparePartModel> _sparePartModels = const [];

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
    for (final c in _productSerialControllers) c.dispose();
    _laborPlanController.dispose();
    _productNotesController.dispose();
    _reportNoController.dispose();
    _serviceOrderReportNoController.dispose();
    _serviceNotesController.dispose();
    _shopNameController.dispose();
    _shopStreetController.dispose();
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
      // Only start futures needed for the active mode — avoids fetching
      // serial numbers / spare parts / products when adding a client or shop.
      final empty_m = PaginatedResponse<Map<String, dynamic>>(
          data: const [], currentPage: 1, perPage: 100, total: 0, lastPage: 1, links: const []);
      final emptyEmployees = PaginatedResponse<Employee>(
          data: const [], currentPage: 1, perPage: 100, total: 0, lastPage: 1, links: const []);
      final emptyShops = PaginatedResponse<Shop>(
          data: const [], currentPage: 1, perPage: 100, total: 0, lastPage: 1, links: const []);
      final emptyProducts = PaginatedResponse<Product>(
          data: const [], currentPage: 1, perPage: 200, total: 0, lastPage: 1, links: const []);
      final emptyServiceTypes = PaginatedResponse<ServiceTypeModel>(
          data: const [], currentPage: 1, perPage: 100, total: 0, lastPage: 1, links: const []);
      final emptySerials = PaginatedResponse<SerialNumberModel>(
          data: const [], currentPage: 1, perPage: 100, total: 0, lastPage: 1, links: const []);

      final mode = widget.mode;
      final needsEmployees       = mode == AddMode.product || mode == AddMode.service;
      final needsShops           = mode == AddMode.product || mode == AddMode.shop;
      final needsProducts        = mode == AddMode.product;
      final needsApplianceModels = mode == AddMode.product;
      final needsServiceTypes    = mode == AddMode.service;
      final needsSpareParts      = mode == AddMode.service;
      final needsSerialNumbers   = mode == AddMode.service;

      // Start only futures relevant to the current mode.
      final clientsFut = _api.getClients(page: 1, perPage: 100)
          .catchError((_) => empty_m);
      final employeesFut = needsEmployees
          ? _api.getEmployees(page: 1, perPage: 100)
              .catchError((_) => emptyEmployees)
          : Future.value(emptyEmployees);
      final shopsFut = needsShops
          ? _api.getShops(page: 1, perPage: 100)
              .catchError((_) => emptyShops)
          : Future.value(emptyShops);
      final productsFut = needsProducts
          ? _api.getProducts(page: 1, perPage: 200)
              .catchError((_) => emptyProducts)
          : Future.value(emptyProducts);
      final applianceModelsFut = needsApplianceModels
          ? _api.getApplianceModels(page: 1, perPage: 100)
              .catchError((_) => empty_m)
          : Future.value(empty_m);
      final serviceTypesFut = needsServiceTypes
          ? _api.getServiceTypes(page: 1, perPage: 100)
              .catchError((_) => emptyServiceTypes)
          : Future.value(emptyServiceTypes);
      final sparePartsFut = needsSpareParts
          ? _api.fetchAllSpareParts().catchError((_) => <SparePartModel>[])
          : Future.value(<SparePartModel>[]);
      final serialNumbersFut = Future.value(emptySerials);

      // Await all — in-flight futures run in parallel, skipped ones resolve instantly.
      final clientsResp = await clientsFut;
      final employeesResp = await employeesFut;
      final shopsResp = await shopsFut;
      final productsResp = await productsFut;
      final applianceModelsResp = await applianceModelsFut;
      final serviceTypesResp = await serviceTypesFut;
      final sparePartsResp = await sparePartsFut;
      final serialNumbersResp = await serialNumbersFut;

      if (!mounted) return;

      final clients = clientsResp.data;
      final employees = employeesResp.data;
      final shops = shopsResp.data;
      final products = productsResp.data;
      final applianceModels = applianceModelsResp.data;
      final serviceTypes = serviceTypesResp.data;
      final validServiceTypeRows = serviceTypes
          .map((s) => <String, dynamic>{'id': s.id.toString(), 'setypename': s.setypename})
          .where((row) {
            final serviceTypeName = row['setypename']?.toString().trim() ?? '';
            final id = row['id']?.toString().trim() ?? '';
            return serviceTypeName.isNotEmpty && id.isNotEmpty;
          })
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
        // Do NOT auto-assign; Sales Person must be explicitly selected by user

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
        // Sales Person requires explicit user selection — never auto-assign
        if (_salesPersonName != null &&
            !_technicianOptions.contains(_salesPersonName)) {
          _salesPersonName = null;
          _selectedEmployeeId = null;
        }

        _serviceTypes
          ..clear()
          ..addAll(derivedServiceTypes);
        if (_serviceTypes.isNotEmpty) {
          _serviceType = _serviceTypes.first;
        } else {
          _serviceType = null;
        }

        _serialNumberModels = serialNumbersResp.data;
        // Defensive dedup by id — safety layer in case API returns
        // overlapping pages (first occurrence wins).
        final seenSpareIds = <int>{};
        _sparePartModels = sparePartsResp
            .where((m) => seenSpareIds.add(m.id))
            .toList();

        _isLoadingDependencies = false;
      });

      // Fetch serial numbers AFTER _selectedClientId has been resolved.
      if (needsSerialNumbers && _selectedClientId != null) {
        try {
          final serialResp = await _api.getSerialNumbers(
            page: 1,
            perPage: 100,
            clientId: _selectedClientId,
          );
          if (mounted) {
            setState(() => _serialNumberModels = serialResp.data);
          }
        } catch (_) {
          // Leave _serialNumberModels as-is (empty) on error.
        }
      }
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

    // Geocode when leaving Shop step 0 (address fields) → step 1 (location)
    if (widget.mode == AddMode.shop && currentStep == 0) {
      _geocodeAndProceed();
      return;
    }

    if (currentStep < 3) {
      setState(() => currentStep++);
    } else {
      Navigator.pop(context);
    }
  }

  /// Builds the full address, calls the backend forward-geocode endpoint,
  /// opens a map picker for the user to refine the pin, then calls
  /// reverse-geocode to fill location fields and proceeds to step 1.
  Future<void> _geocodeAndProceed() async {
    // Build full address string: Street, Barangay, City, Region, Philippines
    final street = _shopStreetController.text.trim();
    final barangay = (_shopBarangay ?? '').trim();
    final city = (_shopCity ?? '').trim();
    final region = (_shopRegion ?? '').trim();

    final parts = <String>[
      if (street.isNotEmpty) street,
      if (barangay.isNotEmpty) barangay,
      if (city.isNotEmpty) city,
      if (region.isNotEmpty) region,
      'Philippines',
    ];
    final fullAddress = parts.join(', ');

    // Compose the combined address for the saddress payload field
    final addressParts = <String>[
      if (street.isNotEmpty) street,
      if (barangay.isNotEmpty) barangay,
      if (city.isNotEmpty) city,
      if (region.isNotEmpty) region,
    ];
    _shopAddressController.text = addressParts.join(', ');

    setState(() {
      _isGeocoding = true;
      _globalError = null;
    });

    // ── Forward geocode ────────────────────────────────────────────────
    try {
      final data = await _api.geocodeAddress(fullAddress);
      if (!mounted) return;

      setState(() {
        _pinCoordsController.text = (data['location'] ?? '').toString();
        _googleMapsController.text = (data['google_maps_link'] ?? '').toString();
        _isGeocoding = false;
        currentStep = 1;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        currentStep = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not auto-locate address. Please pick on map.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        currentStep = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not auto-locate address. Please pick on map.'),
        ),
      );
    }
  }

  /// Returns a user-friendly message for common network / parse errors.
  String _friendlyErrorMessage(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('HandshakeException')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (s.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    if (s.contains('FormatException')) {
      return 'Invalid response from server. Please try again.';
    }
    return 'Failed to look up address. Please try again.';
  }

  /// Opens the map picker from Step 1 using current Pin Coordinates or
  /// a fallback forward-geocode from the address fields.
  Future<void> _openMapPickerFromStep1() async {
    double? lat;
    double? lng;

    // Try to parse existing pin coordinates first
    final coords = _pinCoordsController.text.trim();
    if (coords.contains(',')) {
      final parts = coords.split(',');
      lat = double.tryParse(parts[0].trim());
      lng = double.tryParse(parts[1].trim());
    }

    // If no valid coords, forward-geocode the address
    if (lat == null || lng == null) {
      final street = _shopStreetController.text.trim();
      final barangay = (_shopBarangay ?? '').trim();
      final city = (_shopCity ?? '').trim();
      final region = (_shopRegion ?? '').trim();
      final addrParts = <String>[
        if (street.isNotEmpty) street,
        if (barangay.isNotEmpty) barangay,
        if (city.isNotEmpty) city,
        if (region.isNotEmpty) region,
        'Philippines',
      ];
      final fullAddress = addrParts.join(', ');

      setState(() {
        _isGeocoding = true;
        _globalError = null;
      });

      try {
        final data = await _api.geocodeAddress(fullAddress);
        if (!mounted) return;
        lat = double.parse(data['latitude'].toString());
        lng = double.parse(data['longitude'].toString());
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isGeocoding = false;
          _globalError = (e is ApiException && e.message.isNotEmpty)
              ? e.message
              : _friendlyErrorMessage(e);
        });
        return;
      }

      setState(() => _isGeocoding = false);
    }

    // Open map picker
    final LatLng? picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(latitude: lat!, longitude: lng!),
      ),
    );

    if (!mounted || picked == null) return;

    // Reverse geocode the selected point
    setState(() {
      _isGeocoding = true;
      _globalError = null;
    });

    try {
      final data = await _api.reverseGeocode(
        latitude: picked.latitude,
        longitude: picked.longitude,
      );
      if (!mounted) return;

      setState(() {
        _pinCoordsController.text = (data['location'] ?? '').toString();
        _googleMapsController.text = (data['google_maps_link'] ?? '').toString();
        _isGeocoding = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        _globalError = e.message.isNotEmpty
            ? e.message
            : 'Unable to reverse geocode the selected location.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        _globalError = _friendlyErrorMessage(e);
      });
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
        if (currentStep == 1) {
          if (_companyNameController.text.trim().isEmpty) {
            errors['ccompanyname'] = 'Company name is required.';
          }
        }
        if (currentStep == 2) {
          final email = _emailController.text.trim();
          if (email.isEmpty) {
            errors['cemail'] = 'Email is required.';
          } else if (!_isValidEmail(email)) {
            errors['cemail'] = 'Enter a valid email address.';
          }
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
        if (currentStep == 1) {
          final hasSerial = _productSerialControllers
              .any((c) => c.text.trim().isNotEmpty);
          if (!hasSerial) {
            errors['serial_number'] = 'At least one serial number is required.';
          }
        }
        if (currentStep == 2) {
          if (_contractDate == null) {
            errors['contract_date'] = 'Contract date is required.';
          }
          if (_deliveryDate == null) {
            errors['delivery_date'] = 'Delivery date is required.';
          }
          if (_installationDate == null) {
            errors['installation_date'] = 'Installation date is required.';
          }
          if (_salesPersonName == null || _selectedEmployeeId == null) {
            errors['employee_id'] = 'Sales Person is required.';
          }
        }
        break;
      case AddMode.service:
        if (currentStep == 0) {
          if (_pickedFile == null) {
            errors['service_file'] = 'File is required.';
          }
          if (_serviceOrderReportNoController.text.trim().isEmpty) {
            errors['service_order_report_no'] =
                'Service Order Report No. is required.';
          }
          if ((_selectedServiceTypeId ?? '').trim().isEmpty) {
            errors['service_type_id'] = 'Service type is required.';
          }
        }
        if (currentStep == 1) {
          // At least one serial number must be selected.
          final hasSerial = _serviceSerialIds.whereType<int>().isNotEmpty;
          if (!hasSerial) {
            errors['service_serial'] =
                'At least one serial number is required.';
          }
          // Check stock for each selected spare part (spare parts are optional).
          for (int i = 0; i < _serviceSparePartRows.length; i++) {
            final row = _serviceSparePartRows[i];
            if (row.sparePartId != null) {
              final part = _sparePartModels
                  .cast<SparePartModel?>()
                  .firstWhere((m) => m?.id == row.sparePartId,
                      orElse: () => null);
              if (part != null && part.spquantity <= 0) {
                errors['spare_parts.$i.spare_part_id'] =
                    '${part.sparepartsname} is out of stock.';
              } else if (part != null && row.quantity > part.spquantity) {
                errors['spare_part_qty_$i'] =
                    'Only ${part.spquantity} in stock.';
              }
            }
          }
        }
        if (currentStep == 2 && _serviceDate == null) {
          errors['service_date'] = 'Service date is required.';
        }
        break;
      case AddMode.shop:
        if (currentStep == 0) {
          if (_shopNameController.text.trim().isEmpty) {
            errors['shopname'] = 'Shop name is required.';
          }
          if ((_shopRegion ?? '').trim().isEmpty) {
            errors['region'] = 'Region is required.';
          }
          if ((_shopProvince ?? '').trim().isEmpty) {
            errors['province'] = 'Province is required.';
          }
          if ((_shopCity ?? '').trim().isEmpty) {
            errors['city'] = 'Municipality / City is required.';
          }
          if ((_shopBarangay ?? '').trim().isEmpty) {
            errors['barangay'] = 'Barangay is required.';
          }
          if (_shopStreetController.text.trim().isEmpty) {
            errors['street'] = 'Street is required.';
          }
          if ((_shopTypeIds[_shopType] ?? '').trim().isEmpty) {
            errors['shop_type_id'] = 'Branch type is required.';
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
                hint: 'First Name',
                errorText: _fieldErrors['cfirstname'],
                textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            _buildTextField(_middleNameController,
                hint: 'Middle Name',
                textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            _buildTextField(_lastNameController,
                hint: 'Last Name',
                errorText: _fieldErrors['csurname'],
                textCapitalization: TextCapitalization.words),
          ],
        );
        break;
      case 1:
        content = _buildTextField(_companyNameController,
            hint: 'Company Name', errorText: _fieldErrors['ccompanyname']);
        break;
      case 2:
        content = Column(
          children: [
            _buildTextField(_emailController,
                hint: 'Email Address',
                errorText: _fieldErrors['cemail']),
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
            _buildSearchableDropdownField(
              hint: 'Select Model Name',
              value: _modelName,
              items: _modelNames,
              onChanged: (v) => _onModelNameChanged(v),
              errorText: _fieldErrors['model_name'],
            ),
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
                const Expanded(
                  child: Text(
                    'Serial Numbers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildIconButton(Icons.add, () {
                  setState(() => _productSerialControllers
                      .add(TextEditingController()));
                }),
              ],
            ),
            const SizedBox(height: 8),
            if (_fieldErrors['serial_number'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _fieldErrors['serial_number']!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            ..._productSerialControllers.asMap().entries.map((entry) {
              final i = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildTextField(ctrl,
                            hint: 'Serial Number',
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [_UpperCaseTextFormatter()])),

                    if (_productSerialControllers.length > 1) ...[
                      const SizedBox(width: 8),
                      _buildRedRemoveButton(() {
                        ctrl.dispose();
                        setState(
                            () => _productSerialControllers.removeAt(i));
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
            if (_fieldErrors['delivery_date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _fieldErrors['delivery_date']!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            const SizedBox(height: 12),
            _buildDateField('Installation Date', _installationDate,
                (d) => setState(() => _installationDate = d)),
            if (_fieldErrors['installation_date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _fieldErrors['installation_date']!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            const SizedBox(height: 12),
            _buildSearchableDropdownField(
              hint: 'Sales Person',
              value: _salesPersonName,
              items: _technicianOptions,
              onChanged: (v) {
                setState(() {
                  _salesPersonName = v;
                  final match = _employees.cast<Employee?>().firstWhere(
                        (e) => e != null && e.name == v,
                        orElse: () => null,
                      );
                  _selectedEmployeeId = match?.id;
                  _fieldErrors.remove('employee_id');
                });
              },
              errorText: _fieldErrors['employee_id'],
            ),
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
      // ── Step 1: File · Report No. · Service Type ─────────────────────────
      case 0:
        return Column(
          children: [
            InkWell(
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  withData: true,
                );
                if (result != null && result.files.isNotEmpty) {
                  setState(() => _pickedFile = result.files.single);
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
                        _pickedFile?.name ?? 'Choose File',
                        style: TextStyle(
                          fontSize: 14,
                          color: _pickedFile != null
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
            if (_fieldErrors['service_file'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _fieldErrors['service_file']!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            const SizedBox(height: 12),
            _buildTextField(
              _serviceOrderReportNoController,
              hint: 'Service Order Report No.',
              errorText: _fieldErrors['service_order_report_no'],
            ),
            const SizedBox(height: 12),
            _buildSearchableDropdownField(
              hint: 'Select Service Type',
              value: _serviceType,
              items: _serviceTypes,
              onChanged: (v) {
                setState(() {
                  _serviceType = v;
                  final idx = _serviceTypes.indexOf(v ?? '');
                  if (idx >= 0 && idx < _serviceTypeRows.length) {
                    _selectedServiceTypeId =
                        _serviceTypeIdFromRow(_serviceTypeRows[idx]);
                  }
                });
              },
              errorText: _fieldErrors['service_type_id'],
            ),
          ],
        );

      // ── Step 2: Serial Numbers · Spare Parts ─────────────────────────────
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _serviceSerialIds.add(null)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('+ Add More Serial Number',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 10),
            if (_fieldErrors['service_serial'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _fieldErrors['service_serial']!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            ..._serviceSerialIds.asMap().entries.map((entry) {
              final i = entry.key;
              final selectedId = entry.value;
              final usedIds = _serviceSerialIds
                  .whereType<int>()
                  .where((id) => id != selectedId)
                  .toSet();
              final seenSerials = <String>{};
              final available = _serialNumberModels
                  .where((m) =>
                      !usedIds.contains(m.id) &&
                      seenSerials.add(m.serialnumber))
                  .toList();
              final selectedName = _serialNumberModels
                  .cast<SerialNumberModel?>()
                  .firstWhere((m) => m?.id == selectedId,
                      orElse: () => null)
                  ?.serialnumber;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSearchableDropdownField(
                        hint: 'Select Serial Number',
                        value: selectedName,
                        items: available.map((m) => m.serialnumber).toList(),
                        onChanged: (v) => setState(() {
                          final model = _serialNumberModels
                              .cast<SerialNumberModel?>()
                              .firstWhere(
                                  (m) => m?.serialnumber == v,
                                  orElse: () => null);
                          _serviceSerialIds[i] = model?.id;
                        }),
                      ),
                    ),
                    if (_serviceSerialIds.length > 1) ...[
                      const SizedBox(width: 8),
                      _buildRedRemoveButton(() {
                        setState(() => _serviceSerialIds.removeAt(i));
                      }),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Spare Parts',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const Spacer(),
                _buildIconButton(
                  Icons.add,
                  () => setState(
                      () => _serviceSparePartRows.add(_SparePartRow())),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_fieldErrors['service_spare'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _fieldErrors['service_spare']!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ),
            ..._serviceSparePartRows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              final usedSpareIds = _serviceSparePartRows
                  .asMap()
                  .entries
                  .where((e) => e.key != i && e.value.sparePartId != null)
                  .map((e) => e.value.sparePartId!)
                  .toSet();
              final availableParts = _sparePartModels
                  .where((m) => !usedSpareIds.contains(m.id))
                  .toList();
              final partIdError = _fieldErrors['spare_parts.$i.spare_part_id'];
              final qtyError = _fieldErrors['spare_parts.$i.quantity']
                  ?? _fieldErrors['spare_part_qty_$i'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(builder: (_) {
                                final nameCounts = <String, int>{};
                                for (final m in _sparePartModels) {
                                  nameCounts[m.sparepartsname] =
                                      (nameCounts[m.sparepartsname] ?? 0) + 1;
                                }
                                String labelFor(SparePartModel m) {
                                  if ((nameCounts[m.sparepartsname] ?? 1) > 1) {
                                    return '${m.sparepartsname} (qty: ${m.spquantity})';
                                  }
                                  return m.sparepartsname;
                                }
                                final seen = <int>{};
                                final uniqueParts = availableParts
                                    .where((m) => seen.add(m.id))
                                    .toList();
                                final labels = uniqueParts
                                    .map((m) => labelFor(m))
                                    .toList();
                                final selectedPart = row.sparePartId != null
                                    ? uniqueParts
                                        .cast<SparePartModel?>()
                                        .firstWhere(
                                            (m) => m?.id == row.sparePartId,
                                            orElse: () => null)
                                    : null;
                                final selectedLabel = selectedPart != null
                                    ? labelFor(selectedPart)
                                    : null;
                                return _buildSearchableDropdownField(
                                  hint: 'Select Spare Parts',
                                  value: selectedLabel,
                                  items: labels,
                                  onChanged: (v) {
                                    final idx = labels.indexOf(v ?? '');
                                    final partId = idx >= 0
                                        ? uniqueParts[idx].id
                                        : null;
                                    setState(() {
                                      _serviceSparePartRows[i] = _SparePartRow(
                                          sparePartId: partId,
                                          quantity: row.quantity);
                                    });
                                  },
                                );
                              }),
                              if (partIdError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(partIdError,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFB91C1C))),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRedRemoveButton(
                          _serviceSparePartRows.length > 1
                              ? () => setState(
                                  () => _serviceSparePartRows.removeAt(i))
                              : () => setState(() =>
                                  _serviceSparePartRows[i] = _SparePartRow()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildIntSpinner(
                      row.quantity,
                      (val) => setState(() => _serviceSparePartRows[i] =
                          _SparePartRow(
                              sparePartId: row.sparePartId,
                              quantity: val)),
                    ),
                    if (qtyError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(qtyError,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFB91C1C))),
                      ),
                  ],
                ),
              );
            }),
          ],
        );

      // ── Step 3: Service Date · Technicians ───────────────────────────────
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            ..._selectedTechnicians.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSearchableDropdownField(
                        hint: 'Technician',
                        value: _selectedTechnicians[i],
                        items: _technicianOptions,
                        onChanged: (v) => setState(() {
                          _selectedTechnicians[i] = v;
                          final match = _employees.cast<Employee?>().firstWhere(
                                (e) => e != null && e.name == v,
                                orElse: () => null,
                              );
                          _selectedEmployeeId = match?.id;
                        }),
                      ),
                    ),
                    if (_selectedTechnicians.length > 1) ...[
                      const SizedBox(width: 8),
                      _buildRedRemoveButton(() {
                        setState(() => _selectedTechnicians.removeAt(i));
                      }),
                    ],
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _selectedTechnicians.add(null)),
                icon: const Icon(Icons.add, size: 16),
                label:
                    const Text('Add More', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );

      // ── Step 4: Notes ─────────────────────────────────────────────────────
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
        final provinceOptions = _shopRegion != null
            ? PhilippineFullAddressData.provincesFor(_shopRegion!)
            : <String>[];
        final cityOptions =
            (_shopRegion != null && _shopProvince != null)
                ? PhilippineFullAddressData.citiesFor(
                    _shopRegion!, _shopProvince!)
                : <String>[];
        final barangayOptions =
            (_shopRegion != null &&
                    _shopProvince != null &&
                    _shopCity != null)
                ? PhilippineFullAddressData.barangaysFor(
                    _shopRegion!, _shopProvince!, _shopCity!)
                : <String>[];

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
            _buildDropdown(
              'Region',
              _shopRegion,
              PhilippineFullAddressData.regions,
              (v) => setState(() {
                _shopRegion = v;
                _shopProvince = null;
                _shopCity = null;
                _shopBarangay = null;
              }),
              errorText: _fieldErrors['region'],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Province',
              _shopProvince,
              provinceOptions,
              (v) => setState(() {
                _shopProvince = v;
                _shopCity = null;
                _shopBarangay = null;
              }),
              errorText: _fieldErrors['province'],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Municipality / City',
              _shopCity,
              cityOptions,
              (v) => setState(() {
                _shopCity = v;
                _shopBarangay = null;
              }),
              errorText: _fieldErrors['city'],
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Barangay',
              _shopBarangay,
              barangayOptions,
              (v) => setState(() => _shopBarangay = v),
              errorText: _fieldErrors['barangay'],
            ),
            const SizedBox(height: 12),
            _buildTextField(_shopStreetController,
                hint: 'Street / Building / House No.',
                errorText: _fieldErrors['street']),
            const SizedBox(height: 12),
            _buildDropdown('Branch Type', _shopType, _shopTypes,
                (v) => setState(() => _shopType = v),
                errorText: _fieldErrors['shop_type_id']),
            if (_isGeocoding) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Looking up address…',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ],
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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGeocoding ? null : _openMapPickerFromStep1,
                icon: _isGeocoding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.map_outlined, size: 18),
                label: Text(_isGeocoding ? 'Updating location…' : 'Pick on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
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

    // All modes use amber step indicators
    const Color activeColor = Color(0xFFFFC300);

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
            if (isClient && isLastStep)
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
                  child: const Text(
                    'Add Client',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else if (isClient)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isLoadingDependencies
                      ? null
                      : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  onPressed: _isSubmitting || _isLoadingDependencies || _isGeocoding
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
                  child: _isGeocoding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Next',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
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
          _summaryRow(
              'Notes',
              _clientNotesController.text.trim().isEmpty
                  ? 'N/A'
                  : _clientNotesController.text.trim()),
        ];
        break;
      case AddMode.product:
        final productSerialSummary = _productSerialControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(', ');
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
          _summaryRow(
              'Serial Numbers',
              productSerialSummary.isEmpty ? '-' : productSerialSummary),
          _summaryRow('Contract Date',
              _contractDate != null ? _formatDate(_contractDate) ?? '-' : '-'),
          _summaryRow('Delivery Date',
              _deliveryDate != null ? _formatDate(_deliveryDate) ?? '-' : '-'),
          _summaryRow('Installation Date',
              _installationDate != null
                  ? _formatDate(_installationDate) ?? '-'
                  : '-'),
          _summaryRow('Sales Person', _salesPersonName ?? '-'),
          _summaryRow(
              'Notes',
              _productNotesController.text.trim().isEmpty
                  ? 'N/A'
                  : _productNotesController.text.trim()),
        ];
        break;
      case AddMode.service:
        final serialSummary = _serviceSerialIds.whereType<int>().isEmpty
            ? '-'
            : _serviceSerialIds
                .whereType<int>()
                .map((id) {
                  return _serialNumberModels
                          .cast<SerialNumberModel?>()
                          .firstWhere((m) => m?.id == id,
                              orElse: () => null)
                          ?.serialnumber ??
                      id.toString();
                })
                .join(', ');
        final spareSummary = _serviceSparePartRows
                .where((r) => r.sparePartId != null)
                .isEmpty
            ? '-'
            : _serviceSparePartRows
                .where((r) => r.sparePartId != null)
                .map((r) {
                  final name = _sparePartModels
                          .cast<SparePartModel?>()
                          .firstWhere((m) => m?.id == r.sparePartId,
                              orElse: () => null)
                          ?.sparepartsname ??
                      r.sparePartId.toString();
                  return '$name ×${r.quantity}';
                })
                .join(', ');
        final techSummary = _selectedTechnicians.whereType<String>().isEmpty
            ? '-'
            : _selectedTechnicians.whereType<String>().join(', ');
        rows = [
          _summaryRow('File', _pickedFile?.name ?? '-'),
          _summaryRow(
              'Service Order Report No.',
              _serviceOrderReportNoController.text.isEmpty
                  ? '-'
                  : _serviceOrderReportNoController.text),
          _summaryRow('Service Type', _serviceType ?? '-'),
          _summaryRow('Serial Numbers', serialSummary),
          _summaryRow('Spare Parts', spareSummary),
          _summaryRow(
              'Service Date',
              _serviceDate != null
                  ? _formatDate(_serviceDate) ?? '-'
                  : '-'),
          _summaryRow('Technicians', techSummary),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
              ),
            ),
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
      ),
    );
  }

  Future<void> _submitCurrentMode() async {
    if (widget.mode == AddMode.client) {
      await _checkAndSubmitClient();
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

  /// Checks for a duplicate name before submitting. If a match is found,
  /// shows a warning dialog. The user can proceed (name gets a (1) suffix)
  /// or cancel and go back to edit.
  Future<void> _checkAndSubmitClient() async {
    final firstName = _toTitleCase(_firstNameController.text);
    final lastName = _toTitleCase(_lastNameController.text);

    setState(() {
      _isSubmitting = true;
      _globalError = null;
    });

    Map<String, dynamic> dupData;
    try {
      dupData = await _api.checkClientDuplicate(
          firstName: firstName, lastName: lastName);
    } catch (_) {
      // If check fails, proceed without blocking the user.
      dupData = {'exists': false};
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    final exists = dupData['exists'] == true;
    if (exists) {
      final fullName = '$firstName $lastName';
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding:
              const EdgeInsets.fromLTRB(24, 28, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFFFC300), width: 2.5),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFFC300), size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Duplicate Name Found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black54, height: 1.5),
                  children: [
                    const TextSpan(
                        text:
                            'There is an existing client with the name '),
                    TextSpan(
                      text: '"$fullName"',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                    const TextSpan(
                        text:
                            '.\n\nWould you like to continue? The name will be saved as '),
                    TextSpan(
                      text: '"$fullName (1)"',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('No, Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Yes, Continue',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (!mounted || proceed != true) return;

      // Append (1) suffix to first name so the full name becomes unique.
      _firstNameController.text = '$firstName (1)';
    }

    await _submitClient();
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
      'cfirstname': _toTitleCase(_firstNameController.text),
      'cmiddlename': _middleNameController.text.trim().isEmpty
          ? null
          : _toTitleCase(_middleNameController.text),
      'csurname': _toTitleCase(_lastNameController.text),
      'client_type_id': _selectedClientTypeId,
      'ccompanyname': _companyNameController.text.trim().isEmpty
          ? null
          : _companyNameController.text.trim(),
      'cemail': _emailController.text.trim(),
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

      final createdShopProduct = await _api.createShopProduct({
        'shop_id': scopedShopId,
        'client_id': _resolveScopedClientId(),
        'product_id': createdProduct.id,
        'quantity': quantity < 1 ? 1 : quantity,
      });

      // Submit serial numbers linked to this shop product.
      final serialValues = _productSerialControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      for (final sn in serialValues) {
        try {
          await _api.createSerialNumber({
            'serialnumber': sn,
            'client_id': _resolveScopedClientId(),
            'shop_product_id': createdShopProduct.id,
          });
        } catch (_) {
          // Non-fatal: product was created; skip duplicate/invalid serials.
        }
      }

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

    final serialNumberIds =
        _serviceSerialIds.whereType<int>().toSet().toList();

    final spareParts = _serviceSparePartRows
        .where((r) => r.sparePartId != null)
        .map((r) =>
            <String, int>{'spare_part_id': r.sparePartId!, 'quantity': r.quantity})
        .toList();

    final technicianIds = _selectedTechnicians
        .where((name) => name != null)
        .map((name) {
          return _employees
              .cast<Employee?>()
              .firstWhere(
                (e) =>
                    e != null &&
                    (e.name.isNotEmpty
                            ? e.name
                            : 'Employee ${e.id}') ==
                        name,
                orElse: () => null,
              )
              ?.id;
        })
        .whereType<int>()
        .toSet()
        .toList();

    try {
      await _api.createAvailedServiceFull(
        serviceOrderReportNo:
            _serviceOrderReportNoController.text.trim(),
        serviceTypeId: (_selectedServiceTypeId ?? '').trim(),
        serviceDate: _formatDate(_serviceDate) ?? '',
        notes: _serviceNotesController.text.trim().isEmpty
            ? null
            : _serviceNotesController.text.trim(),
        filePath: kIsWeb ? null : _pickedFile?.path,
        fileBytes: _pickedFile?.bytes,
        fileName: _pickedFile?.name,
        serialNumberIds: serialNumberIds,
        spareParts: spareParts,
        technicianIds: technicianIds,
        clientId: _resolveScopedClientId() ?? 0,
        shopId: _resolveScopedShopId(),

      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service added successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _applyApiValidationErrors(e, fallbackMessage: 'Failed to add service.');
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('[AddService] unexpected error: $e\n$st');
        return true;
      }());
      if (!mounted) return;
      setState(() {
        _globalError = e.toString().isNotEmpty
            ? e.toString()
            : 'Failed to add service.';
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
    if (_companyNameController.text.trim().isEmpty) {
      errors['ccompanyname'] = 'Company name is required.';
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      errors['cemail'] = 'Email is required.';
    } else if (!_isValidEmail(email)) {
      errors['cemail'] = 'Enter a valid email address.';
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
    if (_deliveryDate == null) {
      errors['delivery_date'] = 'Delivery date is required.';
    }
    if (_installationDate == null) {
      errors['installation_date'] = 'Installation date is required.';
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
    if (_salesPersonName == null || _selectedEmployeeId == null) {
      errors['employee_id'] = 'Sales Person is required.';
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
    if (_serviceOrderReportNoController.text.trim().isEmpty) {
      errors['service_order_report_no'] =
          'Service Order Report No. is required.';
    }
    if ((_selectedServiceTypeId ?? '').trim().isEmpty) {
      errors['service_type_id'] = 'Service type is required.';
    }
    if (_serviceDate == null) {
      errors['service_date'] = 'Service date is required.';
    }
    if (_resolveScopedClientId() == null) {
      errors['client_id'] = 'Client is required.';
    }
    for (int i = 0; i < _serviceSparePartRows.length; i++) {
      if (_serviceSparePartRows[i].sparePartId != null &&
          _serviceSparePartRows[i].quantity < 1) {
        errors['spare_part_qty_$i'] = 'Quantity must be at least 1.';
      }
    }
    return errors;
  }

  Map<String, String> _validateShop() {
    final errors = <String, String>{};
    if (_shopNameController.text.trim().isEmpty) {
      errors['shopname'] = 'Shop name is required.';
    }
    if ((_shopRegion ?? '').trim().isEmpty) {
      errors['region'] = 'Region is required.';
    }
    if ((_shopProvince ?? '').trim().isEmpty) {
      errors['province'] = 'Province is required.';
    }
    if ((_shopCity ?? '').trim().isEmpty) {
      errors['city'] = 'Municipality / City is required.';
    }
    if ((_shopBarangay ?? '').trim().isEmpty) {
      errors['barangay'] = 'Barangay is required.';
    }
    if (_shopStreetController.text.trim().isEmpty) {
      errors['street'] = 'Street is required.';
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

  /// Converts each word's first letter to uppercase and the rest to lowercase.
  String _toTitleCase(String text) {
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildStepIndicator(int step, Color activeColor) {
    final bool isCompleted = step < currentStep;
    final bool isCurrent = step == currentStep;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent ? activeColor : Colors.grey[300],
        boxShadow: (isCompleted || isCurrent)
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
    TextCapitalization textCapitalization = TextCapitalization.none,
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
          textCapitalization: textCapitalization,
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
    // Deduplicate while preserving order to prevent DropdownButton assertion
    final seen = <String>{};
    final uniqueItems = items.where((e) => seen.add(e)).toList();
    final safeValue = uniqueItems.contains(value) ? value : null;

    // Flutter disables DropdownButton internally when items is empty
    // (items.isNotEmpty is part of _enabled). Render a plain placeholder
    // instead so the container always looks consistent.
    Widget dropdownChild;
    if (uniqueItems.isEmpty) {
      dropdownChild = SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isLoadingDependencies ? 'Loading…' : hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      );
    } else {
      dropdownChild = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          items: uniqueItems
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );
    }

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
          child: dropdownChild,
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

  /// Dropdown for spare parts that uses [SparePartModel.id] as the item value
  /// to avoid Flutter duplicates assertion when two parts share the same name.
  /// Disambiguates duplicate names by appending "(qty: X)" in the label only.
  Widget _buildSparePartDropdown(
    int? selectedId,
    List<SparePartModel> parts,
    ValueChanged<int?> onChanged,
  ) {
    // Count how many times each name appears in the full list.
    final nameCounts = <String, int>{};
    for (final m in _sparePartModels) {
      nameCounts[m.sparepartsname] = (nameCounts[m.sparepartsname] ?? 0) + 1;
    }
    String labelFor(SparePartModel m) {
      if ((nameCounts[m.sparepartsname] ?? 1) > 1) {
        return '${m.sparepartsname} (qty: ${m.spquantity})';
      }
      return m.sparepartsname;
    }

    final safeValue = parts.any((m) => m.id == selectedId) ? selectedId : null;
    Widget dropdownChild;
    if (parts.isEmpty) {
      dropdownChild = SizedBox(
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isLoadingDependencies ? 'Loading…' : 'Select Spare Parts',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      );
    } else {
      dropdownChild = DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: safeValue,
          isExpanded: true,
          hint: Text('Select Spare Parts',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          items: (() {
                    // Guard: ensure no duplicate ids reach DropdownButton.
                    final seen = <int>{};
                    return parts
                        .where((m) => seen.add(m.id))
                        .map((m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(labelFor(m),
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87)),
                            ))
                        .toList();
                  })(),
          onChanged: onChanged,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: dropdownChild,
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
    final today = DateTime.now();
    final firstAllowed = DateTime(today.year, today.month, today.day);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: (value != null && !value.isBefore(firstAllowed))
              ? value
              : firstAllowed,
          firstDate: firstAllowed,
          lastDate: DateTime(2035),
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

  /// Red trash button used to remove a spare-part row.
  Widget _buildRedRemoveButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline,
            size: 20, color: Colors.white),
      ),
    );
  }

  /// Searchable dropdown field — shows a bottom sheet with a live-filter
  /// search input. Used for Sales Person selection.
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

  /// Value-based integer spinner — no TextEditingController needed.
  Widget _buildIntSpinner(int value, ValueChanged<int> onChanged,
      {int min = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                value.toString(),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => onChanged(value + 1),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Icon(Icons.keyboard_arrow_up, size: 18),
                ),
              ),
              InkWell(
                onTap: () {
                  if (value > min) onChanged(value - 1);
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
}

class _ApplianceTypeMeta {
  final String label;
  final String codeField;

  const _ApplianceTypeMeta(this.label, this.codeField);
}

/// Holds one spare-part row's selection state (mutable so validation can
/// clear sparePartId when dependency data reloads).
class _SparePartRow {
  int? sparePartId;
  int quantity;

  _SparePartRow({this.sparePartId, this.quantity = 1});
}

/// Forces all typed/pasted text to uppercase.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Full-screen search picker pushed via Navigator.
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
