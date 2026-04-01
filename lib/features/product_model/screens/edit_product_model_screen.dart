import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/widgets/custom_app_bar.dart';

const _kEditStatusOptions = ['Latest', 'Active', 'Discontinued'];
const _kEditApplianceTypes = ['Washer', 'Dryer', 'Styler', 'Payment System'];

class EditProductModelScreen extends StatefulWidget {
  final ProductModel item;

  const EditProductModelScreen({Key? key, required this.item})
      : super(key: key);

  @override
  State<EditProductModelScreen> createState() =>
      _EditProductModelScreenState();
}

class _EditProductModelScreenState extends State<EditProductModelScreen> {
  final _api = BackendApi();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _modelCodeController;
  late String? _selectedApplianceType;
  late String _selectedStatus;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.modelname);
    _modelCodeController = TextEditingController(text: widget.item.modelCode);
    // If the saved value isn't in the hardcoded list, fall back to null
    _selectedApplianceType = _kEditApplianceTypes.contains(widget.item.applianceType)
        ? widget.item.applianceType
        : (widget.item.applianceType.isNotEmpty ? widget.item.applianceType : null);
    _selectedStatus = widget.item.status.isNotEmpty ? widget.item.status : 'Latest';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedApplianceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a model type.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.updateProductModel(
        id: widget.item.id,
        payload: {
          'appliance_type': _selectedApplianceType!,
          'modelname': _nameController.text.trim(),
          'model_code': _modelCodeController.text.trim(),
          'status': _selectedStatus,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated successfully.')));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Inventory',
        showMenuButton: false,
        actions: const [],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Product Model',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      // ── Select Model (appliance type) ────────────────────
                      _FieldLabel('Select Model'),
                      _buildApplianceTypeDropdown(),
                      const SizedBox(height: 14),

                      // ── Model Name ───────────────────────────────────────
                      _FieldLabel('Model Name'),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        decoration: _inputDecoration('Enter Model Name'),
                      ),
                      const SizedBox(height: 14),

                      // ── Washer Code ──────────────────────────────────────
                      _FieldLabel('Washer Code'),
                      TextFormField(
                        controller: _modelCodeController,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        decoration: _inputDecoration('Enter Washer Code'),
                      ),
                      const SizedBox(height: 14),

                      // ── Status ───────────────────────────────────────────
                      _FieldLabel('Status'),
                      _buildStatusDropdown(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Save Changes button ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C518),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplianceTypeDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedApplianceType,
          isExpanded: true,
          hint: Text('Select Model',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.black54, size: 20),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: _kEditApplianceTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _selectedApplianceType = v),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final safeStatus = _kEditStatusOptions.contains(_selectedStatus)
        ? _selectedStatus
        : _kEditStatusOptions.first;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.black54, size: 20),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: _kEditStatusOptions
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _selectedStatus = v ?? 'Latest'),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE74C3C))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFFE74C3C), width: 1.5)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54)),
    );
  }
}
