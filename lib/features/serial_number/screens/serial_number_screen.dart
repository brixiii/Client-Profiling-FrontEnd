import 'package:flutter/material.dart';
import '../models/serial_number_model.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'serial_number_detail_screen.dart';

class SerialNumberScreen extends StatefulWidget {
  const SerialNumberScreen({Key? key}) : super(key: key);

  @override
  State<SerialNumberScreen> createState() => _SerialNumberScreenState();
}

class _SerialNumberScreenState extends State<SerialNumberScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  final List<SerialNumberModel> _items = const [
    SerialNumberModel(
      id: '1',
      clientName: 'Aaron Adam Nuqui',
      clientType: 'Owner',
      dateCreated: '175630252',
      productModel: 'LG GIANT C MAX WASHER (CWG27MDCRB)',
      serialCodes: ['419KWK529045', '419KWEL62236', '412KWJU2B26B'],
    ),
    SerialNumberModel(
      id: '2',
      clientName: 'Aaron De Leon',
      clientType: 'Owner',
      dateCreated: '175630253',
      productModel: 'LG TWIN WASH (F2514NTGW)',
      serialCodes: ['412KWVO0LB23', '412KWCFBLB27'],
    ),
    SerialNumberModel(
      id: '3',
      clientName: 'Aaron Paradero',
      clientType: 'Owner',
      dateCreated: '175630252',
      productModel: 'LG GIANT C MAX WASHER (CWG27MDCRB)',
      serialCodes: [
        '419KWK529045',
        '419KWEL62236',
        '412KWJU2B26B',
        '412KWVO0LB23',
        '412KWCFBLB27',
        '509KWPV15664',
      ],
    ),
    SerialNumberModel(
      id: '4',
      clientName: 'Abby Rojas',
      clientType: 'Owner',
      dateCreated: '175630254',
      productModel: 'LG FRONT LOAD (F1296QDP3)',
      serialCodes: ['509KWPV15664'],
    ),
    SerialNumberModel(
      id: '5',
      clientName: 'AB Gregorio',
      clientType: 'Owner',
      dateCreated: '175630255',
      productModel: 'LG TOP LOAD (T2108VSAM)',
      serialCodes: ['412KWVO0LB23'],
    ),
    SerialNumberModel(
      id: '6',
      clientName: 'Ace Santos',
      clientType: 'Owner',
      dateCreated: '175630256',
      productModel: 'LG TWIN WASH (F2514NTGW)',
      serialCodes: ['419KWK529045'],
    ),
  ];

  List<SerialNumberModel> get _filtered => _items
      .where((e) =>
          e.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.clientType.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  List<SerialNumberModel> get _pageItems {
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
      drawer: const AppDrawer(currentPage: 'Serial Numbers'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat cards ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: 'Spare Parts\nUsed', value: '0'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(label: 'Available\nSpare Parts', value: '1257'),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Section heading ─────────────────────────────────────────
            const Text(
              'Serial Numbers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // ── Search field ───────────────────────────────────────────
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
                    borderSide: const BorderSide(color: Color(0xFFBBBBBB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFBBBBBB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                }),
              ),
            ),
            const SizedBox(height: 12),

            // ── Table ──────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Header row
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F9F9),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: const Text(
                                'Client Name',
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
                              width: 1,
                              thickness: 1,
                              color: Color(0xFFCCCCCC)),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: const Text(
                                'Client Type',
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
                        child: Text('No records found.',
                            style: TextStyle(
                                color: Colors.black45, fontSize: 13)),
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
                                      SerialNumberDetailScreen(item: item),
                                ),
                              );
                            },
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 8),
                                      child: Text(
                                        item.clientName,
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
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 8),
                                      child: Text(
                                        item.clientType,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
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

            // ── Pagination footer ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _filtered.isEmpty
                      ? 'Showing 0 entries'
                      : 'Showing ${(_currentPage - 1) * _itemsPerPage + 1} to '
                          '${(_currentPage * _itemsPerPage).clamp(1, _filtered.length)} '
                          'of ${_filtered.length} entries',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black45),
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
                          ? () => setState(() => _currentPage = _totalPages)
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

// ── Stat card ───────────────────────────────────────────────────────────────

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
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}

// ── Pagination button ───────────────────────────────────────────────────────

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
        child: Icon(icon,
            size: 16,
            color: onTap == null ? Colors.black26 : Colors.black54),
      ),
    );
  }
}
