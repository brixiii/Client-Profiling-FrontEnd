import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api/api_exception.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/models/shop.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../providers/client_shops_provider.dart';
import 'clientproduct_detail_screen.dart';
import 'edit_owner_screen.dart';
import 'screens/add_client/add_buttons_screen.dart';

class ClientShopDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, String> client;

  const ClientShopDetailsScreen({Key? key, required this.client})
      : super(key: key);

  @override
  ConsumerState<ClientShopDetailsScreen> createState() =>
      _ClientShopDetailsScreenState();
}

class _ClientShopDetailsScreenState
    extends ConsumerState<ClientShopDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();

  int? get _clientId =>
      int.tryParse(widget.client['client_id'] ?? widget.client['id'] ?? '');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final shopsAsync = ref.watch(clientShopsProvider(_clientId));
    final _isShopsLoading = shopsAsync.isLoading;
    final _shopsError = shopsAsync.hasError
        ? (shopsAsync.error is ApiException
            ? (shopsAsync.error as ApiException).message
            : 'Failed to load shops.')
        : null;
    final query = _searchController.text.trim().toLowerCase();
    final shops = (shopsAsync.valueOrNull ?? <Shop>[]).where((shop) {
      if (query.isEmpty) return true;
      return shop.shopname.toLowerCase().contains(query) ||
          shop.scontactperson.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(title: 'Direct Client', showMenuButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Client Details Card ────────────────────────────
            Container(
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
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              ((client['contactPerson'] ??
                                          client['ccompanyname'] ??
                                          '?')
                                      .isNotEmpty
                                  ? (client['contactPerson'] ??
                                          client['ccompanyname'] ??
                                          '?')
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?'),
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
                                client['contactPerson'] ?? '-',
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
                                  'Client Account',
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
                        _buildInfoRow(Icons.person_outline, 'Name',
                            client['contactPerson'] ?? '-'),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                          Icons.business_outlined,
                          'Company Name',
                          client['ccompanyname']?.trim().isNotEmpty == true
                              ? client['ccompanyname']!
                              : (client['companyName'] ?? '-'),
                        ),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.email_outlined, 'Email',
                            client['contactEmail'] ?? '-'),
                        const SizedBox(height: 14),
                        _buildInfoRow(Icons.phone_outlined, 'Phone No.',
                            client['contactNo'] ?? '-'),
                        const SizedBox(height: 20),
                        // Pill action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditOwnerScreen(client: client),
                                    ),
                                  );
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    SessionFlags.userRole != 'Super Admin'
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Delete Client'),
                                                content: const Text(
                                                    'Are you sure you want to delete this client? This action cannot be undone.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child:
                                                        const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFEF4444),
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                    ),
                                                    child:
                                                        const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              Navigator.pop(context);
                                            }
                                          },
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
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
            ),
            const SizedBox(height: 24),
            const Text(
              'Shop Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search shops...',
                              hintStyle: TextStyle(
                                  fontSize: 13, color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search,
                                  size: 18, color: Colors.grey[400]),
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
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddButtonsScreen(
                                  mode: AddMode.shop,
                                  initialClientId: _clientId,
                                ),
                              ),
                            );
                            // Invalidate so the provider re-fetches fresh shops.
                            ref.invalidate(clientShopsProvider(_clientId));
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Shop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC300),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            child: Text(
                              'Shop',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            child: Text(
                              'Contact Person',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
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
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (shops.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Column(
                          children: [
                            if (_isShopsLoading)
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(Icons.store_outlined,
                                  size: 44, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(
                              _shopsError ?? 'No shops yet',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _shopsError == null
                                      ? Colors.grey[400]
                                      : const Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...shops.map((shop) => Container(
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
                                      vertical: 16, horizontal: 12),
                                  child: Text(shop.shopname,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 12),
                                  child: Text(
                                      shop.scontactperson.isEmpty
                                          ? '-'
                                          : shop.scontactperson,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Center(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final scopedClient = {
                                        ...client,
                                        'shop_id': shop.id.toString(),
                                        'shop': shop.shopname,
                                        'address': shop.saddress,
                                        'pinLocation': shop.pinLocation,
                                        'googleMaps': shop.locationLink,
                                        'branchType': shop.shopTypeId,
                                        'contactPerson': shop.scontactperson,
                                        'contactEmail': shop.semailaddress,
                                        'contactNo': shop.scontactnum,
                                        'viberNo': shop.svibernum,
                                      };
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ClientDetailScreen(
                                              client: scopedClient),
                                        ),
                                      );
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
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing 1 to ${shops.length} of ${shops.length} entries',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            _PaginationButton(
                                icon: Icons.keyboard_double_arrow_left,
                                onPressed: () {}),
                            _PaginationButton(
                                icon: Icons.chevron_left, onPressed: () {}),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('1',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            _PaginationButton(
                                icon: Icons.chevron_right, onPressed: () {}),
                            _PaginationButton(
                                icon: Icons.keyboard_double_arrow_right,
                                onPressed: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.grey[600]),
      ),
    );
  }
}
