import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditShopScreen extends StatefulWidget {
  final Map<String, String> client;

  const EditShopScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
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
  final List<String> _shopTypes = ['Main Branch', 'Sub Branch', 'Kiosk'];

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

    // Pre-select shop type if it matches one of the options
    final branchType = widget.client['branchType'] ?? '';
    if (_shopTypes.contains(branchType)) {
      _shopType = branchType;
    }
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

                  _buildField('Shop name', _shopNameController,
                      hint: "3J's Laundry"),
                  const SizedBox(height: 14),

                  _buildField('Shop Address', _shopAddressController,
                      hint: '42 Fuchsia St., De Nacia VIII 4, Brgy. Sauyo, QC'),
                  const SizedBox(height: 14),

                  _buildLabel('Shop Type'),
                  const SizedBox(height: 6),
                  _buildDropdown(),
                  const SizedBox(height: 14),

                  _buildField('Pin Coordinates', _pinCoordinatesController,
                      hint: '14.6888888888888888123123.',
                      keyboardType: TextInputType.text),
                  const SizedBox(height: 14),

                  _buildField('Google Maps Link', _googleMapsController,
                      hint: 'https://maps.app.goo.gl/Lfoqiwqel23'),
                  const SizedBox(height: 14),

                  _buildField('Contact Person Name', _contactPersonController,
                      hint: 'Glenda Valeroso'),
                  const SizedBox(height: 14),

                  _buildField('Contact No.', _contactNoController,
                      hint: '0966-135-9282',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),

                  _buildField('Viber No.', _viberNoController,
                      hint: '0966-135-9282',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),

                  _buildField('Email Address', _emailController,
                      hint: 'glendavaleroso25@gmail.com',
                      keyboardType: TextInputType.emailAddress),
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
              onPressed: () {
                // TODO: save shop data
                Navigator.pop(context);
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
    );
  }
}
