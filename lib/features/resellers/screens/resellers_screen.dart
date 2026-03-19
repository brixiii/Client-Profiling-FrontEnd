import 'package:flutter/material.dart';
import '../../../shared/widgets/analytics_card.dart';
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

  final List<Map<String, String>> resellers = [
    {
      'companyName': 'TechFlow Solutions',
      'email': 'contact@techflow.com',
      'phoneNumber': '+1 (555) 123-4567',
    },
  ];

  List<Map<String, String>> get filteredResellers {
    if (_searchQuery.isEmpty) {
      return resellers;
    }
    return resellers.where((reseller) {
      return reseller['companyName']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          reseller['email']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          reseller['phoneNumber']!.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, String>> get paginatedResellers {
    final startIndex = (_currentPage - 1) * _entriesPerPage;
    final endIndex = startIndex + _entriesPerPage;
    final filtered = filteredResellers;
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int get totalPages {
    return (filteredResellers.length / _entriesPerPage).ceil();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(currentPage: 'Resellers'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Cards Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: const [
                AnalyticsCard(
                  title: 'Overall Resellers',
                  value: '1',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Sold Products',
                  value: '3527',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Resellers List Section
            Container(
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddResellerScreen(),
                            ),
                          );
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
                  if (paginatedResellers.isEmpty)
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
                    ...paginatedResellers.map((reseller) {
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
                                reseller['companyName']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                reseller['email']!,
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
                                reseller['phoneNumber']!,
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
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResellerDetailScreen(
                                        reseller: reseller,
                                      ),
                                    ),
                                  );
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
                        'Showing ${filteredResellers.isEmpty ? 0 : ((_currentPage - 1) * _entriesPerPage) + 1} to ${((_currentPage - 1) * _entriesPerPage) + paginatedResellers.length} of ${filteredResellers.length} ${filteredResellers.length == 1 ? 'entry' : 'entries'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() {
                                      _currentPage = 1;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.first_page),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _currentPage.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _currentPage < totalPages
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
