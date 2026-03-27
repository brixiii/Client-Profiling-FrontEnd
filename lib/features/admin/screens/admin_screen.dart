import 'package:flutter/material.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/models/user.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/api_exception.dart';
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
  final _api = BackendApi();

  // ── Admin (Users) List state ─────────────────────────────────────────────
  final TextEditingController _adminSearchController = TextEditingController();
  String _adminSearchQuery = '';
  int _adminCurrentPage = 1;
  final int _adminEntriesPerPage = 5;
  List<User> _users = [];
  bool _usersLoading = false;
  int _adminTotalPages = 1;
  int _adminTotal = 0;

  // ── Employee List state ──────────────────────────────────────────────────
  final TextEditingController _employeeSearchController =
      TextEditingController();
  String _employeeSearchQuery = '';
  int _employeeCurrentPage = 1;
  final int _employeeEntriesPerPage = 5;
  List<Employee> _employees = [];
  bool _employeesLoading = false;
  int _employeeTotalPages = 1;
  int _employeeTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadEmployees();
  }

  Future<void> _loadUsers() async {
    setState(() => _usersLoading = true);
    try {
      final response = await _api.getUsers(
        page: _adminCurrentPage,
        perPage: _adminEntriesPerPage,
        q: _adminSearchQuery.isEmpty ? null : _adminSearchQuery,
      );
      if (!mounted) return;
      setState(() {
        _users = response.data;
        _adminTotalPages = response.lastPage.clamp(1, 9999);
        _adminTotal = response.total;
        _usersLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _usersLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _usersLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load admins.')),
      );
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _employeesLoading = true);
    try {
      final response = await _api.getEmployees(
        page: _employeeCurrentPage,
        perPage: _employeeEntriesPerPage,
        q: _employeeSearchQuery.isEmpty ? null : _employeeSearchQuery,
      );
      if (!mounted) return;
      setState(() {
        _employees = response.data;
        _employeeTotalPages = response.lastPage.clamp(1, 9999);
        _employeeTotal = response.total;
        _employeesLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _employeesLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _employeesLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load employees.')),
      );
    }
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
        actions: const [],
      ),
      drawer: const AppDrawer(currentPage: 'Admin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Analytics Cards ──────────────────────────────────────────
            LayoutBuilder(
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
                      title: 'Number of Admins',
                      value: _adminTotal.toString(),
                      backgroundColor: const Color(0xFFB3E5FC),
                    ),
                    AnalyticsCard(
                      title: 'Number of Employee',
                      value: _employeeTotal.toString(),
                      backgroundColor: const Color(0xFFB3E5FC),
                    ),
                  ],
                );
              },
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
    final totalPages = _adminTotalPages;
    final startEntry = _adminTotal == 0 ? 0 : (_adminCurrentPage - 1) * _adminEntriesPerPage + 1;
    final endEntry = (startEntry + _users.length - 1).clamp(0, _adminTotal);

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
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAdminScreen(),
                    ),
                  );
                  if (result == true) {
                    setState(() => _adminCurrentPage = 1);
                    _loadUsers();
                  }
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
            onChanged: (v) {
              setState(() {
                _adminSearchQuery = v;
                _adminCurrentPage = 1;
              });
              _loadUsers();
            },
          ),
          const SizedBox(height: 12),

          // Table header
          _buildTableHeader(col1: 'Name', col2: 'Role'),

          // Rows or loading
          if (_usersLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._users.map((user) => _buildAdminTableRow(context, user)),

          const SizedBox(height: 12),

          // Pagination
          _buildPaginationFooter(
            label: 'Showing $startEntry to $endEntry of $_adminTotal entries',
            currentPage: _adminCurrentPage,
            totalPages: totalPages,
            onFirst: () { setState(() => _adminCurrentPage = 1); _loadUsers(); },
            onPrev: () {
              if (_adminCurrentPage > 1) {
                setState(() => _adminCurrentPage--);
                _loadUsers();
              }
            },
            onNext: () {
              if (_adminCurrentPage < totalPages) {
                setState(() => _adminCurrentPage++);
                _loadUsers();
              }
            },
            onLast: () { setState(() => _adminCurrentPage = totalPages); _loadUsers(); },
          ),
        ],
      ),
    );
  }

  // ── Employee List card ───────────────────────────────────────────────────
  Widget _buildEmployeeList() {
    final totalPages = _employeeTotalPages;
    final startEntry = _employeeTotal == 0 ? 0 : (_employeeCurrentPage - 1) * _employeeEntriesPerPage + 1;
    final endEntry = (startEntry + _employees.length - 1).clamp(0, _employeeTotal);

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
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEmployeeScreen(),
                    ),
                  );
                  if (result == true) {
                    setState(() => _employeeCurrentPage = 1);
                    _loadEmployees();
                  }
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
            onChanged: (v) {
              setState(() {
                _employeeSearchQuery = v;
                _employeeCurrentPage = 1;
              });
              _loadEmployees();
            },
          ),
          const SizedBox(height: 12),

          // Table header
          _buildTableHeader(col1: 'Name', col2: 'Position'),

          // Rows or loading
          if (_employeesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._employees.map((emp) => _buildEmployeeTableRow(context, emp)),

          const SizedBox(height: 12),

          // Pagination
          _buildPaginationFooter(
            label: 'Showing $startEntry to $endEntry of $_employeeTotal entries',
            currentPage: _employeeCurrentPage,
            totalPages: totalPages,
            onFirst: () { setState(() => _employeeCurrentPage = 1); _loadEmployees(); },
            onPrev: () {
              if (_employeeCurrentPage > 1) {
                setState(() => _employeeCurrentPage--);
                _loadEmployees();
              }
            },
            onNext: () {
              if (_employeeCurrentPage < totalPages) {
                setState(() => _employeeCurrentPage++);
                _loadEmployees();
              }
            },
            onLast: () { setState(() => _employeeCurrentPage = totalPages); _loadEmployees(); },
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

  Widget _buildAdminTableRow(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(user.name,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          Expanded(
            flex: 2,
            child: Text(user.role,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          SizedBox(
            width: 72,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDetailScreen(user: user),
                  ),
                );
                if (result != null) _loadUsers();
              },
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

  Widget _buildEmployeeTableRow(BuildContext context, Employee emp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(emp.name,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          Expanded(
            flex: 2,
            child: Text(emp.role,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          SizedBox(
            width: 72,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeDetailScreen(employee: emp),
                  ),
                );
                if (result != null) _loadEmployees();
              },
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
