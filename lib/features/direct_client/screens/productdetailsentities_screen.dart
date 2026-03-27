import 'package:flutter/material.dart';

import '../../../features/serial_number/models/serial_number_model.dart';
import '../../../features/serial_number/screens/serial_number_detail_screen.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_product_details_screen.dart';

class ProductDetailsEntitiesScreen extends StatefulWidget {
  final Map<String, String> product;

  const ProductDetailsEntitiesScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailsEntitiesScreen> createState() =>
      _ProductDetailsEntitiesScreenState();
}

class _ProductDetailsEntitiesScreenState
    extends State<ProductDetailsEntitiesScreen> {
  final _api = BackendApi();
  final _searchController = TextEditingController();

  Product? _product;
  bool _isLoading = false;
  String? _errorText;

  List<String> _serialNumbers = const [];

  int? get _productId => int.tryParse(widget.product['id'] ?? '');

  @override
  void initState() {
    super.initState();
    _seedSerialNumbers();
    _loadProduct();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _seedSerialNumbers() {
    final raw =
        widget.product['serialNumbers'] ?? widget.product['serialNumber'] ?? '';
    final seeded =
        raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    _serialNumbers = seeded;
  }

  Future<void> _loadProduct() async {
    if (_productId == null) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final product = await _api.getProductById(_productId!);
      if (!mounted) return;
      setState(() {
        _product = product;
      });
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

  Future<void> _deleteProduct() async {
    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing product id.')),
      );
      return;
    }

    try {
      await _api.deleteProduct(_productId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully.')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete product.')),
      );
    }
  }

  String _value(String key, String fallback) {
    return widget.product[key]?.trim().isNotEmpty == true
        ? widget.product[key]!
        : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final serialRows = _serialNumbers
        .where((sn) => sn
            .toLowerCase()
            .contains(_searchController.text.trim().toLowerCase()))
        .toList();

    final modelCode = _product?.modelCode ?? _value('modelCode', '');
    final supplierType = _product?.applianceType ?? _value('supplierType', '');
    final uom = _product?.unitsofmeasurement ?? _value('uom', '');
    final quantity = _value('quantity', '-');
    final poNumber = _value('poNumber', '-');
    final drNumber = _value('drNumber', '-');
    final contractDate = _product?.contractDate ?? _value('contractDate', '');
    final deliveryDate = _product?.deliveryDate ?? _value('deliveryDate', '');
    final installationDate =
        _product?.installmentDate ?? _value('installationDate', '');
    final employeeName =
        _product?.employeeId.toString() ?? _value('employeeName', '-');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorText != null) ...[
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _infoRow('Model Code', modelCode.isEmpty ? '-' : modelCode),
                  _divider(),
                  _infoRow('Supplier Type',
                      supplierType.isEmpty ? '-' : supplierType),
                  _divider(),
                  _infoRow('UOM', uom.isEmpty ? '-' : uom),
                  _divider(),
                  _infoRow('Quantity', quantity),
                  _divider(),
                  _infoRow('PO Number', poNumber),
                  _divider(),
                  _infoRow('DR Number', drNumber),
                  _divider(),
                  _infoRow('Contract Date',
                      contractDate.isEmpty ? '-' : contractDate),
                  _divider(),
                  _infoRow('Delivery Date',
                      deliveryDate.isEmpty ? '-' : deliveryDate),
                  _divider(),
                  _infoRow('Installation Date',
                      installationDate.isEmpty ? '-' : installationDate),
                  _divider(),
                  _infoRow('Employee Name', employeeName),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProductDetailsScreen(
                                  product: widget.product,
                                ),
                              ),
                            ).then((_) => _loadProduct());
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text(
                            'Edit',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Product'),
                                content: const Text(
                                    'Are you sure you want to delete this product? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await _deleteProduct();
                            }
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Serial Number Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildSearchField('Search'),
                  ),
                  const SizedBox(height: 10),
                  _buildTableHeader(),
                  if (serialRows.isEmpty) _buildTableRow(context, ''),
                  ...serialRows.map((sn) => _buildTableRow(context, sn)),
                  _buildPaginationFooter(serialRows.length),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[200]);

  Widget _buildSearchField(String hint) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Text(
                'Serial Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.grey[200],
          ),
          const SizedBox(
            width: 80,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                'Actions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, String serialNumber) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                serialNumber,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[100],
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: serialNumber.isEmpty
                  ? const SizedBox.shrink()
                  : OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SerialNumberDetailScreen(
                              item: SerialNumberModel(
                                id: serialNumber,
                                clientName: _value('employeeName', '-'),
                                clientType: _value('supplierType', '-'),
                                dateCreated: _value('deliveryDate', '-'),
                                productModel: _value('modelCode', '-'),
                                serialCodes: [serialNumber],
                              ),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.visibility_outlined,
                              size: 13, color: Color(0xFF2563EB)),
                          SizedBox(width: 3),
                          Text('View',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            count == 0
                ? 'Showing 0 to 0 of 0 entries'
                : 'Showing 1 to $count of $count entries',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Row(
            children: [
              _PaginationBtn(icon: Icons.keyboard_double_arrow_left),
              _PaginationBtn(icon: Icons.chevron_left),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _PaginationBtn(icon: Icons.chevron_right),
              _PaginationBtn(icon: Icons.keyboard_double_arrow_right),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationBtn extends StatelessWidget {
  final IconData icon;

  const _PaginationBtn({Key? key, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: Colors.grey[600]),
      ),
    );
  }
}
