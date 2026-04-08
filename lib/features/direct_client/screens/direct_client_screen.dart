import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/shop.dart';
import '../../../shared/widgets/analytics_card.dart';
import '../../../shared/widgets/animated_fade_slide.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../providers/client_list_provider.dart';
import 'clientshop_details_screen.dart';
import 'screens/add_client/add_buttons_screen.dart';

class DirectClientScreen extends ConsumerStatefulWidget {
  const DirectClientScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DirectClientScreen> createState() =>
      _DirectClientScreenState();
}

class _DirectClientScreenState extends ConsumerState<DirectClientScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Fetch on first mount only.  If the provider already has data (e.g.
    // navigating back from a sub-screen), cached state is shown immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(clientListProvider).clients.isEmpty) {
        ref.read(clientListProvider.notifier).fetch();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref
          .read(clientListProvider.notifier)
          .setQuery(_searchController.text.trim());
    });
  }

  Shop? _primaryShopForClient(int clientId, List<Shop> shops) {
    for (final shop in shops) {
      if (shop.clientId == clientId) return shop;
    }
    return null;
  }

  String _asString(dynamic value) => value?.toString() ?? '';

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(_asString(value)) ?? 0;
  }

  String _clientDisplayName(Map<String, dynamic> client) {
    final fullName = [
      _asString(client['cfirstname']).trim(),
      _asString(client['cmiddlename']).trim(),
      _asString(client['csurname']).trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    if (fullName.isNotEmpty) return fullName;

    final company = _asString(client['ccompanyname']).trim();
    if (company.isNotEmpty) return company;

    final fallback = _asString(client['name']).trim();
    return fallback.isEmpty ? 'Client' : fallback;
  }

  Map<String, String> _clientMap(Map<String, dynamic> client, Shop? shop) {
    final clientId = _asInt(client['id']);
    final name = _clientDisplayName(client);
    final email = _asString(client['cemail']).isNotEmpty
        ? _asString(client['cemail'])
        : _asString(client['email']);
    final phone = _asString(client['cphonenum']).isNotEmpty
        ? _asString(client['cphonenum'])
        : _asString(client['phone']);

    return {
      'client_id': clientId.toString(),
      'name': name,
      'email': email,
      'phone': phone,
      'cfirstname': _asString(client['cfirstname']),
      'cmiddlename': _asString(client['cmiddlename']),
      'csurname': _asString(client['csurname']),
      'ccompanyname': _asString(client['ccompanyname']),
      'notes': _asString(client['notes']),
      'shop_id': shop?.id.toString() ?? '',
      'shop': shop?.shopname ?? '-',
      'address': shop?.saddress ?? '-',
      'pinLocation': shop?.pinLocation ?? '-',
      'googleMaps': shop?.locationLink ?? '',
      'branchType': shop == null
          ? '-'
          : (shop.shopTypeId.trim().isEmpty ? '-' : shop.shopTypeId),
      'contactPerson': shop?.scontactperson ?? name,
      'contactEmail':
          shop?.semailaddress.isNotEmpty == true ? shop!.semailaddress : email,
      'contactNo':
          shop?.scontactnum.isNotEmpty == true ? shop!.scontactnum : phone,
      'viberNo': shop?.svibernum ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(clientListProvider);
    final _clients = s.clients;
    final _shops = s.shops;
    final _isLoadingClients = s.isLoading;
    final _clientsError = s.error;
    final _page = s.page;
    final _lastPage = s.lastPage;
    final _totalClients = s.total;
    const _perPage = ClientListNotifier.perPage;

    final start = _totalClients == 0 ? 0 : ((_page - 1) * _perPage) + 1;
    final end = _totalClients == 0
        ? 0
        : (_page * _perPage) > _totalClients
            ? _totalClients
            : (_page * _perPage);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Direct Client',
        showMenuButton: true,
      ),
      drawer: const AppDrawer(currentPage: 'Direct Client'),
      body: RefreshIndicator(
        onRefresh: () => ref.read(clientListProvider.notifier).fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              title: 'Owner',
                              value: '${s.ownersCount}',
                              backgroundColor: const Color(0xFFB3E5FC),
                            ),
                            AnalyticsCard(
                              title: 'Co-Owner',
                              value: '-',
                              backgroundColor: const Color(0xFFB3E5FC),
                            ),
                            AnalyticsCard(
                              title: 'Shops',
                              value: '${s.shopsCount}',
                              backgroundColor: const Color(0xFFB3E5FC),
                            ),
                            AnalyticsCard(
                              title: 'Successful Service',
                              value: '${s.servicesCount}',
                              backgroundColor: const Color(0xFFB3E5FC),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddButtonsScreen(
                                    mode: AddMode.client,
                                  ),
                                ),
                              );
                              await ref
                                  .read(clientListProvider.notifier)
                                  .fetch();
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Client'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC300),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.read(clientListProvider.notifier).refresh(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Search clients...',
                                hintStyle: TextStyle(
                                    fontSize: 13, color: Colors.grey[400]),
                                prefixIcon: IconButton(
                                  icon: Icon(Icons.search,
                                      size: 18, color: Colors.grey[400]),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Search',
                                  onPressed: () {
                                    _searchDebounce?.cancel();
                                    ref
                                        .read(clientListProvider.notifier)
                                        .setQuery(
                                            _searchController.text.trim());
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
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
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                child: Text(
                                  'Shop',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                child: Text(
                                  'Name',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                child: Text(
                                  'Actions',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingClients)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_clientsError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _clientsError!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFB91C1C)),
                          ),
                        )
                      else if (_clients.isEmpty)
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
                              ],
                            ),
                          ),
                        )
                      else
                        ..._clients.map((client) {
                          final clientId = _asInt(client['id']);
                          final shop = _primaryShopForClient(clientId, _shops);
                          final map = _clientMap(client, shop);
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[200]!, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 8),
                                    child: Text(
                                      map['shop'] ?? '-',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 8),
                                    child: Text(
                                      _clientDisplayName(client),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ClientShopDetailsScreen(
                                              client: map,
                                            ),
                                          ),
                                        );
                                        await ref
                                            .read(clientListProvider.notifier)
                                            .fetch();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 6),
                                        side: const BorderSide(
                                            color: Color(0xFF2563EB)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.visibility_outlined,
                                              size: 13,
                                              color: Color(0xFF2563EB)),
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
                          );
                        }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing $start to $end of $_totalClients entries',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Row(
                            children: [
                              _PaginationButton(
                                icon: Icons.keyboard_double_arrow_left,
                                onPressed: _page > 1
                                    ? () => ref
                                        .read(clientListProvider.notifier)
                                        .setPage(1)
                                    : null,
                              ),
                              _PaginationButton(
                                icon: Icons.chevron_left,
                                onPressed: _page > 1
                                    ? () => ref
                                        .read(clientListProvider.notifier)
                                        .setPage(_page - 1)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$_page',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              _PaginationButton(
                                icon: Icons.chevron_right,
                                onPressed: _page < _lastPage
                                    ? () => ref
                                        .read(clientListProvider.notifier)
                                        .setPage(_page + 1)
                                    : null,
                              ),
                              _PaginationButton(
                                icon: Icons.keyboard_double_arrow_right,
                                onPressed: _page < _lastPage
                                    ? () => ref
                                        .read(clientListProvider.notifier)
                                        .setPage(_lastPage)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

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
          color: onPressed == null ? Colors.grey[350] : Colors.grey[700],
        ),
      ),
    );
  }
}
