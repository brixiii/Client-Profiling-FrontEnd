import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/models/user.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/animated_fade_slide.dart';
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
  bool _isUploadingPhoto = false;
  int _photoVersion = 0; // incremented after each upload to bust image cache
  String? _uploadedPhotoUrl; // immediately set after upload for instant UI refresh
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final AnimationController _profileAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  // ── Dashboard data ──────────────────────────────────────────────────────
  final _api = BackendApi();
  int _clientCount = 0;
  int _productCount = 0;
  int _servicesCount = 0;
  int _shopsCount = 0;
  User? _profileUser;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController();
    _addressCtrl  = TextEditingController();
    _phoneCtrl    = TextEditingController();
    _emailCtrl    = TextEditingController();
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
    _fetchCards();
    _fetchProfile();
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

  // ── Helpers ─────────────────────────────────────────────────────────────
  String get _profileFullName {
    if (_profileUser == null) return '';
    final parts = [
      _profileUser!.firstname,
      _profileUser!.middlename,
      _profileUser!.surname,
    ].where((p) => p.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : _profileUser!.name;
  }

  /// Returns the first non-null, non-empty photo URL (upload takes priority), or null.
  String? get _currentPhotoUrl {
    if (_uploadedPhotoUrl != null && _uploadedPhotoUrl!.isNotEmpty) {
      return _uploadedPhotoUrl;
    }
    final url = _profileUser?.profilePhotoUrl;
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  // ── Data fetching ────────────────────────────────────────────────────────
  Future<void> _fetchCards() async {
    try {
      final summary = await _api.getDashboardSummary();
      if (!mounted) return;
      setState(() {
        _clientCount   = summary['total_clients']!;
        _productCount  = summary['total_sold_products']!;
        _servicesCount = summary['total_services']!;
        _shopsCount    = summary['total_shops']!;
      });
    } catch (_) {
      // Keep zeroed values on failure.
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await _api.profile();
      debugPrint('[Profile] photo url: ${user.profilePhotoUrl}');
      if (!mounted) return;
      setState(() {
        _profileUser       = user;
        _usernameCtrl.text = user.username;
        _addressCtrl.text  = user.address;
        _phoneCtrl.text    = user.phone;
        _emailCtrl.text    = user.email;
      });
      // Share the fetched user with the drawer (no extra fetch needed anywhere).
      SessionFlags.loggedInUser = user;
    } catch (_) {
      // Profile panel stays empty on failure; main screen is unaffected.
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: kIsWeb, // load bytes on web
    );
    if (result == null) return;
    final file = result.files.single;
    setState(() => _isUploadingPhoto = true);
    try {
      debugPrint('[ProfilePhoto] starting upload, filename: ${file.name}');
      String? newUrl;
      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) return;
        newUrl = await _api.uploadProfilePhotoBytes(bytes, file.name);
      } else {
        final path = file.path;
        if (path == null) return;
        debugPrint('[ProfilePhoto] selected file: $path');
        newUrl = await _api.uploadProfilePhoto(path);
      }
      debugPrint('[ProfilePhoto] upload success, url: $newUrl');
      // Immediately update the avatar without waiting for _fetchProfile.
      if (mounted && newUrl != null && newUrl.isNotEmpty) {
        setState(() {
          _uploadedPhotoUrl = newUrl;
          _photoVersion++;
        });
      }
      await _fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated.')),
        );
      }
    } catch (e) {
      debugPrint('[ProfilePhoto] upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
                child: Builder(
                  builder: (ctx) {
                    final rawUrl = _currentPhotoUrl;
                    debugPrint('[AppBarAvatar] _uploadedPhotoUrl: $_uploadedPhotoUrl');
                    debugPrint('[AppBarAvatar] _profileUser?.profilePhotoUrl: ${_profileUser?.profilePhotoUrl}');
                    final photoUrl = rawUrl != null ? '$rawUrl?v=$_photoVersion' : null;
                    debugPrint('[AppBarAvatar] computed photoUrl: $photoUrl');
                    return ClipOval(
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stack) {
                                debugPrint('[AppBarAvatar] Image.network ERROR: $error');
                                debugPrint('[AppBarAvatar] url was: $photoUrl');
                                return Icon(
                                  Icons.person_outline,
                                  size: 22,
                                  color: _profileVisible
                                      ? const Color(0xFF2563EB)
                                      : Colors.black87,
                                );
                              },
                            )
                          : Icon(
                              Icons.person_outline,
                              size: 22,
                              color: _profileVisible
                                  ? const Color(0xFF2563EB)
                                  : Colors.black87,
                            ),
                    );
                  },
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
            // Welcome Back Section + Analytics Cards — staggered fade-in
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profileUser != null
                        ? 'Welcome Back, ${_profileUser!.firstname.isNotEmpty ? _profileUser!.firstname : _profileUser!.name}!'
                        : 'Welcome Back!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Analytics Cards Grid
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
                            title: 'Clients',
                            value: '$_clientCount',
                            backgroundColor: const Color(0xFFB3E5FC),
                          ),
                          AnalyticsCard(
                            title: 'Sold Products',
                            value: '$_productCount',
                            backgroundColor: const Color(0xFFB3E5FC),
                          ),
                          AnalyticsCard(
                            title: 'Total Services',
                            value: '$_servicesCount',
                            backgroundColor: const Color(0xFFB3E5FC),
                          ),
                          AnalyticsCard(
                            title: 'Shops',
                            value: '$_shopsCount',
                            backgroundColor: const Color(0xFFB3E5FC),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Sold Product in 2026 Chart — fades in with delay
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 180),
              child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sold Products in 2026',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final chartHeight = (constraints.maxWidth * 0.55).clamp(180.0, 280.0);
                      return SizedBox(
                    height: chartHeight,
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
                  );
                    },
                  ),
                ],
              ),
            ),
            ),
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
    final rawUrl = _currentPhotoUrl;
    debugPrint('[ProfilePanel] _uploadedPhotoUrl: $_uploadedPhotoUrl');
    debugPrint('[ProfilePanel] _profileUser?.profilePhotoUrl: ${_profileUser?.profilePhotoUrl}');
    final photoUrl = rawUrl != null ? '$rawUrl?v=$_photoVersion' : null;
    debugPrint('[ProfilePanel] computed photoUrl: $photoUrl');
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
            GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stack) {
                                debugPrint('[ProfilePanel] Image.network ERROR: $error');
                                debugPrint('[ProfilePanel] url was: $photoUrl');
                                return const Icon(
                                  Icons.person,
                                  size: 52,
                                  color: Colors.black54,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 52,
                              color: Colors.black54,
                            ),
                    ),
                  ),
                  if (_isUploadingPhoto)
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Color(0x88000000),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (!_isUploadingPhoto)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Full name ─────────────────────────────────────────────
            Text(
              _profileFullName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // ── Email subtitle ────────────────────────────────────────
            Text(
              _profileUser?.email ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                  _ProfileInfoRow(label: 'Role', value: _profileUser?.role ?? ''),
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
                      onPressed: () async {
                        if (_isEditing) {
                          // Animated dialog: scale + fade in
                          final confirmed = await showGeneralDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black54,
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            transitionBuilder: (ctx, anim, _, child) =>
                                FadeTransition(
                              opacity: CurvedAnimation(
                                  parent: anim, curve: Curves.easeOut),
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.88, end: 1.0)
                                    .animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                            ),
                            pageBuilder: (ctx, _, __) => AlertDialog(
                              title: const Text('Save Changes'),
                              content: const Text(
                                  'Are you sure you want to save these changes?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            setState(() => _isEditing = false);
                          }
                        } else {
                          setState(() => _isEditing = true);
                        }
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
