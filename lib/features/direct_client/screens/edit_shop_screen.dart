import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/api_exception.dart';

class EditShopScreen extends StatefulWidget {
  final Map<String, String> client;

  const EditShopScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _api = BackendApi();

  late final TextEditingController _shopNameController;
  late final TextEditingController _shopAddressController;
  late final TextEditingController _pinCoordinatesController;
  late final TextEditingController _googleMapsController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _contactNoController;
  late final TextEditingController _viberNoController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;

  String? _shopType;
  final List<String> _shopTypes = [];
  final Map<String, String> _shopTypeIds = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorText;
  Map<String, String> _fieldErrors = {};

  int? _shopId;
  int? _clientId;
  String? _shopTypeId;

  @override
  void initState() {
    super.initState();
    _shopNameController =
        TextEditingController(text: widget.client['shop'] ?? '');
    _shopAddressController =
        TextEditingController(text: widget.client['address'] ?? '');
    _pinCoordinatesController =
        TextEditingController(text: widget.client['pinLocation'] ?? '');
    _googleMapsController =
        TextEditingController(text: widget.client['googleMaps'] ?? '');
    _contactPersonController =
        TextEditingController(text: widget.client['contactPerson'] ?? '');
    _contactNoController =
        TextEditingController(text: widget.client['contactNo'] ?? '');
    _viberNoController =
        TextEditingController(text: widget.client['viberNo'] ?? '');
    _emailController =
        TextEditingController(text: widget.client['contactEmail'] ?? '');
    _notesController = TextEditingController();

    _shopId =
        int.tryParse(widget.client['shop_id'] ?? widget.client['id'] ?? '');
    _clientId = int.tryParse(
        widget.client['client_id'] ?? widget.client['clientId'] ?? '');

    _loadShopDetails();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _pinCoordinatesController.dispose();
    _googleMapsController.dispose();
    _contactPersonController.dispose();
    _contactNoController.dispose();
    _viberNoController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadShopDetails() async {
    if (_shopId == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final shopsPage = await _api.getShops(page: 1, perPage: 100);
      final shop = await _api.getShopById(_shopId!);
      if (!mounted) return;

      final typeOptions = <String, String>{
        for (final row in shopsPage.data)
          if (row.shopTypeId.trim().isNotEmpty && row.shopTypeId != '0')
            row.shopTypeId: row.shopTypeId,
      };
      final currentTypeLabel = shop.shopTypeId;
      typeOptions[currentTypeLabel] = shop.shopTypeId;

      setState(() {
        _shopTypeIds
          ..clear()
          ..addAll(typeOptions);
        _shopTypes
          ..clear()
          ..addAll(_shopTypeIds.keys);

        _shopNameController.text = shop.shopname;
        _shopAddressController.text = shop.saddress;
        _pinCoordinatesController.text = shop.pinLocation;
        _googleMapsController.text = shop.locationLink;
        _contactPersonController.text = shop.scontactperson;
        _contactNoController.text = shop.scontactnum;
        _viberNoController.text = shop.svibernum;
        _emailController.text = shop.semailaddress;
        _notesController.text = shop.notes;
        _clientId = shop.clientId;
        _shopTypeId = shop.shopTypeId;
        _shopType = currentTypeLabel.trim().isEmpty ? null : currentTypeLabel;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to load shop details.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveShop() async {
    if (_shopId == null) {
      setState(() => _errorText = 'Missing shop id.');
      return;
    }

    final guardErrors = _validateShopForm();
    if (guardErrors.isNotEmpty) {
      setState(() {
        _fieldErrors = guardErrors;
        _errorText = 'Please fix the highlighted fields before saving.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
      _fieldErrors = {};
    });

    final payload = {
      'shopname': _shopNameController.text.trim(),
      'saddress': _shopAddressController.text.trim(),
      'svibernum': _viberNoController.text.trim(),
      'semailaddress': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'scontactperson': _contactPersonController.text.trim(),
      'scontactnum': _contactNoController.text.trim(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'shop_type_id': _shopType != null
          ? _shopTypeIds[_shopType] ?? _shopTypeId
          : _shopTypeId,
      'client_id': _clientId,
      'location_link': _googleMapsController.text.trim().isEmpty
          ? null
          : _googleMapsController.text.trim(),
      'pin_location': _pinCoordinatesController.text.trim().isEmpty
          ? null
          : _pinCoordinatesController.text.trim(),
    };

    try {
      await _api.updateShop(id: _shopId!, payload: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop updated successfully.')),
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
      setState(() => _errorText = 'Failed to update shop.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                    'Edit Shop',
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
                  _buildField('Shop name', _shopNameController,
                      hint: 'Enter shop name'),
                  const SizedBox(height: 14),
                  _buildField('Shop Address', _shopAddressController,
                      hint: 'Enter shop address'),
                  const SizedBox(height: 14),
                  _buildLabel('Shop Type'),
                  const SizedBox(height: 6),
                  _buildDropdown(),
                  const SizedBox(height: 14),
                  _buildField('Pin Coordinates', _pinCoordinatesController,
                      hint: 'Enter pin coordinates',
                      keyboardType: TextInputType.text),
                  const SizedBox(height: 14),
                  _buildField('Google Maps Link', _googleMapsController,
                      hint: 'Enter map link'),
                  const SizedBox(height: 14),
                  _buildField('Contact Person Name', _contactPersonController,
                      hint: 'Enter contact person'),
                  const SizedBox(height: 14),
                  _buildField('Contact No.', _contactNoController,
                      hint: 'Enter contact number',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      maxLength: 11),
                  const SizedBox(height: 14),
                  _buildField('Viber No.', _viberNoController,
                      hint: 'Enter viber number',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      maxLength: 11),
                  const SizedBox(height: 14),
                  _buildField('Email Address', _emailController,
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _buildField('Notes', _notesController, hint: '', maxLines: 6),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFF5F7FA),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ElevatedButton(
              onPressed: () async {
                if (_isSaving || _isLoading) return;
                final guardErrors = _validateShopForm();
                if (guardErrors.isNotEmpty) {
                  setState(() {
                    _fieldErrors = guardErrors;
                    _errorText =
                        'Please fix the highlighted fields before saving.';
                  });
                  return;
                }
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
                  await _saveShop();
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
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
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            errorText: _fieldErrors[_toBackendKey(label)],
            counterText: '',
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

  Widget _buildDropdown() {
    final errorText = _fieldErrors['shop_type_id'];
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
              value: _shopType,
              isExpanded: true,
              hint: Text(
                'Select Shop Type',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              items: _shopTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _shopType = value),
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

  String _toBackendKey(String label) {
    switch (label) {
      case 'Shop name':
        return 'shopname';
      case 'Shop Address':
        return 'saddress';
      case 'Pin Coordinates':
        return 'pin_location';
      case 'Google Maps Link':
        return 'location_link';
      case 'Contact Person Name':
        return 'scontactperson';
      case 'Contact No.':
        return 'scontactnum';
      case 'Viber No.':
        return 'svibernum';
      case 'Email Address':
        return 'semailaddress';
      case 'Notes':
        return 'notes';
      default:
        return '';
    }
  }

  Map<String, String> _validateShopForm() {
    final errors = <String, String>{};

    if (_shopNameController.text.trim().isEmpty) {
      errors['shopname'] = 'Shop name is required.';
    }
    if (_shopAddressController.text.trim().isEmpty) {
      errors['saddress'] = 'Shop address is required.';
    }
    if (_contactPersonController.text.trim().isEmpty) {
      errors['scontactperson'] = 'Contact person is required.';
    }

    _validateRequiredPhone(
      key: 'scontactnum',
      label: 'Contact number',
      value: _contactNoController.text,
      errors: errors,
    );
    _validateRequiredPhone(
      key: 'svibernum',
      label: 'Viber number',
      value: _viberNoController.text,
      errors: errors,
    );

    final selectedTypeId = _shopType != null
        ? _shopTypeIds[_shopType] ?? _shopTypeId
        : _shopTypeId;
    if ((selectedTypeId ?? '').trim().isEmpty) {
      errors['shop_type_id'] = 'Shop type is required.';
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      errors['semailaddress'] = 'Enter a valid email address.';
    }

    return errors;
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

  bool _isValidEmail(String email) {
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(email);
  }
}
