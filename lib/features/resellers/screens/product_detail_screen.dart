import 'package:flutter/material.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/models/reseller_product.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ResellerProduct product;
  final String companyName;

  const ProductDetailScreen({
    Key? key,
    required this.product,
    this.companyName = '',
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _serialSearchController = TextEditingController();
  String _serialQuery = '';
  final BackendApi _api = BackendApi();

  @override
  void dispose() {
    _serialSearchController.dispose();
    super.dispose();
  }

  List<String> get filteredSerials {
    final serials = widget.product.serials;
    if (_serialQuery.isEmpty) return serials;
    return serials
        .where((s) => s.toLowerCase().contains(_serialQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.companyName;
    final p = widget.product;
    final initial = p.modelName.isNotEmpty
        ? p.modelName.substring(0, 1).toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Resellers'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Info Card ──────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient header band
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF87CEEB), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar initial
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.modelName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Product Detail',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info rows with icons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.qr_code_outlined, 'Model Code',
                            p.modelCode.isEmpty ? 'N/A' : p.modelCode),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.local_offer_outlined, 'Supplier Type',
                            p.supplierType.isEmpty ? 'N/A' : p.supplierType),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.straighten_outlined, 'UOM',
                            p.unitsOfMeasurement.isEmpty ? 'N/A' : p.unitsOfMeasurement),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.inventory_2_outlined, 'Quantity',
                            '${p.quantity}'),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.receipt_outlined, 'PO Number',
                            p.poNumber.isEmpty ? 'N/A' : p.poNumber),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.description_outlined, 'DR Number',
                            p.drNumber.isEmpty ? 'N/A' : p.drNumber),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Delivery Date',
                            p.deliveryDate.isEmpty ? 'N/A' : p.deliveryDate),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.location_on_outlined, 'Delivery Address',
                            p.deliveryAddress.isEmpty ? 'N/A' : p.deliveryAddress),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.local_shipping_outlined, 'Logistics', 'N/A'),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.person_outline, 'Customer Representative',
                            p.customerRepresentative.isEmpty
                                ? 'N/A'
                                : p.customerRepresentative),
                        const SizedBox(height: 20),

                        // Pill action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditProductScreen(product: p),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    Navigator.pop(context, true);
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: SessionFlags.userRole != 'Super Admin'
                                    ? null
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            title: const Text('Delete Product',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            content: const Text(
                                                'Are you sure you want to delete this product?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('Cancel',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[700])),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  try {
                                                    await _api
                                                        .deleteResellerProduct(
                                                            p.id);
                                                    if (!mounted) return;
                                                    Navigator.pop(
                                                        context, true);
                                                  } catch (_) {
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Failed to delete product.')),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFEF4444),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Serial Number Details ──────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Text(
                      'Serial Number Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _serialSearchController,
                      onChanged: (v) => setState(() => _serialQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle:
                            TextStyle(fontSize: 13, color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 18, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FC),
                      border: Border.symmetric(
                        horizontal:
                            BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Text(
                      'Serial Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Serial rows
                  if (filteredSerials.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No serial numbers found',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[400])),
                      ),
                    )
                  else
                    ...filteredSerials.asMap().entries.map((e) {
                      final isLast = e.key == filteredSerials.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: e.key.isEven
                              ? Colors.white
                              : const Color(0xFFFAFAFC),
                          border: !isLast
                              ? Border(
                                  bottom: BorderSide(
                                      color: Colors.grey[100]!, width: 1))
                              : null,
                        ),
                        child: Text(
                          e.value,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                        ),
                      );
                    }).toList(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Text(
                      'Showing 1 to ${filteredSerials.length} of ${filteredSerials.length} entries',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
