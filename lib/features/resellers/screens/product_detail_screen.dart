import 'package:flutter/material.dart';
import '../../../shared/api/backend_api.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Resellers'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company name header
            if (companyName.isNotEmpty) ...[
              Text(
                '($companyName)',
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
            ],

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoRow('Model Code', widget.product.modelCode),
                  _divider(),
                  _infoRow('Supplier Type', widget.product.supplierType),
                  _divider(),
                  _infoRow('UOM', widget.product.unitsOfMeasurement),
                  _divider(),
                  _infoRow('Quantity', '${widget.product.quantity}'),
                  _divider(),
                  _infoRow('PO Number', widget.product.poNumber),
                  _divider(),
                  _infoRow('DR Number', widget.product.drNumber),
                  _divider(),
                  _infoRow('Delivery Date', widget.product.deliveryDate),
                  _divider(),
                  _infoRow('Delivery Address', widget.product.deliveryAddress),
                  _divider(),
                  _infoRow('Logistics', ''),
                  _divider(),
                  _infoRow('Customer Representative', widget.product.customerRepresentative),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Action buttons ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: const Color(0xFF2563EB),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProductScreen(product: widget.product),
                        ),
                      );
                      if (result == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        title: const Text('Delete Product',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text(
                            'Are you sure you want to delete this product?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel',
                                style: TextStyle(color: Colors.grey[700])),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context); // close dialog
                              try {
                                await _api.deleteResellerProduct(widget.product.id);
                                if (!mounted) return;
                                Navigator.pop(context, true);
                              } catch (_) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Failed to delete product.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
                    child: Row(
                      children: [
                        Expanded(
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
                      ],
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

                  // Footer count
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Text(
                      'Showing 1 to ${filteredSerials.length} of ${filteredSerials.length} entries',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[500]),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[100]);

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
