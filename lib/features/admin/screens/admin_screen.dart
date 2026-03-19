import 'package:flutter/material.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'add_admin_screen.dart';
import 'add_employee_screen.dart';
import 'admin_detail_screen.dart';
import 'employee_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // ── Admin List state ─────────────────────────────────────────────────────
  final TextEditingController _adminSearchController = TextEditingController();
  String _adminSearchQuery = '';
  int _adminCurrentPage = 1;
  final int _adminEntriesPerPage = 5;

  final List<Map<String, String>> _admins = [
    {
      'name': 'Nathaniel Nagal',
      'firstName': 'Nathaniel',
      'middleName': 'N/A',
      'lastName': 'Nagal',
      'username': 'dev',
      'phone': '0947-813-3253',
      'email': 'bullacravecustomerservice@gmail.com',
      'role': 'Super Admin',
      'address': 'Star Apple Street, Kasiglahan Rodriguez Rizal',
    },
    {
      'name': 'Arinthea Salamander Vargas',
      'firstName': 'Arinthea',
      'middleName': 'Salamander',
      'lastName': 'Vargas',
      'username': 'arinthea',
      'phone': '0912-345-6789',
      'email': 'arinthea@example.com',
      'role': 'Admin',
      'address': '123 Sample Street, Quezon City',
    },
  ];

  // ── Employee List state ──────────────────────────────────────────────────
  final TextEditingController _employeeSearchController =
      TextEditingController();
  String _employeeSearchQuery = '';
  int _employeeCurrentPage = 1;
  final int _employeeEntriesPerPage = 5;

  final List<Map<String, String>> _employees = [
    {'name': 'Alvince Mavares', 'position': 'Salesperson'},
    {'name': 'Marion Brix Ouling', 'position': 'Technician'},
    {'name': 'Vivian Leigh Marion', 'position': 'Technician'},
  ];

  // ── Helpers ──────────────────────────────────────────────────────────────
  List<Map<String, String>> get _filteredAdmins {
    if (_adminSearchQuery.isEmpty) return _admins;
    return _admins
        .where((a) =>
            a['name']!.toLowerCase().contains(_adminSearchQuery.toLowerCase()) ||
            a['role']!.toLowerCase().contains(_adminSearchQuery.toLowerCase()))
        .toList();
  }

  List<Map<String, String>> get _paginatedAdmins {
    final start = (_adminCurrentPage - 1) * _adminEntriesPerPage;
    final filtered = _filteredAdmins;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, (start + _adminEntriesPerPage).clamp(0, filtered.length));
  }

  List<Map<String, String>> get _filteredEmployees {
    if (_employeeSearchQuery.isEmpty) return _employees;
    return _employees
        .where((e) =>
            e['name']!
                .toLowerCase()
                .contains(_employeeSearchQuery.toLowerCase()) ||
            e['position']!
                .toLowerCase()
                .contains(_employeeSearchQuery.toLowerCase()))
        .toList();
  }

  List<Map<String, String>> get _paginatedEmployees {
    final start = (_employeeCurrentPage - 1) * _employeeEntriesPerPage;
    final filtered = _filteredEmployees;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, (start + _employeeEntriesPerPage).clamp(0, filtered.length));
  }

  @override
  void dispose() {
    _adminSearchController.dispose();
    _employeeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Admin',
        showMenuButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(currentPage: 'Admin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Analytics Cards ──────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: const [
                AnalyticsCard(
                  title: 'Number of Admins',
                  value: '11',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Number of Employee',
                  value: '34',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Total Spare Parts',
                  value: '0',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Available Spare Parts',
                  value: '1,257',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Admin List ───────────────────────────────────────────────
            _buildAdminList(),
            const SizedBox(height: 24),

            // ── Employee List ────────────────────────────────────────────
            _buildEmployeeList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Admin List card ──────────────────────────────────────────────────────
  Widget _buildAdminList() {
    final paginated = _paginatedAdmins;
    final filtered = _filteredAdmins;
    final totalPages =
        (filtered.length / _adminEntriesPerPage).ceil().clamp(1, 9999);
    final startEntry =
        filtered.isEmpty ? 0 : (_adminCurrentPage - 1) * _adminEntriesPerPage + 1;
    final endEntry =
        (startEntry + _adminEntriesPerPage - 1).clamp(0, filtered.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Admin List',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAdminScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search + Filter row
          _buildSearchRow(
            controller: _adminSearchController,
            onChanged: (v) => setState(() {
              _adminSearchQuery = v;
              _adminCurrentPage = 1;
            }),
          ),
          const SizedBox(height: 12),

          // Table header
          _buildTableHeader(col1: 'Name', col2: 'Role'),

          // Rows
          ...paginated.map((admin) => _buildAdminTableRow(context, admin)),

          const SizedBox(height: 12),

          // Pagination
          _buildPaginationFooter(
            label:
                'Showing $startEntry to $endEntry of ${filtered.length} entries',
            currentPage: _adminCurrentPage,
            totalPages: totalPages,
            onFirst: () => setState(() => _adminCurrentPage = 1),
            onPrev: () =>
                setState(() {
                  if (_adminCurrentPage > 1) _adminCurrentPage--;
                }),
            onNext: () =>
                setState(() {
                  if (_adminCurrentPage < totalPages) _adminCurrentPage++;
                }),
            onLast: () => setState(() => _adminCurrentPage = totalPages),
          ),
        ],
      ),
    );
  }

  // ── Employee List card ───────────────────────────────────────────────────
  Widget _buildEmployeeList() {
    final paginated = _paginatedEmployees;
    final filtered = _filteredEmployees;
    final totalPages =
        (filtered.length / _employeeEntriesPerPage).ceil().clamp(1, 9999);
    final startEntry = filtered.isEmpty
        ? 0
        : (_employeeCurrentPage - 1) * _employeeEntriesPerPage + 1;
    final endEntry =
        (startEntry + _employeeEntriesPerPage - 1).clamp(0, filtered.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Employee List',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEmployeeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Employee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search + Filter row
          _buildSearchRow(
            controller: _employeeSearchController,
            onChanged: (v) => setState(() {
              _employeeSearchQuery = v;
              _employeeCurrentPage = 1;
            }),
          ),
          const SizedBox(height: 12),

          // Table header
          _buildTableHeader(col1: 'Name', col2: 'Position'),

          // Rows
          ...paginated.map((emp) => _buildEmployeeTableRow(context, emp)),

          const SizedBox(height: 12),

          // Pagination
          _buildPaginationFooter(
            label:
                'Showing $startEntry to $endEntry of ${filtered.length} entries',
            currentPage: _employeeCurrentPage,
            totalPages: totalPages,
            onFirst: () => setState(() => _employeeCurrentPage = 1),
            onPrev: () =>
                setState(() {
                  if (_employeeCurrentPage > 1) _employeeCurrentPage--;
                }),
            onNext: () =>
                setState(() {
                  if (_employeeCurrentPage < totalPages) _employeeCurrentPage++;
                }),
            onLast: () => setState(() => _employeeCurrentPage = totalPages),
          ),
        ],
      ),
    );
  }

  // ── Shared UI helpers ────────────────────────────────────────────────────
  Widget _buildSearchRow({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Text('Filter',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(width: 4),
              Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader({required String col1, required String col2}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            flex: 3,
            child: Text(col1,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
          ),
          Expanded(
            flex: 2,
            child: Text(col2,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'Actions',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTableRow(BuildContext context, Map<String, String> admin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(admin['name']!,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          Expanded(
            flex: 2,
            child: Text(admin['role']!,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          SizedBox(
            width: 72,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminDetailScreen(admin: admin),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                side: const BorderSide(color: Color(0xFF2563EB)),
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
        ],
      ),
    );
  }

  Widget _buildEmployeeTableRow(BuildContext context, Map<String, String> emp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(emp['name']!,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          Expanded(
            flex: 2,
            child: Text(emp['position']!,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          SizedBox(
            width: 72,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailScreen(employee: emp),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                side: const BorderSide(color: Color(0xFF2563EB)),
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
        ],
      ),
    );
  }

  Widget _buildPaginationFooter({
    required String label,
    required int currentPage,
    required int totalPages,
    required VoidCallback onFirst,
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required VoidCallback onLast,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Row(
          children: [
            _PageButton(
                icon: Icons.first_page,
                onTap: onFirst,
                enabled: currentPage > 1),
            _PageButton(
                icon: Icons.chevron_left,
                onTap: onPrev,
                enabled: currentPage > 1),
            _PageButton(
                icon: Icons.chevron_right,
                onTap: onNext,
                enabled: currentPage < totalPages),
            _PageButton(
                icon: Icons.last_page,
                onTap: onLast,
                enabled: currentPage < totalPages),
          ],
        ),
      ],
    );
  }
}

// ── Pagination arrow button ──────────────────────────────────────────────────
class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _PageButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.black87 : Colors.grey[400],
        ),
      ),
    );
  }
}
