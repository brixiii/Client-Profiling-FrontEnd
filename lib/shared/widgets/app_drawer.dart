import 'package:flutter/material.dart';
import '../../features/login/screens/login_screen.dart';
import '../models/user.dart';
import '../session_flags.dart';
import '../../features/direct_client/screens/direct_client_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/resellers/screens/resellers_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/csr_guide/screens/csr_guide_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/product_model/screens/product_model_screen.dart';
import '../../features/service_type/screens/service_type_screen.dart';
import '../../features/spare_parts/screens/spare_parts_screen.dart';
import '../../features/serial_number/screens/serial_number_screen.dart';

// Pages that belong to the Inventory group
const _inventoryPages = {
  'Product Model',
  'Service Type',
  'Spare Parts',
  'Serial Number',
};

class AppDrawer extends StatefulWidget {
  final String currentPage;

  const AppDrawer({Key? key, this.currentPage = 'Dashboard'}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late bool _inventoryExpanded;

  @override
  void initState() {
    super.initState();
    // Start expanded if the current page is under Inventory
    _inventoryExpanded = _inventoryPages.contains(widget.currentPage);
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.currentPage;
    return Drawer(
      child: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Dynamic drawer header ─────────────────────────────────
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFF87CEEB),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Builder(
                    builder: (_) {
                      final photoUrl = SessionFlags.loggedInUser?.profilePhotoUrl;
                      if (photoUrl != null && photoUrl.isNotEmpty) {
                        return Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF87CEEB),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Dark gradient overlay so the text is readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                  // Name + subtitle at bottom-left
                  Positioned(
                    left: 20,
                    bottom: 16,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _drawerDisplayName(SessionFlags.loggedInUser),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.1,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black54,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Client Profiling',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black45,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Dashboard ─────────────────────────────────────────────
            _DrawerMenuItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              isSelected: page == 'Dashboard',
              onTap: () {
                if (page != 'Dashboard') _navigate(context, const DashboardScreen());
                else Navigator.pop(context);
              },
            ),

            // ── Direct Client ─────────────────────────────────────────
            _DrawerMenuItem(
              icon: Icons.people_outline,
              label: 'Direct Client',
              isSelected: page == 'Direct Client',
              onTap: () {
                if (page != 'Direct Client') _navigate(context, const DirectClientScreen());
                else Navigator.pop(context);
              },
            ),

            // ── Resellers ─────────────────────────────────────────────
            _DrawerMenuItem(
              icon: Icons.groups_outlined,
              label: 'Resellers',
              isSelected: page == 'Resellers',
              onTap: () {
                if (page != 'Resellers') _navigate(context, const ResellersScreen());
                else Navigator.pop(context);
              },
            ),

            // ── Calendar ─────────────────────────────────────────────
            _DrawerMenuItem(
              icon: Icons.calendar_month_outlined,
              label: 'Calendar',
              isSelected: page == 'Calendar',
              onTap: () {
                if (page != 'Calendar') _navigate(context, const CalendarScreen());
                else Navigator.pop(context);
              },
            ),

            // ── CSR Guide ─────────────────────────────────────────────
            _DrawerMenuItem(
              icon: Icons.folder_outlined,
              label: 'CSR Guide',
              isSelected: page == 'CSR Guide',
              onTap: () {
                if (page != 'CSR Guide') _navigate(context, const CsrGuideScreen());
                else Navigator.pop(context);
              },
            ),

            // ── Inventory (collapsible) — Super Admin only ──────────
            if (SessionFlags.userRole == 'Super Admin')
              _InventoryDrawerItem(
                isExpanded: _inventoryExpanded,
                currentPage: page,
                onToggle: () => setState(() => _inventoryExpanded = !_inventoryExpanded),
                onSubItemTap: (label, screen) {
                  if (page != label) _navigate(context, screen);
                  else Navigator.pop(context);
                },
              ),

            // ── Admin — Super Admin only ──────────────────────────────
            if (SessionFlags.userRole == 'Super Admin')
              _DrawerMenuItem(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin',
                isSelected: page == 'Admin',
                onTap: () {
                  if (page != 'Admin') _navigate(context, const AdminScreen());
                  else Navigator.pop(context);
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
                SessionFlags.reset();
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const LoginScreen(),
                    transitionDuration: const Duration(milliseconds: 400),
                    transitionsBuilder: (_, anim, __, child) => FadeTransition(
                      opacity:
                          CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                      child: child,
                    ),
                  ),
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

// ── Inventory collapsible drawer item ────────────────────────────────────────
class _InventoryDrawerItem extends StatelessWidget {
  final bool isExpanded;
  final String currentPage;
  final VoidCallback onToggle;
  final void Function(String label, Widget screen) onSubItemTap;

  const _InventoryDrawerItem({
    Key? key,
    required this.isExpanded,
    required this.currentPage,
    required this.onToggle,
    required this.onSubItemTap,
  }) : super(key: key);

  static const _subItems = [
    ('Product Model', ProductModelScreen()),
    ('Service Type',  ServiceTypeScreen()),
    ('Spare Parts',   SparePartsScreen()),
    ('Serial Number', SerialNumberScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isGroupSelected =
        _inventoryPages.contains(currentPage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────
          Material(
            color: isGroupSelected
                ? const Color(0xFF87CEEB).withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.checklist_outlined,
                      size: 22,
                      color: isGroupSelected
                          ? const Color(0xFF2563EB)
                          : Colors.black87,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Inventory',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isGroupSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isGroupSelected
                              ? const Color(0xFF2563EB)
                              : Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: isGroupSelected
                            ? const Color(0xFF2563EB)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Sub-items (animated expand/collapse) ────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: List.generate(_subItems.length, (index) {
                  final (label, screen) = _subItems[index];
                  final isActive = currentPage == label;
                  return Column(
                    children: [
                      if (index != 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade200,
                        ),
                      InkWell(
                        onTap: () => onSubItemTap(label, screen),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          color: isActive
                              ? const Color(0xFF87CEEB).withOpacity(0.12)
                              : Colors.transparent,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? const Color(0xFF2563EB)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Standard drawer menu item ─────────────────────────────────────────────────
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

// ── Drawer helper: build display name from User fields ────────────────────────
String _drawerDisplayName(User? user) {
  if (user == null) return '';
  final parts = [user.firstname, user.middlename, user.surname]
      .where((p) => p.isNotEmpty)
      .join(' ');
  return parts.isNotEmpty ? parts : user.name;
}

// ── Drawer profile avatar with network image + fallback ───────────────────────
class _DrawerAvatar extends StatelessWidget {
  final User? user;

  const _DrawerAvatar({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.profilePhotoUrl;
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white.withOpacity(0.3),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 28,
                  color: Colors.white,
                ),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Icon(
                    Icons.person,
                    size: 28,
                    color: Colors.white,
                  );
                },
              )
            : const Icon(
                Icons.person,
                size: 28,
                color: Colors.white,
              ),
      ),
    );
  }
}