import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/models/user.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/animated_fade_slide.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../widgets/dashboard_charts.dart';

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

  // ── Analytics state ─────────────────────────────────────────────────────
  List<int> _soldProductsMonthly = List.filled(12, 0);
  Map<String, int> _servicesBreakdown = const {
    'Repair': 0, 'Maintenance': 0, 'Installation': 0, 'Delivery': 0,
  };
  List<Map<String, dynamic>> _topProducts = const [];
  List<int> _clientGrowthMonthly = List.filled(12, 0);
  bool _chartsLoading = true;

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
    _fetchAnalytics();
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
  Future<void> _fetchAnalytics() async {
    try {
      final year = DateTime.now().year;
      final results = await Future.wait([
        _api.getSoldProductsMonthly(year: year),
        _api.getServicesBreakdown(),
        _api.getTopProducts(),
        _api.getClientGrowthMonthly(year: year),
      ]);
      if (!mounted) return;
      setState(() {
        _soldProductsMonthly =
            results[0] as List<int>? ?? List.filled(12, 0);
        _servicesBreakdown =
            results[1] as Map<String, int>? ?? _servicesBreakdown;
        _topProducts =
            results[2] as List<Map<String, dynamic>>? ?? const [];
        _clientGrowthMonthly =
            results[3] as List<int>? ?? List.filled(12, 0);
        _chartsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chartsLoading = false);
    }
  }

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
                            title: 'Services',
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

            // ── Analytics charts ─────────────────────────────────────
            if (_chartsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 180),
                child: SoldProductsBarChart(
                  monthlyCounts: _soldProductsMonthly,
                  year: DateTime.now().year,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 260),
                child: ServicesDonutChart(breakdown: _servicesBreakdown),
              ),
              const SizedBox(height: 14),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 340),
                child: TopProductsChart(products: _topProducts),
              ),
              const SizedBox(height: 14),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 420),
                child: ClientGrowthLineChart(
                  monthlyCounts: _clientGrowthMonthly,
                  year: DateTime.now().year,
                ),
              ),
              const SizedBox(height: 8),
            ],
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
  Widget _buildEditRow(String label, TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
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
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
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

  // ── Change Password dialog ───────────────────────────────────────────────
  void _showChangePasswordDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => const _ChangePasswordDialog(),
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
    final screenHeight = MediaQuery.of(context).size.height;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
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
        child: SingleChildScrollView(
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
                  _ProfileInfoRow(label: 'Username', value: _usernameCtrl.text),
                  _isEditing
                      ? _buildEditRow('Address', _addressCtrl)
                      : _ProfileInfoRow(label: 'Address', value: _addressCtrl.text),
                  _isEditing
                      ? _buildEditRow('Phone', _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ])
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
                            try {
                              final updated = await _api.updateProfile(
                                address: _addressCtrl.text.trim(),
                                phone: _phoneCtrl.text.trim(),
                                email: _emailCtrl.text.trim(),
                              );
                              if (!mounted) return;
                              setState(() {
                                _profileUser = updated;
                                _isEditing = false;
                              });
                              SessionFlags.loggedInUser = updated;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully.')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e is ApiException ? e.message : 'Failed to update profile.')),
                              );
                            }
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
                  // Change Password button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showChangePasswordDialog(),
                      icon: const Icon(Icons.lock_outline, size: 18),
                      label: const Text('Change Password'),
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
                ],
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Change Password Dialog ────────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _api = BackendApi();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  String? _oldError;
  String? _newError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _oldError = null;
      _newError = null;
      _confirmError = null;
      _generalError = null;

      if (_oldCtrl.text.isEmpty) {
        _oldError = 'Old password is required.';
        valid = false;
      }
      if (_newCtrl.text.isEmpty) {
        _newError = 'New password is required.';
        valid = false;
      } else if (_newCtrl.text.length < 6) {
        _newError = 'Must be at least 6 characters.';
        valid = false;
      }
      if (_confirmCtrl.text.isEmpty) {
        _confirmError = 'Please confirm your new password.';
        valid = false;
      } else if (_confirmCtrl.text != _newCtrl.text) {
        _confirmError = 'Passwords do not match.';
        valid = false;
      }
    });
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() {
      _loading = true;
      _generalError = null;
    });
    try {
      await _api.changePassword(
        oldPassword: _oldCtrl.text,
        newPassword: _newCtrl.text,
        newPasswordConfirmation: _confirmCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (e.fieldErrors.containsKey('old_password')) {
          _oldError = e.fieldErrors['old_password'];
        }
        if (e.fieldErrors.containsKey('new_password')) {
          _newError = e.fieldErrors['new_password'];
        }
        if (e.fieldErrors.containsKey('new_password_confirmation')) {
          _confirmError = e.fieldErrors['new_password_confirmation'];
        }
        if (e.fieldErrors.isEmpty) {
          _generalError = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generalError = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.88;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth > 400 ? 400 : dialogWidth,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              if (_generalError != null) ...[
                Text(
                  _generalError!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 12),
              ],
              _buildPasswordField(
                controller: _oldCtrl,
                label: 'Old Password',
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
                error: _oldError,
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                error: _newError,
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                error: _confirmError,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: error != null ? const Color(0xFFEF4444) : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: error != null ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey[500],
              ),
              onPressed: onToggle,
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ),
      ],
    );
  }
}
