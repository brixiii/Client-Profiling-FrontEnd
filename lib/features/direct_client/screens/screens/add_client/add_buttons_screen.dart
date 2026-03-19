import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../shared/widgets/custom_app_bar.dart';

enum AddMode { client, product, service, shop }

class AddButtonsScreen extends StatefulWidget {
  final AddMode mode;

  const AddButtonsScreen({Key? key, required this.mode}) : super(key: key);

  @override
  State<AddButtonsScreen> createState() => _AddButtonsScreenState();
}

class _AddButtonsScreenState extends State<AddButtonsScreen> {
  int currentStep = 0;

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
  final _purchaseOrderController = TextEditingController();
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
  final List<String> _technicianOptions = [
    'Juan dela Cruz',
    'Maria Santos',
    'Pedro Reyes',
    'Ana Garcia',
    'Carlos Mendoza',
  ];
  final _serviceNotesController = TextEditingController();

  // ── Static mock options ──────────────────────────────────────────────────
  final List<String> _modelNames = [
    'LG Titan C Max Dryer (CDT)',
    'LG Pro Washer'
  ];
  final List<String> _categoryTypes = ['Dryer', 'Washer', 'Combo'];
  final List<String> _machineTypes = ['Commercial', 'Industrial', 'Residential'];
  final List<String> _modelCodes = ['CDT-001', 'CDT-002', 'PRO-001'];
  final List<String> _uomOptions = ['Unit', 'Piece', 'Set'];
  final List<String> _shopTypes = ['Branch', 'Main Office', 'Warehouse', 'Service Center'];
  final List<String> _subTypes = ['Warranty', 'Non-warranty', 'Preventive'];
  final List<String> _serviceTypes = [
    'Delivery & Installation',
    'Repair',
    'Maintenance',
  ];
  final List<String> _serialNumbers = ['SN-001', 'SN-002', 'SN-003'];
  final List<String> _spareParts = ['Belt', 'Motor', 'Drum', 'Filter'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _clientNotesController.dispose();
    _quantityController.dispose();
    _purchaseOrderController.dispose();
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

  void _nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
    } else {
      Navigator.pop(context);
    }
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
            _buildTextField(_firstNameController, hint: 'First Name'),
            const SizedBox(height: 16),
            _buildTextField(_middleNameController, hint: 'Middle Name'),
            const SizedBox(height: 16),
            _buildTextField(_lastNameController, hint: 'Last Name'),
          ],
        );
        break;
      case 1:
        content = _buildTextField(_companyNameController, hint: 'Company Name');
        break;
      case 2:
        content = Column(
          children: [
            _buildTextField(_emailController,
                hint: 'Email Address (Optional)'),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, hint: 'Phone Number'),
          ],
        );
        break;
      case 3:
        content = _buildTextField(_clientNotesController,
            hint: 'Notes', maxLines: 6);
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
                (v) => setState(() => _modelName = v)),
            const SizedBox(height: 12),
            _buildDropdown('Category Type', _categoryType, _categoryTypes,
                (v) => setState(() => _categoryType = v)),
            const SizedBox(height: 12),
            _buildDropdown('Machine Type', _machineType, _machineTypes,
                (v) => setState(() => _machineType = v)),
            const SizedBox(height: 12),
            _buildDropdown('Model Code', _modelCode, _modelCodes,
                (v) => setState(() => _modelCode = v)),
            const SizedBox(height: 12),
            _buildDropdown(
                'UOM', _uom, _uomOptions, (v) => setState(() => _uom = v)),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildSpinnerField('Quantity', _quantityController),
            const SizedBox(height: 12),
            _buildTextField(_purchaseOrderController, hint: 'Purchase Order'),
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
            const SizedBox(height: 12),
            _buildDateField('Delivery Date', _deliveryDate,
                (d) => setState(() => _deliveryDate = d)),
            const SizedBox(height: 12),
            _buildDateField('Installation Date', _installationDate,
                (d) => setState(() => _installationDate = d)),
            const SizedBox(height: 12),
            _buildTextField(_laborPlanController, hint: 'Labor Plan'),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
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
                    Icon(Icons.attach_file,
                        size: 18, color: Colors.grey[500]),
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
                (v) => setState(() => _serviceType = v)),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildDropdown('Select Serial Number', _selectedSerialNumber,
                _serialNumbers,
                (v) => setState(() => _selectedSerialNumber = v)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown('Select Spare Part', _selectedSparePart,
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
                  (v) => setState(() => _selectedTechnicians[i] = v),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _selectedTechnicians.add(null)),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+ Add More',
                    style: TextStyle(fontSize: 12)),
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
            _buildTextField(_shopNameController, hint: 'Shop Name'),
            const SizedBox(height: 12),
            _buildTextField(_shopAddressController, hint: 'Shop Address'),
            const SizedBox(height: 12),
            _buildDropdown('Shop Type', _shopType, _shopTypes,
                (v) => setState(() => _shopType = v)),
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
            _buildTextField(_shopContactPersonController, hint: 'Contact Person'),
            const SizedBox(height: 12),
            _buildTextField(_shopContactNoController, hint: 'Contact No.'),
            const SizedBox(height: 12),
            _buildTextField(_shopViberNoController, hint: 'Viber No.'),
            const SizedBox(height: 12),
            _buildTextField(_shopContactEmailController, hint: 'Email Address'),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              const Color(0xFF2563EB).withOpacity(0.35)),
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
                              padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 8),
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
                  onPressed: isLastStep ? _showConfirmDialog : _nextStep,
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
                  onPressed: _showConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Submit',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _nextStep,
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog() {
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
          _summaryRow('Company Name',
              _companyNameController.text.isEmpty ? 'N/A' : _companyNameController.text),
          _summaryRow('Email',
              _emailController.text.isEmpty ? '-' : _emailController.text),
          _summaryRow('Phone No.',
              _phoneController.text.isEmpty ? '-' : _phoneController.text),
        ];
        break;
      case AddMode.product:
        rows = [
          _summaryRow('Model Name', _modelName ?? '-'),
          _summaryRow('Category Type', _categoryType ?? '-'),
          _summaryRow('Machine Type', _machineType ?? '-'),
          _summaryRow('Model Code', _modelCode ?? '-'),
          _summaryRow('UOM', _uom ?? '-'),
          _summaryRow('Quantity', _quantityController.text),
          _summaryRow('Purchase Order',
              _purchaseOrderController.text.isEmpty ? '-' : _purchaseOrderController.text),
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
          _summaryRow('Shop Name',
              _shopNameController.text.isEmpty ? '-' : _shopNameController.text),
          _summaryRow('Shop Address',
              _shopAddressController.text.isEmpty ? '-' : _shopAddressController.text),
          _summaryRow('Shop Type', _shopType ?? '-'),
          _summaryRow('Contact Person',
              _shopContactPersonController.text.isEmpty ? '-' : _shopContactPersonController.text),
          _summaryRow('Contact No.',
              _shopContactNoController.text.isEmpty ? '-' : _shopContactNoController.text),
          _summaryRow('Email',
              _shopContactEmailController.text.isEmpty ? '-' : _shopContactEmailController.text),
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
                onPressed: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.pop(context); // go back to previous screen
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
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
  }) {
    return TextField(
      controller: controller,
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
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
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

  Widget _buildSpinnerField(
      String label, TextEditingController controller) {
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
    final display = value != null
        ? '${value.month}/${value.day}/${value.year}'
        : '';
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
