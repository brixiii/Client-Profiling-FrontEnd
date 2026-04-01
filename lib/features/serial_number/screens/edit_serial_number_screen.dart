import 'package:flutter/material.dart';
import '../models/serial_number_model.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EditSerialNumberScreen extends StatefulWidget {
  final SerialNumberModel item;

  const EditSerialNumberScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<EditSerialNumberScreen> createState() => _EditSerialNumberScreenState();
}

class _EditSerialNumberScreenState extends State<EditSerialNumberScreen> {
  final _api = BackendApi();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _serialNumberController;
  late final TextEditingController _shopProductIdController;

  String _shopProductName = '';
  Map<String, String> _fieldErrors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _serialNumberController = TextEditingController(text: widget.item.serialnumber);
    _shopProductIdController =
        TextEditingController(text: widget.item.shopProductId?.toString() ?? '');
    _loadShopProductName();
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _shopProductIdController.dispose();
    super.dispose();
  }

  Future<void> _loadShopProductName() async {
    final idText = _shopProductIdController.text.trim();
    final id = int.tryParse(idText);
    if (id == null) {
      setState(() => _shopProductName = '');
      return;
    }

    try {
      final shopProduct = await _api.getShopProductById(id);
      if (mounted) {
        setState(() => _shopProductName = shopProduct.product.modelName);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _shopProductName = '');
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _fieldErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await _api.updateSerialNumber(widget.item.id, {
        'serialnumber': _serialNumberController.text.trim(),
        'shop_product_id': int.tryParse(_shopProductIdController.text.trim()),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
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
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Serial',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Serial Number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _serialNumberController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return _fieldErrors['serialnumber'];
                      },
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('serialnumber')) {
                          setState(() => _fieldErrors.remove('serialnumber'));
                        }
                      },
                      decoration: _inputDecoration('Enter Serial Number'),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Product Model ID'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _shopProductIdController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (int.tryParse(v.trim()) == null) {
                          return 'Must be a number';
                        }
                        return _fieldErrors['shop_product_id'];
                      },
                      onChanged: (_) {
                        if (_fieldErrors.containsKey('shop_product_id')) {
                          setState(() => _fieldErrors.remove('shop_product_id'));
                        }
                        _loadShopProductName();
                      },
                      decoration: _inputDecoration('Enter Product Model ID'),
                    ),
                    if (_shopProductName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Model: $_shopProductName',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFEF5350)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
      ),
    );
  }
}
