import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String selectedService = 'Service Types';
  String selectedMonth = 'Select Months to Compare';

  // ── Profile panel state ──────────────────────────────────────────────────
  bool _profileVisible = false;
  bool _isEditing = false;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final AnimationController _profileAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: 'dev');
    _addressCtrl  = TextEditingController(text: 'DEv');
    _phoneCtrl    = TextEditingController(text: '0962-464-3757');
    _emailCtrl    = TextEditingController(text: 'maryosepkaalvince@gmail.com');
    _profileAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    // Panel slides up from the bottom edge
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _profileAnim, curve: Curves.easeOutCubic));
    // Backdrop fades in
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _profileAnim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _profileAnim.dispose();
    super.dispose();
  }

  /// Toggle the profile panel open / closed.
  void _toggleProfile() {
    if (_profileVisible) {
      _profileAnim.reverse().then((_) {
        if (mounted) setState(() => _profileVisible = false);
      });
    } else {
      setState(() => _profileVisible = true);
      _profileAnim.forward();
    }
  }

  /// Close the profile panel (used by backdrop tap & close button).
  void _closeProfile() {
    if (!_profileVisible) return;
    _profileAnim.reverse().then((_) {
      if (mounted) setState(() => _profileVisible = false);
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Dashboard',
        showMenuButton: true,
        actions: [
          // Notification icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          // Profile avatar — tapping opens the slide-up panel
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _toggleProfile,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black.withOpacity(0.08),
                child: Icon(
                  Icons.person_outline,
                  size: 22,
                  color: _profileVisible
                      ? const Color(0xFF2563EB)
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentPage: 'Dashboard'),
      // Wrap the body in a Stack so the overlay can float above the content
      body: Stack(
        children: [
          // ── Main scrollable content ────────────────────────────────────
          SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Back Section
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

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
                  title: 'Client',
                  value: '618',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Sold Product',
                  value: '5,627',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Total Services',
                  value: '625',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
                AnalyticsCard(
                  title: 'Shops',
                  value: '601',
                  backgroundColor: Color(0xFFB3E5FC),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sold Product in 2026 Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sold Product in 2026',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 700,
                        minY: 0,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 100,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr'];
                                if (value.toInt() >= 0 && value.toInt() < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      months[value.toInt()],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 100,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: 150,
                                color: const Color(0xFF6366F1),
                                width: 32,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: 550,
                                color: const Color(0xFF6366F1),
                                width: 32,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: 450,
                                color: const Color(0xFF6366F1),
                                width: 32,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: 250,
                                color: const Color(0xFF6366F1),
                                width: 32,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
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
            const SizedBox(height: 20),

            // Available Services Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Service Types dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedService,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Service Types',
                          child: Text('Service Types'),
                        ),
                        DropdownMenuItem(
                          value: 'Service 1',
                          child: Text('Service 1'),
                        ),
                        DropdownMenuItem(
                          value: 'Service 2',
                          child: Text('Service 2'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedService = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Select Months to Compare dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedMonth,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Select Months to Compare',
                          child: Text('Select Months to Compare'),
                        ),
                        DropdownMenuItem(
                          value: 'Last 3 Months',
                          child: Text('Last 3 Months'),
                        ),
                        DropdownMenuItem(
                          value: 'Last 6 Months',
                          child: Text('Last 6 Months'),
                        ),
                        DropdownMenuItem(
                          value: 'Last 12 Months',
                          child: Text('Last 12 Months'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29B6F6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date Labels
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jan 11, 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'August 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'September 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Second Chart (Comparison Chart)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    minY: 0,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!),
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    barGroups: List.generate(8, (index) {
                      final heights = [
                        [65.0, 0.0],  // First pair - tall light blue only
                        [25.0, 50.0], // Second pair
                        [0.0, 30.0],  // Third pair - short dark blue only
                        [40.0, 0.0],  // Fourth pair - medium light blue only
                        [0.0, 35.0],  // Fifth pair - short dark blue only
                        [55.0, 0.0],  // Sixth pair - tall light blue only
                        [0.0, 25.0],  // Seventh pair - short dark blue only
                        [80.0, 0.0],  // Eighth pair - very tall light blue only
                      ];
                      
                      return BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: [
                          if (heights[index][0] > 0)
                            BarChartRodData(
                              toY: heights[index][0],
                              color: const Color(0xFF93C5FD),
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                              ),
                            ),
                          if (heights[index][1] > 0)
                            BarChartRodData(
                              toY: heights[index][1],
                              color: const Color(0xFF3B82F6),
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // ── Semi-transparent backdrop ─────────────────────────────────────
      // Tapping anywhere on the backdrop dismisses the profile panel
      if (_profileVisible)
        FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _closeProfile,
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
        ),

      // ── Sliding profile card ──────────────────────────────────────────
      // Anchored to the bottom; SlideTransition carries it up smoothly
      if (_profileVisible)
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnim,
            child: _buildProfilePanel(),
          ),
        ),
        ],        // end Stack children
      ),          // end Stack (body)
    );
  }

  // ── Editable row helper ─────────────────────────────────────────────────
  Widget _buildEditRow(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile panel widget ─────────────────────────────────────────────────
  // Returns the floating card shown when the profile avatar is tapped
  Widget _buildProfilePanel() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag-handle pill at the top (visual affordance)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Close button ──────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: _closeProfile,
              ),
            ),
            // ── Profile avatar ────────────────────────────────────────
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.person, size: 52, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            // ── Full name ─────────────────────────────────────────────
            const Text(
              'Alvince Maryosep',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // ── Email subtitle ────────────────────────────────────────
            const Text(
              'maryosepkaalvince@gmail.com',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            // ── Info rows ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _isEditing
                      ? _buildEditRow('Username', _usernameCtrl)
                      : _ProfileInfoRow(label: 'Username', value: _usernameCtrl.text),
                  _isEditing
                      ? _buildEditRow('Address', _addressCtrl)
                      : _ProfileInfoRow(label: 'Address', value: _addressCtrl.text),
                  _isEditing
                      ? _buildEditRow('Phone', _phoneCtrl)
                      : _ProfileInfoRow(label: 'Phone', value: _phoneCtrl.text),
                  _isEditing
                      ? _buildEditRow('Email', _emailCtrl)
                      : _ProfileInfoRow(label: 'Email', value: _emailCtrl.text),
                  const _ProfileInfoRow(label: 'Role', value: 'Admin'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Action buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  // Edit / Save profile button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isEditing = !_isEditing);
                      },
                      icon: Icon(
                        _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                        size: 18,
                      ),
                      label: Text(_isEditing ? 'Save' : 'Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Logout button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
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

// ── Reusable profile info row ─────────────────────────────────────────────────
// Displays a label/value pair inside the profile panel
class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
