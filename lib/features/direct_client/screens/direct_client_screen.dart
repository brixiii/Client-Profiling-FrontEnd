import 'package:flutter/material.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'screens/add_client/add_buttons_screen.dart';
import 'clientshop_details_screen.dart';

class DirectClientScreen extends StatefulWidget {
  const DirectClientScreen({Key? key}) : super(key: key);

  @override
  State<DirectClientScreen> createState() => _DirectClientScreenState();
}

class _DirectClientScreenState extends State<DirectClientScreen> {
  final List<Map<String, String>> clients = [
    {
      'shop': '3G Laundry Room',
      'name': 'Andrea Manlapid',
      'address': '42 Fuchsia St., De Nacia VIII 4, Brgy. Sauyo, Quezon City',
      'pinLocation': '14.6888665,121.0425025',
      'googleMaps': 'https://maps.app.goo.gl/L9eFmISF4gvPXPBv9',
      'branchType': 'Main Branch',
      'contactPerson': 'Glenda Valeroso',
      'contactEmail': 'glendavaleroso25@gmail.com',
      'contactNo': '0966-135-9282',
      'viberNo': '0966-135-9282',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Direct Client',
        showMenuButton: true,
      ),
      drawer: const AppDrawer(currentPage: 'Direct Client'),
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
                  title: 'Owner',
                  value: '618',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Co-Owner',
                  value: '5',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Shops',
                  value: '681',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Sold Products',
                  value: '3,527',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Successful Service Card (single, full-width)
            const SizedBox(
              width: double.infinity,
              height: 90,
              child: AnalyticsCard(
                title: 'Successful Service',
                value: '625',
                backgroundColor: Color(0xFFB3E5FC),
              ),
            ),
            const SizedBox(height: 24),

            // Client List Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and Add Client button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Client List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddButtonsScreen(
                                mode: AddMode.client,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Client'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC300),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter + Search row
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement filter functionality
                        },
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: const Text('Filter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search clients...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(
                              'Shop',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(
                              'Name',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(
                              'Actions',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Data rows
                  if (clients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline,
                                size: 44, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(
                              'No clients yet',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Add Client" to get started',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...clients.map((client) => Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 8),
                              child: Text(
                                client['shop']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 8),
                              child: Text(
                                client['name']!,
                                style: const TextStyle(fontSize: 14),
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
                                      builder: (_) =>
                                          ClientDetailsScreen(client: client),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  side: const BorderSide(
                                      color: Color(0xFF2563EB)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.visibility_outlined,
                                        size: 13, color: Color(0xFF2563EB)),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing 1 to ${clients.length} of ${clients.length} entries',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          _PaginationButton(
                            icon: Icons.keyboard_double_arrow_left,
                            onPressed: () {},
                          ),
                          _PaginationButton(
                            icon: Icons.chevron_left,
                            onPressed: () {},
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          _PaginationButton(
                            icon: Icons.chevron_right,
                            onPressed: () {},
                          ),
                          _PaginationButton(
                            icon: Icons.keyboard_double_arrow_right,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _PaginationButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
