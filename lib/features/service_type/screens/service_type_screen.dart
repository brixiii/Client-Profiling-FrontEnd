import 'package:flutter/material.dart';
import '../models/service_type_model.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
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
  final _api = BackendApi();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 5;

  List<ServiceTypeModel> _allItems = [];
  bool _isLoading = true;
  String? _error;
  int _lastPage = 1;
  int _total = 0;

  int _spAvailable = 0;
  bool _spLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _loadSparePartsStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resp = await _api.getServiceTypes(
          page: _currentPage, perPage: _itemsPerPage);
      if (mounted) {
        setState(() {
          _allItems = resp.data;
          _lastPage = resp.lastPage;
          _total = resp.total;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadSparePartsStats() async {
    try {
      final resp = await _api.getSpareParts(page: 1, perPage: 1);
      if (mounted) {
        setState(() {
          _spAvailable = resp.total;
          _spLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _spLoading = false);
    }
  }

  List<ServiceTypeModel> get _filtered => _allItems.where((e) =>
      e.setypename.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: true),
      drawer: const AppDrawer(currentPage: 'Service Type'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat cards ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(label: 'Spare Parts\nUsed', value: '0'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Available\nSpare Parts',
                    value: _spLoading ? '...' : '$_spAvailable',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Section heading + Add button ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Service Type',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final added = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => const AddServiceTypeScreen()),
                    );
                    if (added == true) _loadPage();
                  },
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Add Type',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Search field ─────────────────────────────────────────
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFBBBBBB))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFBBBBBB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5)),
                ),
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                }),
              ),
            ),
            const SizedBox(height: 12),

            // ── Table ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Header row
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
                              child: const Text('Service Type',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black87)),
                            ),
                          ),
                          const VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Color(0xFFCCCCCC)),
                          const SizedBox(
                            width: 80,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              child: Text('Actions',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black87)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFCCCCCC)),

                  // Loading / error / empty / data rows
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(_error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextButton(
                              onPressed: _loadPage,
                              child: const Text('Retry')),
                        ],
                      ),
                    )
                  else if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No records found.',
                            style: TextStyle(
                                color: Colors.black45, fontSize: 13)),
                      ),
                    )
                  else
                    ...List.generate(filtered.length, (index) {
                      final item = filtered[index];
                      final isLast = index == filtered.length - 1;
                      return Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                    child: Text(item.setypename,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87)),
                                  ),
                                ),
                                const VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    color: Color(0xFFCCCCCC)),
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final changed =
                                            await Navigator.of(context)
                                                .push<bool>(MaterialPageRoute(
                                          builder: (_) =>
                                              ServiceTypeDetailScreen(
                                                  item: item),
                                        ));
                                        if (changed == true) _loadPage();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
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
                  _total == 0
                      ? 'Showing 0 entries'
                      : 'Showing ${(_currentPage - 1) * _itemsPerPage + 1}'
                          '\u2013${(_currentPage - 1) * _itemsPerPage + filtered.length}'
                          ' of $_total entries',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                Row(
                  children: [
                    _PageButton(
                      icon: Icons.first_page,
                      onTap: _currentPage > 1
                          ? () {
                              setState(() => _currentPage = 1);
                              _loadPage();
                            }
                          : null,
                    ),
                    _PageButton(
                      icon: Icons.chevron_left,
                      onTap: _currentPage > 1
                          ? () {
                              setState(() => _currentPage--);
                              _loadPage();
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('$_currentPage',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    _PageButton(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < _lastPage
                          ? () {
                              setState(() => _currentPage++);
                              _loadPage();
                            }
                          : null,
                    ),
                    _PageButton(
                      icon: Icons.last_page,
                      onTap: _currentPage < _lastPage
                          ? () {
                              setState(() => _currentPage = _lastPage);
                              _loadPage();
                            }
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

// ── Stat card ─────────────────────────────────────────────────────────────

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

// ── Pagination button ─────────────────────────────────────────────────────

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
