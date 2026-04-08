import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/session_flags.dart';

import '../../../features/login/screens/login_screen.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/models/availed_service.dart';
import '../../../shared/models/shop_product.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_shop_screen.dart';
import 'productdetailsentities_screen.dart';
import 'services_entities_screen.dart';
import 'screens/add_client/add_buttons_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Map<String, String> client;

  const ClientDetailScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final _api = BackendApi();

  final _productSearchController = TextEditingController();
  final _serviceSearchController = TextEditingController();

  Timer? _productDebounce;
  Timer? _serviceDebounce;

  List<ShopProduct> _products = const [];
  List<AvailedService> _services = const [];

  bool _isProductsLoading = false;
  bool _isServicesLoading = false;

  String? _productsError;
  String? _servicesError;

  int _productPage = 1;
  int _servicePage = 1;
  final int _perPage = 10;

  int _productLastPage = 1;
  int _serviceLastPage = 1;
  int _productTotal = 0;
  int _serviceTotal = 0;

  int _productRequestSeq = 0;
  int _serviceRequestSeq = 0;

  Map<String, String> _serviceTypeNameById = const {};
  Map<int, String> _employeeNameById = const {};

  Map<String, dynamic>? _clientDetails;
  Map<String, dynamic>? _shopDetails;
  int? _activeClientId;
  int? _activeShopId;

  bool _isShopLoading = false;
  String? _shopError;
  bool _isRedirectingToLogin = false;
  int _shopRequestSeq = 0;

  int? get _incomingClientId =>
      int.tryParse(widget.client['client_id'] ?? widget.client['id'] ?? '');

  int? get _incomingShopId => int.tryParse(widget.client['shop_id'] ?? '');

  @override
  void initState() {
    super.initState();
    _activeClientId = _incomingClientId;
    _activeShopId = _incomingShopId;
    _reloadClientScope();
  }

  @override
  void didUpdateWidget(covariant ClientDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousClientId = int.tryParse(
        oldWidget.client['client_id'] ?? oldWidget.client['id'] ?? '');
    final incomingClientId = _incomingClientId;
    final previousShopId = int.tryParse(oldWidget.client['shop_id'] ?? '');
    final incomingShopId = _incomingShopId;

    if (previousClientId != incomingClientId || previousShopId != incomingShopId) {
      _resetStateForClientChange(
        nextClientId: incomingClientId,
        nextShopId: incomingShopId,
      );
      _reloadClientScope();
    }
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _serviceSearchController.dispose();
    _productDebounce?.cancel();
    _serviceDebounce?.cancel();
    super.dispose();
  }

  Future<void> _reloadClientScope() async {
    await _loadLookupData();
    await _fetchClientAndShop();
    await Future.wait([
      _fetchProducts(),
      _fetchServices(),
    ]);
  }

  void _resetStateForClientChange({
    required int? nextClientId,
    required int? nextShopId,
  }) {
    _productDebounce?.cancel();
    _serviceDebounce?.cancel();
    _productRequestSeq++;
    _serviceRequestSeq++;
    _shopRequestSeq++;

    _productSearchController.clear();
    _serviceSearchController.clear();

    setState(() {
      _activeClientId = nextClientId;
      _activeShopId = nextShopId;

      _clientDetails = null;
      _shopDetails = null;
      _products = const [];
      _services = const [];

      _productPage = 1;
      _servicePage = 1;
      _productLastPage = 1;
      _serviceLastPage = 1;
      _productTotal = 0;
      _serviceTotal = 0;

      _isProductsLoading = false;
      _isServicesLoading = false;
      _isShopLoading = false;

      _productsError = null;
      _servicesError = null;
      _shopError = null;
    });
  }

  Future<void> _fetchProducts() async {
    if (_activeShopId == null) {
      setState(() {
        _products = const [];
        _productTotal = 0;
        _productPage = 1;
        _productLastPage = 1;
        _productsError = 'Missing shop id.';
      });
      return;
    }

    final requestId = ++_productRequestSeq;

    setState(() {
      _isProductsLoading = true;
      _productsError = null;
    });

    try {
      final page = await _api.getShopProducts(
        page: _productPage,
        perPage: _perPage,
        q: _productSearchController.text.trim(),
        shopId: _activeShopId,
        clientId: _activeClientId,
      );

      if (!mounted || requestId != _productRequestSeq) return;

      final safeLastPage = page.lastPage <= 0 ? 1 : page.lastPage;
      final safePage =
          _productPage > safeLastPage ? safeLastPage : _productPage;
      final safeTotal = page.total > 0
          ? page.total
          : ((_productPage - 1) * _perPage) + page.data.length;

      setState(() {
        _products = page.data;
        _productPage = safePage;
        _productLastPage = safeLastPage;
        _productTotal = safeTotal;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _productRequestSeq) return;
      if (e.statusCode == 401) {
        _handleSessionExpired();
      }
      setState(
          () => _productsError = _friendlyError(e, 'Failed to load products.'));
    } catch (e) {
      if (!mounted || requestId != _productRequestSeq) return;
      setState(() => _productsError = e.toString());
    } finally {
      if (mounted && requestId == _productRequestSeq) {
        setState(() => _isProductsLoading = false);
      }
    }
  }

  Future<void> _loadLookupData() async {
    try {
      final serviceTypes = await _api.getServiceTypes(page: 1, perPage: 100);
      final employees = await _api.getEmployees(page: 1, perPage: 200);

      if (!mounted) return;

      setState(() {
        _serviceTypeNameById = {
          for (final row in serviceTypes.data)
            if (row.setypename.trim().isNotEmpty)
              row.id.toString(): row.setypename.trim(),
        };

        _employeeNameById = {
          for (final e in employees.data)
            e.id: e.name.trim().isEmpty ? 'Employee ${e.id}' : e.name.trim(),
        };
      });
    } catch (_) {
      // Keep existing rendering fallback when lookups fail.
    }
  }

  Future<void> _fetchClientAndShop() async {
    if (_activeClientId == null) {
      setState(() {
        _clientDetails = null;
        _shopDetails = null;
        _shopError = 'Missing client id.';
      });
      return;
    }

    final requestId = ++_shopRequestSeq;

    setState(() {
      _isShopLoading = true;
      _shopError = null;
    });

    try {
      final client = await _api.getClientById(_activeClientId!);

      dynamic selectedShop;
      if (_activeShopId != null) {
        try {
          final shop = await _api.getShopById(_activeShopId!);
          // Accept the shop regardless of client ownership — the shop_id was
          // explicitly passed from navigation so we trust it.
          selectedShop = shop;
        } catch (_) {
          // getShopById failed; fall through to the shops list lookup.
        }
      }

      if (selectedShop == null) {
        try {
          final shopsPage = await _api.getShops(
            page: 1,
            perPage: 50,
            q: null,
            clientId: _activeClientId,
          );
          if (!mounted || requestId != _shopRequestSeq) return;

          if (shopsPage.data.isNotEmpty) {
            // Prefer the shop that matches the originally passed shop_id.
            selectedShop = shopsPage.data.firstWhere(
              (s) => s.id == _activeShopId,
              orElse: () => shopsPage.data.first,
            );
          }
        } catch (_) {
          // Shops lookup also failed; products will still attempt to load
          // using the original _activeShopId preserved below.
        }
      }

      final shop = selectedShop == null
          ? null
          : {
              'id': selectedShop.id,
              'shopname': selectedShop.shopname,
              'saddress': selectedShop.saddress,
              'pin_location': selectedShop.pinLocation,
              'location_link': selectedShop.locationLink,
              'shop_type_id': selectedShop.shopTypeId,
              'scontactperson': selectedShop.scontactperson,
              'semailaddress': selectedShop.semailaddress,
              'scontactnum': selectedShop.scontactnum,
              'svibernum': selectedShop.svibernum,
              'notes': selectedShop.notes,
            };

      if (!mounted || requestId != _shopRequestSeq) return;

      setState(() {
        _clientDetails = client;
        _shopDetails = shop;
        // Only update _activeShopId when a shop was actually found;
        // preserve the value from navigation if the lookup failed.
        if (selectedShop != null) {
          _activeShopId = selectedShop.id;
        }
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _shopRequestSeq) return;
      if (e.statusCode == 401) {
        _handleSessionExpired();
      }
      setState(
          () => _shopError = _friendlyError(e, 'Failed to load shop details.'));
    } catch (_) {
      if (!mounted || requestId != _shopRequestSeq) return;
      setState(() => _shopError = 'Failed to load shop details.');
    } finally {
      if (mounted && requestId == _shopRequestSeq) {
        setState(() => _isShopLoading = false);
      }
    }
  }

  Future<void> _fetchServices() async {
    if (_activeClientId == null) {
      setState(() {
        _services = const [];
        _serviceTotal = 0;
        _servicePage = 1;
        _serviceLastPage = 1;
        _servicesError = 'Missing client id.';
      });
      return;
    }

    final requestId = ++_serviceRequestSeq;

    setState(() {
      _isServicesLoading = true;
      _servicesError = null;
    });

    try {
      final page = await _api.getAvailedServices(
        page: _servicePage,
        perPage: _perPage,
        q: _serviceSearchController.text.trim(),
        clientId: _activeClientId,
        shopId: _activeShopId,
      );

      if (!mounted || requestId != _serviceRequestSeq) return;

      final safeLastPage = page.lastPage <= 0 ? 1 : page.lastPage;
      final safePage =
          _servicePage > safeLastPage ? safeLastPage : _servicePage;
      final safeTotal = page.total > 0
          ? page.total
          : ((_servicePage - 1) * _perPage) + page.data.length;

      setState(() {
        _services = page.data;
        _servicePage = safePage;
        _serviceLastPage = safeLastPage;
        _serviceTotal = safeTotal;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _serviceRequestSeq) return;
      if (e.statusCode == 401) {
        _handleSessionExpired();
      }
      setState(
          () => _servicesError = _friendlyError(e, 'Failed to load services.'));
    } catch (e) {
      if (!mounted || requestId != _serviceRequestSeq) return;
      setState(() => _servicesError = e.toString());
    } finally {
      if (mounted && requestId == _serviceRequestSeq) {
        setState(() => _isServicesLoading = false);
      }
    }
  }

  void _onProductSearchChanged(String _) {
    _productDebounce?.cancel();
    _productDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _productPage = 1);
      _fetchProducts();
    });
  }

  void _onServiceSearchChanged(String _) {
    _serviceDebounce?.cancel();
    _serviceDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _servicePage = 1);
      _fetchServices();
    });
  }

  String _serviceTypeName(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) return '-';

    final name = _serviceTypeNameById[normalized];
    if (name == null || name.isEmpty) return id;
    return name;
  }

  String _friendlyError(ApiException e, String fallback) {
    if (e.statusCode == 422 && e.fieldErrors.isNotEmpty) {
      return e.fieldErrors.values.join('\n');
    }

    if (e.statusCode == 429) {
      return 'Too many attempts. Please wait a few seconds and try again.';
    }

    if (e.statusCode == 401 || e.statusCode == 404 || e.statusCode == 500) {
      return e.message;
    }

    return e.message.isEmpty ? fallback : e.message;
  }

  void _handleSessionExpired() {
    if (!mounted || _isRedirectingToLogin) return;
    _isRedirectingToLogin = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expired. Please log in again.')),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _employeeName(int? employeeId) {
    if (employeeId == null) return '';
    return _employeeNameById[employeeId] ?? employeeId.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: 'Direct Client',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShopDetailsCard(context),
            const SizedBox(height: 20),
            _buildSectionHeader('Product Details'),
            const SizedBox(height: 8),
            _buildProductsCard(context),
            const SizedBox(height: 20),
            _buildSectionHeader('Services'),
            const SizedBox(height: 8),
            _buildServicesCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildShopDetailsCard(BuildContext context) {
    final shopId =
        _shopDetails?['id']?.toString() ?? widget.client['shop_id'] ?? '';
    final shopName =
        _shopDetails?['shopname']?.toString() ?? widget.client['shop'] ?? '-';
    final address = _shopDetails?['saddress']?.toString() ??
        widget.client['address'] ??
        '-';
    final pinLocation = _shopDetails?['pin_location']?.toString() ??
        widget.client['pinLocation'] ??
        '-';
    final googleMaps = _shopDetails?['location_link']?.toString() ??
        widget.client['googleMaps'] ??
        '';
    final branchType =
        _shopDetails?['shop_type_id']?.toString().isNotEmpty == true
            ? _shopDetails!['shop_type_id'].toString()
            : (widget.client['branchType'] ?? '-');
    final contactPerson =
        _shopDetails?['scontactperson']?.toString().isNotEmpty == true
            ? _shopDetails!['scontactperson'].toString()
            : (widget.client['contactPerson'] ?? widget.client['name'] ?? '-');
    final contactEmail =
        _shopDetails?['semailaddress']?.toString().isNotEmpty == true
            ? _shopDetails!['semailaddress'].toString()
            : (_clientDetails?['cemail']?.toString() ??
                widget.client['contactEmail'] ??
                '-');
    final contactNo =
        _shopDetails?['scontactnum']?.toString().isNotEmpty == true
            ? _shopDetails!['scontactnum'].toString()
            : (_clientDetails?['cphonenum']?.toString() ??
                widget.client['contactNo'] ??
                '-');
    final viberNo = _shopDetails?['svibernum']?.toString() ??
        widget.client['viberNo'] ??
        '-';

    final effectiveClient = {
      ...widget.client,
      'shop_id': shopId,
      'shop': shopName,
      'address': address,
      'pinLocation': pinLocation,
      'googleMaps': googleMaps,
      'branchType': branchType,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactNo': contactNo,
      'viberNo': viberNo,
    };

    final initial = shopName.isNotEmpty ? shopName.substring(0, 1).toUpperCase() : '?';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF87CEEB), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Shop Details',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Info rows
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_isShopLoading) ...[  
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 12),
                ] else if (_shopError != null) ...[  
                  Text(
                    _shopError!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFB91C1C)),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildInfoRow(
                    Icons.location_on_outlined, 'Address', address),
                const SizedBox(height: 14),
                _buildInfoRow(
                    Icons.push_pin_outlined, 'Pin Location', pinLocation),
                const SizedBox(height: 14),
                _buildLinkInfoRow(
                    context, Icons.map_outlined, 'Google Maps', googleMaps),
                const SizedBox(height: 14),
                _buildInfoRow(
                    Icons.store_outlined, 'Branch Type', branchType),
                const SizedBox(height: 14),
                _buildInfoRow(
                    Icons.person_outline, 'Contact Person', contactPerson),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.email_outlined, 'Contact Person Email',
                    contactEmail),
                const SizedBox(height: 14),
                _buildInfoRow(
                    Icons.phone_outlined, 'Contact No.', contactNo),
                const SizedBox(height: 14),
                _buildInfoRow(
                    Icons.chat_bubble_outline, 'Viber No.', viberNo),
                const SizedBox(height: 20),
                // Pill action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditShopScreen(client: effectiveClient),
                            ),
                          );
                          await _fetchClientAndShop();
                          await Future.wait([
                            _fetchProducts(),
                            _fetchServices(),
                          ]);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: SessionFlags.userRole != 'Super Admin' ||
                                shopId.isEmpty
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Shop'),
                                    content: const Text(
                                        'Are you sure you want to delete this shop? This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;

                                try {
                                  await _api.deleteShop(int.parse(shopId));
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Shop deleted successfully.')),
                                  );
                                  setState(() => _shopDetails = null);
                                  await _fetchClientAndShop();
                                  await Future.wait([
                                    _fetchProducts(),
                                    _fetchServices(),
                                  ]);
                                } on ApiException catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Failed to delete shop.')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(BuildContext context) {
    final start = _productTotal == 0 ? 0 : ((_productPage - 1) * _perPage) + 1;
    final end = _productTotal == 0
        ? 0
        : (_productPage * _perPage) > _productTotal
            ? _productTotal
            : (_productPage * _perPage);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSearchField(
                    'Search',
                    controller: _productSearchController,
                    onChanged: _onProductSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddButtonsScreen(
                          mode: AddMode.product,
                          initialClientId: _activeClientId,
                          initialShopId: _activeShopId,
                        ),
                      ),
                    );
                    await _fetchProducts();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
            _buildTableHeader(
              const ['Model Name', 'Model Code', 'Machine Type', 'Quantity', 'Actions']),
          if (_isProductsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_productsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                _productsError!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
              ),
            )
          else if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text(
                'No products found.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            )
          else
            ..._products.map((p) => _buildProductRow(context, p)),
          _buildPaginationFooter(
            start: start,
            end: end,
            total: _productTotal,
            page: _productPage,
            lastPage: _productLastPage,
            onFirst: _productPage > 1
                ? () {
                    setState(() => _productPage = 1);
                    _fetchProducts();
                  }
                : null,
            onPrev: _productPage > 1
                ? () {
                    setState(() => _productPage--);
                    _fetchProducts();
                  }
                : null,
            onNext: _productPage < _productLastPage
                ? () {
                    setState(() => _productPage++);
                    _fetchProducts();
                  }
                : null,
            onLast: _productPage < _productLastPage
                ? () {
                    setState(() => _productPage = _productLastPage);
                    _fetchProducts();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(BuildContext context) {
    final start = _serviceTotal == 0 ? 0 : ((_servicePage - 1) * _perPage) + 1;
    final end = _serviceTotal == 0
        ? 0
        : (_servicePage * _perPage) > _serviceTotal
            ? _serviceTotal
            : (_servicePage * _perPage);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSearchField(
                    'Search',
                    controller: _serviceSearchController,
                    onChanged: _onServiceSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddButtonsScreen(
                          mode: AddMode.service,
                          initialClientId: _activeClientId,
                          initialShopId: _activeShopId,
                        ),
                      ),
                    );
                    await _fetchServices();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Service',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildTableHeader(
              const ['Service Order\nReport No.', 'Service Type', 'Actions']),
          if (_isServicesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_servicesError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                _servicesError!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
              ),
            )
          else if (_services.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text(
                'No services found.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            )
          else
            ..._services.map((s) => _buildServiceRow(context, s)),
          _buildPaginationFooter(
            start: start,
            end: end,
            total: _serviceTotal,
            page: _servicePage,
            lastPage: _serviceLastPage,
            onFirst: _servicePage > 1
                ? () {
                    setState(() => _servicePage = 1);
                    _fetchServices();
                  }
                : null,
            onPrev: _servicePage > 1
                ? () {
                    setState(() => _servicePage--);
                    _fetchServices();
                  }
                : null,
            onNext: _servicePage < _serviceLastPage
                ? () {
                    setState(() => _servicePage++);
                    _fetchServices();
                  }
                : null,
            onLast: _servicePage < _serviceLastPage
                ? () {
                    setState(() => _servicePage = _serviceLastPage);
                    _fetchServices();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey[200]);

  static Future<void> _openUrl(String rawUrl) async {
    if (rawUrl.isEmpty) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (!uri.scheme.startsWith('http'))) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLinkInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    final hasLink = value.isNotEmpty && value.startsWith('http');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: hasLink ? () => _openUrl(value) : null,
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        hasLink ? const Color(0xFF2563EB) : Colors.black87,
                    decoration: hasLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor:
                        hasLink ? const Color(0xFF2563EB) : null,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(
    String hint, {
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, ShopProduct p) {
    final product = p.product;
    final productMap = {
      'id': product.id.toString(),
      'shop_product_id': p.id.toString(),
      'modelName': product.modelName,
      'modelCode': product.modelCode,
      'supplierType': product.applianceType,
      'uom': product.unitsofmeasurement,
      'quantity': p.quantity.toString(),
      'poNumber': '-',
      'drNumber': '-',
      'contractDate': product.contractDate,
      'deliveryDate': product.deliveryDate,
      'installationDate': product.installmentDate,
      'employeeName': product.employeeId.toString(),
      'client_id': product.clientId.toString(),
      'shop_id': p.shopId.toString(),
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(product.modelName,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(product.modelCode.isEmpty ? '-' : product.modelCode,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                product.applianceType.isEmpty ? '-' : product.applianceType,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(
                p.quantity.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
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
                          ProductDetailsEntitiesScreen(product: productMap),
                    ),
                  ).then((_) => _fetchProducts());
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.visibility_outlined,
                        size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 3),
                    Text('View',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(BuildContext context, AvailedService s) {
    final resolvedServiceType = _serviceTypeName(s.serviceTypeId);

    // Build serial+spare-parts display string from pivot data (new format),
    // falling back to the legacy single serial_number_id column.
    final serialStr = s.serialNumbersList.isNotEmpty
        ? s.serialNumbersList.join(', ')
        : (s.serialNumberId.isNotEmpty ? s.serialNumberId : '-');

    final spareStr = s.sparePartsList.isNotEmpty
        ? s.sparePartsList
            .map((sp) => '${sp['name']} ×${sp['quantity']}')
            .join(', ')
        : null;

    final serialSpareParts =
        spareStr != null ? '$serialStr | $spareStr' : serialStr;

    // Build technician display string from pivot data (new format),
    // falling back to the legacy single employee_id column.
    final techStr = s.technicianNames.isNotEmpty
        ? s.technicianNames.join(', ')
        : (s.employeeId != null ? _employeeName(s.employeeId) : '-');

    final serviceMap = {
      'id': s.id.toString(),
      'reportNo': s.controlNumber,
      'controlNumber': s.controlNumber,
      'serviceType': resolvedServiceType,
      'serviceTypeId': s.serviceTypeId,
      'serviceDate': s.serviceDate,
      'serialNumber': s.serialNumbersList.isNotEmpty
          ? s.serialNumbersList.first
          : s.serialNumberId,
      'serialSpareParts': serialSpareParts,
      'technicians': techStr,
      'image': s.image,
      'notes': s.notes,
      'shop_id': s.shopId?.toString() ?? '',
      'client_id': s.clientId.toString(),
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(s.controlNumber.isEmpty ? '-' : s.controlNumber,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Text(resolvedServiceType,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
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
                      builder: (_) => ServicesEntitiesScreen(
                        service: serviceMap,
                        shopName: _shopDetails?['shopname']?.toString() ??
                            widget.client['shop'] ??
                            'Shop',
                      ),
                    ),
                  ).then((_) => _fetchServices());
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.visibility_outlined,
                        size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 3),
                    Text('View',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<String> columns) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          ...columns.sublist(0, columns.length - 1).map((col) => Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Text(
                    col,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )),
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                columns.last,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter({
    required int start,
    required int end,
    required int total,
    required int page,
    required int lastPage,
    required VoidCallback? onFirst,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    required VoidCallback? onLast,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start to $end of $total entries',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Row(
            children: [
              _PaginationBtn(
                  icon: Icons.keyboard_double_arrow_left, onTap: onFirst),
              _PaginationBtn(icon: Icons.chevron_left, onTap: onPrev),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$page',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
              _PaginationBtn(icon: Icons.chevron_right, onTap: onNext),
              _PaginationBtn(
                  icon: Icons.keyboard_double_arrow_right, onTap: onLast),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PaginationBtn({Key? key, required this.icon, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: Colors.grey[600]),
      ),
    );
  }
}
