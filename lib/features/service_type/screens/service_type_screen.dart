import 'package:flutter/material.dart';
import '../models/service_type_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'add_service_type_screen.dart';
import 'service_type_detail_screen.dart';

class ServiceTypeScreen extends StatefulWidget {
  const ServiceTypeScreen({Key? key}) : super(key: key);

  @override
  State<ServiceTypeScreen> createState() => _ServiceTypeScreenState();
}

class _ServiceTypeScreenState extends State<ServiceTypeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<ServiceTypeModel> _items = const [
    ServiceTypeModel(id: '1', name: 'Back Job',                  description: '', price: 0),
    ServiceTypeModel(id: '2', name: 'Check Up',                  description: '', price: 0),
    ServiceTypeModel(id: '3', name: 'Delivery',                  description: '', price: 0),
    ServiceTypeModel(id: '4', name: 'Delivery and Installation',  description: '', price: 0),
    ServiceTypeModel(id: '5', name: 'Check Up and Repair',        description: '', price: 0),
  ];

  List<ServiceTypeModel> get _filtered => _items
      .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  List<ServiceTypeModel> get _pageItems {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _itemsPerPage).ceil().clamp(1, double.maxFinite).toInt();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: true),
      drawer: const AppDrawer(currentPage: 'Service Type'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat cards ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: 'Spare Parts\nUsed', value: '0'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                      label: 'Available\nSpare Parts', value: '1257'),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Section heading + Add button ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Service Type',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddServiceTypeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    '+ Add Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Search field ──────────────────────────────────────────
            SizedBox(
              width: 160,
              height: 36,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Colors.black38),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: Color(0xFFBBBBBB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: Color(0xFFBBBBBB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                        color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                }),
              ),
            ),
            const SizedBox(height: 12),

            // ── Table ─────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color(0xFFCCCCCC), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F9F9),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: const Text(
                                'Service Type',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const VerticalDivider(
                              width: 1, thickness: 1, color: Color(0xFFCCCCCC)),
                          SizedBox(
                            width: 80,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: const Text(
                                'Actions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFCCCCCC)),

                  // Data rows
                  if (_pageItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No records found.',
                          style: TextStyle(
                              color: Colors.black45, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_pageItems.length, (index) {
                      final item = _pageItems[index];
                      final isLast = index == _pageItems.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServiceTypeDetailScreen(item: item),
                                ),
                              );
                            },
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 16),
                                      child: Text(
                                        item.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Color(0xFFCCCCCC)),
                                  SizedBox(
                                    width: 80,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 6),
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ServiceTypeDetailScreen(
                                                      item: item),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 4),
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
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFCCCCCC)),
                        ],
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Pagination footer ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _filtered.isEmpty
                      ? 'Showing 0 entries'
                      : 'Showing ${(_currentPage - 1) * _itemsPerPage + 1} to '
                          '${(_currentPage * _itemsPerPage).clamp(1, _filtered.length)} '
                          'of ${_filtered.length} entries',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45),
                ),
                Row(
                  children: [
                    _PageButton(
                      icon: Icons.first_page,
                      onTap: _currentPage > 1
                          ? () => setState(() => _currentPage = 1)
                          : null,
                    ),
                    _PageButton(
                      icon: Icons.chevron_left,
                      onTap: _currentPage > 1
                          ? () => setState(() => _currentPage -= 1)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$_currentPage',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _PageButton(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < _totalPages
                          ? () => setState(() => _currentPage += 1)
                          : null,
                    ),
                    _PageButton(
                      icon: Icons.last_page,
                      onTap: _currentPage < _totalPages
                          ? () =>
                              setState(() => _currentPage = _totalPages)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pagination button ──────────────────────────────────────────────────────

class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PageButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(4),
          color: onTap == null ? const Color(0xFFF0F0F0) : Colors.white,
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? Colors.black26 : Colors.black54,
        ),
      ),
    );
  }
}
