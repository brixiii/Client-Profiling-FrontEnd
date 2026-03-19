import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'clientproduct_detail_screen.dart';
import 'edit_owner_screen.dart';
import 'screens/add_client/add_buttons_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Map<String, String> client;

  const ClientDetailsScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final List<Map<String, String>> shops = [
      {
        'shop': client['shop'] ?? '-',
        'contactPerson': client['contactPerson'] ?? '-',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Client Details ────────────────────────────────────────
            const Text(
              'Client Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Name:', client['contactPerson'] ?? '-'),
                  _divider(),
                  _infoRow('Company Name:', client['companyName'] ?? 'N/A'),
                  _divider(),
                  _infoRow('Email:', client['contactEmail'] ?? '-'),
                  _divider(),
                  _infoRow('Phone No.:', client['contactNo'] ?? '-'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditOwnerScreen(client: client),
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
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Client'),
                                content: const Text(
                                    'Are you sure you want to delete this client? This action cannot be undone.'),
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
                              // TODO: delete logic
                              Navigator.pop(context);
                            }
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
            ),
            const SizedBox(height: 24),

            // ── Shop Details ──────────────────────────────────────────
            const Text(
              'Shop Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search + Add Shop row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list, size: 16),
                          label: const Text('Filter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search shops...',
                              hintStyle: TextStyle(
                                  fontSize: 13, color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search,
                                  size: 18, color: Colors.grey[400]),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2563EB), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddButtonsScreen(mode: AddMode.shop),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Shop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC300),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table header
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            child: Text(
                              'Shop',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            child: Text(
                              'Contact Person',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            child: Text(
                              'Actions',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Data rows
                  if (shops.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.store_outlined,
                                size: 44, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('No shops yet',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    )
                  else
                    ...shops.map((shop) => Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: Colors.grey[200]!, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 12),
                                  child: Text(shop['shop']!,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 12),
                                  child: Text(shop['contactPerson']!,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Center(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ClientDetailScreen(
                                              client: widget.client),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 6),
                                      side: const BorderSide(
                                          color: Color(0xFF2563EB)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.visibility_outlined,
                                            size: 13,
                                            color: Color(0xFF2563EB)),
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
                        )),

                  // Pagination footer
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing 1 to ${shops.length} of ${shops.length} entries',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            _PaginationButton(
                                icon: Icons.keyboard_double_arrow_left,
                                onPressed: () {}),
                            _PaginationButton(
                                icon: Icons.chevron_left, onPressed: () {}),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('1',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            _PaginationButton(
                                icon: Icons.chevron_right, onPressed: () {}),
                            _PaginationButton(
                                icon: Icons.keyboard_double_arrow_right,
                                onPressed: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[200]);
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _PaginationButton(
      {Key? key, required this.icon, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.grey[600]),
      ),
    );
  }
}
