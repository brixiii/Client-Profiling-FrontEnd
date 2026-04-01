import 'package:flutter/material.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/paginated_response.dart';
import '../../../shared/models/reseller.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/animated_fade_slide.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'reseller_detail_screen.dart';
import 'add_reseller/screens/add_reseller_screen.dart';

class ResellersScreen extends StatefulWidget {
  const ResellersScreen({Key? key}) : super(key: key);

  @override
  State<ResellersScreen> createState() => _ResellersScreenState();
}

class _ResellersScreenState extends State<ResellersScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _entriesPerPage = 5;
  int _currentPage = 1;
  String _searchQuery = '';

  final BackendApi _api = BackendApi();
  List<Reseller> _resellers = [];
  int _totalCount = 0;
  int _lastPage = 1;
  int _analyticsResellers = 0;
  int _analyticsProducts = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchResellers();
    _fetchAnalytics();
  }

  Future<void> _fetchResellers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.getResellers(
        page: _currentPage,
        perPage: _entriesPerPage,
        q: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _resellers = response.data;
        _totalCount = response.total;
        _lastPage = response.lastPage > 0 ? response.lastPage : 1;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAnalytics() async {
    try {
      final both = await Future.wait<dynamic>([
        _api.getResellers(page: 1, perPage: 1),
        _api.getResellerProducts(page: 1, perPage: 1),
      ]);
      if (!mounted) return;
      final r0 = both[0] as PaginatedResponse<Reseller>;
      final r1 = both[1] as PaginatedResponse<Map<String, dynamic>>;
      setState(() {
        _analyticsResellers = r0.total;
        _analyticsProducts  = r1.total;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Resellers',
        showMenuButton: true,
        actions: [],
      ),
      drawer: const AppDrawer(currentPage: 'Resellers'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Cards — fade + slide in
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 60),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 600 ? 4 : 2;
                  return GridView.count(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    AnalyticsCard(
                      title: 'Overall Resellers',
                      value: '$_analyticsResellers',
                      backgroundColor: const Color(0xFFB3E5FC),
                    ),
                    AnalyticsCard(
                      title: 'Sold Products',
                      value: '$_analyticsProducts',
                      backgroundColor: const Color(0xFFB3E5FC),
                    ),
                  ],
                );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Resellers List Section — fades in with delay
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Resellers List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue[600],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddResellerScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _currentPage = 1;
                            _fetchResellers();
                            _fetchAnalytics();
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Reseller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Controls Row - Entries dropdown and Search
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Entries per page
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButton<int>(
                              value: _entriesPerPage,
                              underline: const SizedBox(),
                              items: [5, 10, 25, 50].map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _entriesPerPage = value!;
                                  _currentPage = 1;
                                });
                                _fetchResellers();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'entries per page',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      // Search field
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 16),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _currentPage = 1;
                              });
                              _fetchResellers();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search:',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                                borderSide: const BorderSide(color: Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Company Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Actions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_resellers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No resellers found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._resellers.map((reseller) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                reseller.companyName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                reseller.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                reseller.phone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: OutlinedButton(
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResellerDetailScreen(
                                        reseller: reseller,
                                      ),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _fetchResellers();
                                    _fetchAnalytics();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),  // OutlinedButton
                            ),  // Center
                          ),  // SizedBox
                          ],
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 16),

                  // Footer with pagination info and controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_resellers.isEmpty ? 0 : ((_currentPage - 1) * _entriesPerPage) + 1} to ${((_currentPage - 1) * _entriesPerPage) + _resellers.length} of $_totalCount ${_totalCount == 1 ? 'entry' : 'entries'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          // «« First page
                          _pageBtn(
                            icon: Icons.keyboard_double_arrow_left,
                            enabled: _currentPage > 1,
                            onTap: () { setState(() => _currentPage = 1); _fetchResellers(); },
                          ),
                          const SizedBox(width: 4),
                          // ‹ Prev
                          _pageBtn(
                            icon: Icons.chevron_left,
                            enabled: _currentPage > 1,
                            onTap: () { setState(() => _currentPage--); _fetchResellers(); },
                          ),
                          const SizedBox(width: 6),
                          // Current page bubble
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentPage.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // › Next
                          _pageBtn(
                            icon: Icons.chevron_right,
                            enabled: _currentPage < _lastPage,
                            onTap: () { setState(() => _currentPage++); _fetchResellers(); },
                          ),
                          const SizedBox(width: 4),
                          // »» Last page
                          _pageBtn(
                            icon: Icons.keyboard_double_arrow_right,
                            enabled: _currentPage < _lastPage,
                            onTap: () { setState(() => _currentPage = _lastPage); _fetchResellers(); },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBtn({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        size: 22,
        color: enabled ? Colors.grey[700] : Colors.grey[350],
      ),
    );
  }
}
