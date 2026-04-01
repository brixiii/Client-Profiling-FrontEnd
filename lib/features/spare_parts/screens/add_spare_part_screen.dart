import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/widgets/custom_app_bar.dart';

/// Add a new Spare Part.
/// Reached from "+ Add Parts" in SparePartsScreen.
class AddSparePartScreen extends StatefulWidget {
  const AddSparePartScreen({Key? key}) : super(key: key);

  @override
  State<AddSparePartScreen> createState() => _AddSparePartScreenState();
}

class _AddSparePartScreenState extends State<AddSparePartScreen> {
  final _api = BackendApi();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  int _quantity = 0;

  Map<String, String> _fieldErrors = {};
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _partNumberController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _fieldErrors.remove('date');
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await _api.createSparePart({
        'sparepartsname': _nameController.text.trim(),
        'partnumber': _partNumberController.text.trim(),
        'spquantity': _quantity,
        'date': _dateController.text.trim(),
        'spnotes': _notesController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Spare part added successfully.')));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 422 && e.fieldErrors.isNotEmpty) {
          setState(() => _fieldErrors = Map<String, String>.from(e.fieldErrors));
          _formKey.currentState?.validate();
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Parts',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Part Name'),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Enter Part Name',
                        fieldKey: 'sparepartsname',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (_fieldErrors.containsKey('sparepartsname')) {
                            return _fieldErrors['sparepartsname'];
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _FieldLabel('Part Number'),
                      _buildTextField(
                        controller: _partNumberController,
                        hint: 'Enter Part Number',
                        fieldKey: 'partnumber',
                      ),
                      const SizedBox(height: 16),

                      _FieldLabel('Quantity'),
                      _buildQuantityStepper(),
                      const SizedBox(height: 16),

                      _FieldLabel('Date'),
                      _buildDateField(),
                      const SizedBox(height: 16),

                      _FieldLabel('Notes'),
                      _buildTextField(
                        controller: _notesController,
                        hint: 'Notes',
                        fieldKey: 'spnotes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String fieldKey,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      onChanged: (_) {
        if (_fieldErrors.containsKey(fieldKey)) {
          setState(() => _fieldErrors.remove(fieldKey));
        }
      },
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text('$_quantity',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87)),
            ),
          ),
          Column(
            children: [
              InkWell(
                onTap: () => setState(() => _quantity++),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Icon(Icons.keyboard_arrow_up,
                      size: 18, color: Colors.black54),
                ),
              ),
              const Divider(
                  height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
              InkWell(
                onTap: () => setState(() {
                  if (_quantity > 0) _quantity--;
                }),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: _pickDate,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (_fieldErrors.containsKey('date')) return _fieldErrors['date'];
        return null;
      },
      decoration: _inputDecoration('YYYY-MM-DD').copyWith(
        suffixIcon: const Icon(Icons.calendar_today_outlined,
            size: 18, color: Colors.black45),
      ),
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54)),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
    filled: true,
    fillColor: const Color(0xFFF5F7FA),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:
          const BorderSide(color: Color(0xFF2563EB), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFEF5350)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
    ),
  );
}

/// Add a new Spare Part.
/// Reached from "+ Add Parts" in SparePartsScreen.
