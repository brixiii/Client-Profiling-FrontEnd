import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_shop_screen.dart';
import 'screens/add_client/add_buttons_screen.dart';

class ClientDetailScreen extends StatelessWidget {
  final Map<String, String> client;

  const ClientDetailScreen({Key? key, required this.client}) : super(key: key);

  // Static demo products — replace with real data later
  static const List<Map<String, String>> _products = [
    {'modelName': 'LG Titan C Max Dryer (CDT)', 'purchaseOrder': 'To Follow'},
  ];

  // Static demo services — replace with real data later
  static const List<Map<String, String>> _services = [
    {'reportNo': 'N/A', 'serviceType': 'Delivery & Installation'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: 'Direct Client',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Shop Details ──────────────────────────────────────────
            _buildSectionHeader('Shop Details'),
            const SizedBox(height: 8),
            _buildShopDetailsCard(context),

            const SizedBox(height: 20),

            // ── Product Details ───────────────────────────────────────
            _buildSectionHeader('Product Details'),
            const SizedBox(height: 8),
            _buildProductsCard(context),

            const SizedBox(height: 20),

            // ── Services ─────────────────────────────────────────────
            _buildSectionHeader('Services'),
            const SizedBox(height: 8),
            _buildServicesCard(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section header text ─────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // ── Shop details card ───────────────────────────────────────────────────
  Widget _buildShopDetailsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          _infoRow('Address', client['address'] ?? '-'),
          _divider(),
          _infoRow('Pin Location', client['pinLocation'] ?? '-'),
          _divider(),
          _infoRow('Google Maps', client['googleMaps'] ?? '-'),
          _divider(),
          _infoRow('Branch Type', client['branchType'] ?? '-'),
          _divider(),
          _infoRow('Contact Person', client['contactPerson'] ?? '-'),
          _divider(),
          _infoRow('Contact Person\nEmail', client['contactEmail'] ?? '-'),
          _divider(),
          _infoRow('Contact No.', client['contactNo'] ?? '-'),
          _divider(),
          _infoRow('Viber No.', client['viberNo'] ?? '-'),
          const SizedBox(height: 16),

          // Edit and Delete action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditShopScreen(client: client),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
                  onPressed: () {
                    // TODO: implement delete
                  },
                  icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
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
    );
  }

  // ── Product details card ────────────────────────────────────────────────
  Widget _buildProductsCard(BuildContext context) {
    return Container(
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
          // Search + Add Product row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSearchField('Search'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddButtonsScreen(
                          mode: AddMode.product,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Table header
          _buildTableHeader(const ['Model Name', 'Purchase Order']),

          // Data rows
          ..._products.map(
            (p) => _buildTableRow([p['modelName']!, p['purchaseOrder']!]),
          ),

          // Pagination footer
          _buildPaginationFooter(_products.length),
        ],
      ),
    );
  }

  // ── Services card ───────────────────────────────────────────────────────
  Widget _buildServicesCard(BuildContext context) {
    return Container(
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
          // Search + Add Service row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSearchField('Search'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddButtonsScreen(
                          mode: AddMode.service,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Service',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Table header
          _buildTableHeader(
              const ['Service Order\nReport No.', 'Service Type']),

          // Data rows
          ..._services.map(
            (s) => _buildTableRow([s['reportNo']!, s['serviceType']!]),
          ),

          // Pagination footer
          _buildPaginationFooter(_services.length),
        ],
      ),
    );
  }

  // ── Reusable helpers ────────────────────────────────────────────────────

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
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
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

  Widget _buildTableHeader(List<String> columns) {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: columns.map((col) {
          return Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Text(
                col,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow(List<String> cells) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Row(
        children: cells.map((cell) {
          return Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                cell,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          );
        }).toList(),
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
              const _PaginationBtn(icon: Icons.keyboard_double_arrow_left),
              const _PaginationBtn(icon: Icons.chevron_left),
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
                      fontWeight: FontWeight.w600),
                ),
              ),
              const _PaginationBtn(icon: Icons.chevron_right),
              const _PaginationBtn(icon: Icons.keyboard_double_arrow_right),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small pagination icon button ─────────────────────────────────────────────
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
