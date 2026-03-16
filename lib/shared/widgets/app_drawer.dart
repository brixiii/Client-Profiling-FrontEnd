import 'package:flutter/material.dart';
import '../../features/login/screens/login_screen.dart';
import '../../features/direct_client/screens/direct_client_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/resellers/screens/resellers_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/csr_guide/screens/csr_guide_screen.dart';
import '../../features/admin/screens/admin_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentPage;
  
  const AppDrawer({Key? key, this.currentPage = 'Dashboard'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Branded drawer header ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF87CEEB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Client Profiling',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Management System',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerMenuItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              isSelected: currentPage == 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'Dashboard') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            _DrawerMenuItem(
              icon: Icons.people_outline,
              label: 'Direct Client',
              isSelected: currentPage == 'Direct Client',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'Direct Client') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DirectClientScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            _DrawerMenuItem(
              icon: Icons.groups_outlined,
              label: 'Resellers',
              isSelected: currentPage == 'Resellers',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'Resellers') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResellersScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            _DrawerMenuItem(
              icon: Icons.calendar_month_outlined,
              label: 'Calendar',
              isSelected: currentPage == 'Calendar',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'Calendar') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            _DrawerMenuItem(
              icon: Icons.folder_outlined,
              label: 'CSR Guide',
              isSelected: currentPage == 'CSR Guide',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'CSR Guide') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CsrGuideScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            _DrawerMenuItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              isSelected: currentPage == 'Admin',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'Admin') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(),
            ),
            _DrawerMenuItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        color: isSelected ? const Color(0xFF87CEEB).withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: isSelected ? 0 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
