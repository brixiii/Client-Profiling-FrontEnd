import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_product_details_screen.dart';

class ProductDetailsEntitiesScreen extends StatelessWidget {
  final Map<String, String> product;

  const ProductDetailsEntitiesScreen({Key? key, required this.product})
      : super(key: key);

  // Static demo serial numbers — replace with real data later
  static const List<String> _serialNumbers = [
    '502KWAT0L216',
    '503KWELI350B',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Details header ─────────────────────────────────
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // ── Product Details info card ──────────────────────────────
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
                  _infoRow('Model Code', product['modelCode'] ?? 'CWG27MDCRB'),
                  _divider(),
                  _infoRow('Supplier Type', product['supplierType'] ?? 'Bulla Crave'),
                  _divider(),
                  _infoRow('UOM', product['uom'] ?? '3'),
                  _divider(),
                  _infoRow('Quantity', product['quantity'] ?? '3'),
                  _divider(),
                  _infoRow('PO Number', product['poNumber'] ?? 'N/A'),
                  _divider(),
                  _infoRow('DR Number', product['drNumber'] ?? 'N/A'),
                  _divider(),
                  _infoRow('Contract Date', product['contractDate'] ?? '2025-04-15'),
                  _divider(),
                  _infoRow('Delivery Date', product['deliveryDate'] ?? '2025-04-15'),
                  _divider(),
                  _infoRow('Installation Date', product['installationDate'] ?? '2025-04-15'),
                  _divider(),
                  _infoRow('Employee Name', product['employeeName'] ?? 'Cecile Aviles'),
                  const SizedBox(height: 16),

                  // Edit / Delete buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProductDetailsScreen(
                                  product: product,
                                ),
                              ),
                            );
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
                              // TODO: implement delete
                              Navigator.pop(context);
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

            // ── Serial Number Details header ───────────────────────────
            const Text(
              'Serial Number Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // ── Serial Number table card ───────────────────────────────
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
                  // Search row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildSearchField('Search'),
                  ),
                  const SizedBox(height: 10),

                  // Table header
                  _buildTableHeader(),

                  // Data rows
                  ..._serialNumbers.map((sn) => _buildTableRow(sn)),

                  // Empty filler rows to match image appearance
                  for (int i = _serialNumbers.length; i < 4; i++)
                    _buildTableRow(''),

                  // Pagination footer
                  _buildPaginationFooter(_serialNumbers.length),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

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
            borderSide:
                const BorderSide(color: Color(0xFF87CEEB), width: 1.5),
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
      child: const Row(
        children: [
          Expanded(
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
        ],
      ),
    );
  }

  Widget _buildTableRow(String serialNumber) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Text(
          serialNumber,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
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
            'Showing 1 to $count of $count entries',
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

// ── Small pagination icon button ──────────────────────────────────────────────
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
