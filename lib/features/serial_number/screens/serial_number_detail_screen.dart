import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/serial_number_model.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'edit_serial_number_screen.dart';
import '../../direct_client/screens/clientshop_details_screen.dart';

class SerialNumberDetailScreen extends StatefulWidget {
  final int serialId;
  final int clientId;

  const SerialNumberDetailScreen({
    Key? key,
    required this.serialId,
    required this.clientId,
  }) : super(key: key);

  @override
  State<SerialNumberDetailScreen> createState() =>
      _SerialNumberDetailScreenState();
}

class _SerialNumberDetailScreenState extends State<SerialNumberDetailScreen> {
  final _api = BackendApi();

  SerialNumberModel? _item;
  List<SerialNumberModel> _serialRows = [];

  bool _loading = true;
  bool _deleting = false;
  bool _navigating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await _api.getSerialNumberById(widget.serialId);
      final rows = await _api.getSerialNumbers(
        page: 1,
        perPage: 100,
        clientId: widget.clientId,
      );

      if (mounted) {
        setState(() {
          _item = item;
          _serialRows = rows.data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return 'N/A';
    try {
      return DateFormat('MM/dd/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Future<void> _viewClient() async {
    setState(() => _navigating = true);
    try {
      final raw = await _api.getClientById(widget.clientId);
      if (!mounted) return;

      String asStr(dynamic v) => v?.toString() ?? '';

      final firstName = asStr(raw['cfirstname']).trim();
      final surname = asStr(raw['csurname']).trim();
      final fullName = [firstName, asStr(raw['cmiddlename']).trim(), surname]
          .where((p) => p.isNotEmpty)
          .join(' ');
      final displayName = fullName.isNotEmpty
          ? fullName
          : asStr(raw['ccompanyname']).trim().isNotEmpty
              ? asStr(raw['ccompanyname']).trim()
              : 'Client';

      final clientMap = <String, String>{
        'client_id': asStr(raw['id']),
        'name': displayName,
        // Keys read by ClientShopDetailsScreen
        'contactPerson': displayName,
        'contactEmail': asStr(raw['cemail']).isNotEmpty
            ? asStr(raw['cemail'])
            : asStr(raw['email']),
        'contactNo': asStr(raw['cphonenum']).isNotEmpty
            ? asStr(raw['cphonenum'])
            : asStr(raw['phone']),
        // Extra fields used by EditOwnerScreen / other sub-screens
        'email': asStr(raw['cemail']).isNotEmpty
            ? asStr(raw['cemail'])
            : asStr(raw['email']),
        'phone': asStr(raw['cphonenum']).isNotEmpty
            ? asStr(raw['cphonenum'])
            : asStr(raw['phone']),
        'cfirstname': asStr(raw['cfirstname']),
        'cmiddlename': asStr(raw['cmiddlename']),
        'csurname': asStr(raw['csurname']),
        'ccompanyname': asStr(raw['ccompanyname']),
        'notes': asStr(raw['notes']),
        'viberNo': asStr(raw['svibernum']),
      };

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClientShopDetailsScreen(client: clientMap),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _confirmDelete() async {    final name = _item?.clientName.isNotEmpty == true
        ? _item!.clientName
        : 'this serial number';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Delete Serial Number',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('Delete serial data for "$name"?',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );

    if (confirmed != true || _item == null || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _api.deleteSerialNumber(_item!.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deleted successfully.')));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Inventory', showMenuButton: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final item = _item!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Serial Number',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),

                _InfoRow(label: 'Client Name', value: item.clientName),
                const SizedBox(height: 12),
                _InfoRow(
                    label: 'Client Type',
                    value: item.supplierType.isEmpty ? 'N/A' : item.supplierType),
                const SizedBox(height: 12),
                _InfoRow(label: 'Date Created', value: _formatDate(item.createdAt)),
                const SizedBox(height: 24),

                const Text(
                  'Serial Numbers',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _serialRows.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('No serial numbers found.'),
                        )
                      : Column(
                          children: List.generate(_serialRows.length, (i) {
                            final row = _serialRows[i];
                            final isLast = i == _serialRows.length - 1;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          row.serialnumber,
                                          style: const TextStyle(
                                              fontSize: 16, color: Colors.black87),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final changed =
                                              await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EditSerialNumberScreen(item: row),
                                            ),
                                          );
                                          if (changed == true) {
                                            _loadData();
                                          }
                                        },
                                        child: const Icon(
                                          Icons.edit_square,
                                          size: 26,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFEEEEEE)),
                              ],
                            );
                          }),
                        ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _navigating ? null : _viewClient,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _navigating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black54),
                        )
                      : const Text(
                          'View Client',
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _deleting ? null : _confirmDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
