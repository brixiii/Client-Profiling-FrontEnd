import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/paginated_response.dart';
import '../../../shared/models/shop.dart';
import '../../service_type/models/service_type_model.dart';

const List<String> _kStatuses = [
  'Pending',
  'Tentative',
  'Final',
  'Resolved',
];

void showAddScheduleDialog(
  BuildContext context, {
  DateTime? date,
  VoidCallback? onCreated,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => _AddScheduleDialog(date: date, onCreated: onCreated),
  );
}

class _AddScheduleDialog extends StatefulWidget {
  final DateTime? date;
  final VoidCallback? onCreated;

  const _AddScheduleDialog({Key? key, this.date, this.onCreated})
      : super(key: key);

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  // Controllers
  final _clientSearchCtrl = TextEditingController();
  final _clientSearchFocusNode = FocusNode();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pinLocationCtrl = TextEditingController();
  final _locationLinkCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _tollCtrl = TextEditingController();
  final _gasCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Radio – client source
  bool _useDefault = true; // true = Default, false = Asterisk

  // Dropdowns
  String? _selectedShop;
  String? _selectedServiceType;
  String _selectedStatus = 'Pending';
  late DateTime _selectedDate;

  // Tech slots — store efullname; resolved to ID on save
  final List<String?> _techSlotValues = [null, null, null, null, null];

  // Client search state
  List<Map<String, dynamic>> _clientSuggestions = [];
  bool _isSearchingClients = false;
  int? _selectedClientId;
  bool _isLoadingShopsForClient = false;
  Timer? _clientSearchDebounce;

  // API-fetched options
  List<Shop> _shops = [];
  List<Map<String, dynamic>> _serviceTypes = [];
  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingDeps = false;
  bool _isSaving = false;

  final BackendApi _api = BackendApi();

  @override
  void initState() {
    super.initState();
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _selectedDate = (widget.date != null && !widget.date!.isBefore(today))
        ? widget.date!
        : today;
    // Show initial client list when the field gains focus (dropdown behaviour).
    _clientSearchFocusNode.addListener(_onClientFocusChanged);
    _loadDeps();
  }

  @override
  void dispose() {
    _clientSearchCtrl.dispose();
    _clientSearchFocusNode.dispose();
    _clientSearchDebounce?.cancel();
    _contactCtrl.dispose();
    _addressCtrl.dispose();
    _pinLocationCtrl.dispose();
    _locationLinkCtrl.dispose();
    _vehicleCtrl.dispose();
    _tollCtrl.dispose();
    _gasCtrl.dispose();
    _notesCtrl.dispose();
    _clientSearchFocusNode.removeListener(_onClientFocusChanged);
    super.dispose();
  }

  Future<void> _loadDeps() async {
    setState(() => _isLoadingDeps = true);
    try {
      final stRespFuture = _api.getServiceTypes(page: 1, perPage: 100);
      final empRespFuture = _api.getCalendarEmployees(page: 1, perPage: 100);
      final PaginatedResponse<ServiceTypeModel> stResp = await stRespFuture;
      final PaginatedResponse<Map<String, dynamic>> empResp = await empRespFuture;
      if (!mounted) return;
      setState(() {
        _serviceTypes = stResp.data
            .map((s) => <String, dynamic>{'id': s.id, 'setypename': s.setypename})
            .toList();
        _employees = empResp.data;
        _isLoadingDeps = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDeps = false);
    }
  }

  Future<void> _loadShopsForClient(int clientId) async {
    setState(() {
      _isLoadingShopsForClient = true;
      _shops = [];
      _selectedShop = null;
    });
    try {
      final resp =
          await _api.getShops(page: 1, perPage: 100, clientId: clientId);
      if (!mounted) return;
      setState(() {
        _shops = resp.data;
        _isLoadingShopsForClient = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingShopsForClient = false);
    }
  }

  // Called whenever the client search field gains/loses focus.
  void _onClientFocusChanged() {
    if (_clientSearchFocusNode.hasFocus && _clientSearchCtrl.text.isEmpty) {
      _loadInitialClients();
    } else if (!_clientSearchFocusNode.hasFocus && _clientSuggestions.isNotEmpty && _clientSearchCtrl.text.isEmpty) {
      // Clear suggestions when focus leaves with an empty field (no selection made).
      setState(() => _clientSuggestions = []);
    }
  }

  // Loads the first page of clients to populate the dropdown on focus/tap.
  void _loadInitialClients() {
    _clientSearchDebounce?.cancel();
    if (!mounted) return;
    setState(() => _isSearchingClients = true);
    _api.getClients(page: 1, perPage: 20, q: '').then((resp) {
      if (!mounted) return;
      setState(() {
        _clientSuggestions = resp.data;
        _isSearchingClients = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _isSearchingClients = false);
    });
  }

  void _searchClients(String query) {
    _clientSearchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _clientSuggestions = [];
        _isSearchingClients = false;
      });
      return;
    }
    _clientSearchDebounce =
        Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingClients = true);
      try {
        final resp =
            await _api.getClients(page: 1, perPage: 20, q: query.trim());
        if (!mounted) return;
        setState(() {
          _clientSuggestions = resp.data;
          _isSearchingClients = false;
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            _clientSuggestions = [];
            _isSearchingClients = false;
          });
        }
      }
    });
  }

  void _selectClient(Map<String, dynamic> client) {
    final id = _asInt(client['id']);
    final parts = [
      _asString(client['cfirstname']),
      _asString(client['cmiddlename']),
      _asString(client['csurname']),
    ].where((p) => p.isNotEmpty).toList();
    final name = parts.isNotEmpty
        ? parts.join(' ')
        : _asString(client['ccompanyname']);
    final phone = _asString(client['cphonenum']).isNotEmpty
        ? _asString(client['cphonenum'])
        : _asString(client['phone']);
    setState(() {
      _clientSearchCtrl.text = name;
      _contactCtrl.text = phone;
      _selectedClientId = id;
      _clientSuggestions = [];
    });
    if (id > 0) _loadShopsForClient(id);
  }

  Future<void> _onSave() async {
    if (_clientSearchCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client name is required.'),
          backgroundColor: Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (_selectedDate.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot schedule for a past date. Please select today or a future date.'),
          backgroundColor: Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final d = _selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    debugPrint('[AddSchedule] Submitting with date: $dateStr (raw _selectedDate: $_selectedDate)');

    int? shopId;
    for (final s in _shops) {
      if (s.shopname == _selectedShop) {
        shopId = s.id;
        break;
      }
    }

    int? serviceTypeId;
    for (final s in _serviceTypes) {
      if (_asString(s['setypename']) == _selectedServiceType) {
        serviceTypeId = _asInt(s['id']);
        break;
      }
    }

    final techIds = <int>[];
    for (final name in _techSlotValues) {
      if (name == null || name.isEmpty) continue;
      for (final e in _employees) {
        if (_asString(e['efullname']) == name) {
          final eid = _asInt(e['id']);
          if (eid > 0) techIds.add(eid);
          break;
        }
      }
    }

    const statusMap = {
      'Pending': 'pending',
      'Tentative': 'tentative',
      'Final': 'final',
      'Resolved': 'resolved',
    };

    final payload = <String, dynamic>{
      'client_name': _clientSearchCtrl.text.trim(),
      if (_selectedClientId != null) 'client_id': _selectedClientId,
      'phone': _contactCtrl.text.trim(),
      'location': _addressCtrl.text.trim(),
      'start': dateStr,
      'end': dateStr,
      'status': statusMap[_selectedStatus] ?? 'pending',
      if (serviceTypeId != null) 'service_type_id': serviceTypeId,
      if (shopId != null) 'shop_id': shopId,
      if (_selectedServiceType != null && _selectedServiceType!.isNotEmpty)
        'services': _selectedServiceType,
      if (_vehicleCtrl.text.trim().isNotEmpty)
        'vehicles': _vehicleCtrl.text.trim(),
      if (_tollCtrl.text.trim().isNotEmpty)
        'toll_amount': _tollCtrl.text.trim(),
      if (_gasCtrl.text.trim().isNotEmpty)
        'gas_amount': _gasCtrl.text.trim(),
      if (_locationLinkCtrl.text.trim().isNotEmpty)
        'location_link': _locationLinkCtrl.text.trim(),
      if (_pinLocationCtrl.text.trim().isNotEmpty)
        'pin_location': _pinLocationCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (techIds.isNotEmpty) 'technician_ids': techIds,
      if (!_useDefault) 'event_mark': 'asterisk',
    };

    setState(() => _isSaving = true);
    try {
      await _api.createEvent(payload);
      if (!mounted) return;
      widget.onCreated?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule saved successfully.'),
          backgroundColor: Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final msg = e is ApiException
          ? (e.fieldErrors.isNotEmpty
              ? e.fieldErrors.values.join('\n')
              : e.message)
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Failed to save schedule.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 560 ? screenWidth * 0.94 : 540.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screenWidth - dialogWidth) / 2,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_isLoadingDeps)
            const LinearProgressIndicator(
              color: Color(0xFF87CEEB),
              backgroundColor: Color(0xFFE0F7FA),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: _buildFormBody(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Add Schedule',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: Colors.black54),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Form Body ──────────────────────────────────────────────────────────────

  Widget _buildFormBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1 – Client Name | Contact No.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFieldColumn(
                label: 'Client Name',
                child: _buildClientSearchField(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFieldColumn(
                label: 'Contact No.',
                child: _buildInput(
                  controller: _contactCtrl,
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Radio – Default / Asterisk
        Row(
          children: [
            _buildRadioOption('Default', _useDefault, () {
              setState(() => _useDefault = true);
            }),
            const SizedBox(width: 16),
            _buildRadioOption('* Asterisk', !_useDefault, () {
              setState(() => _useDefault = false);
            }),
          ],
        ),
        const SizedBox(height: 10),

        // Type Client Name button — focuses the client search field
        OutlinedButton(
          onPressed: () =>
              FocusScope.of(context).requestFocus(_clientSearchFocusNode),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2563EB)),
            foregroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Type Client Name...',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),

        // Schedule Date
        _buildFieldColumn(
          label: 'Schedule Date',
          child: _buildDatePicker(),
        ),
        const SizedBox(height: 12),

        // Shop
        _buildFieldColumn(
          label: 'Shop',
          child: _isLoadingShopsForClient
              ? _buildLoadingField()
              : _buildDropdown(
                  hint: 'Select Shop',
                  value: _selectedShop,
                  items: _shops.map((s) => s.shopname).toList(),
                  onChanged: (v) {
                    setState(() => _selectedShop = v);
                    if (v != null && _shops.isNotEmpty) {
                      final shop = _shops.firstWhere(
                        (s) => s.shopname == v,
                        orElse: () => _shops.first,
                      );
                      _addressCtrl.text = shop.saddress;
                      _pinLocationCtrl.text = shop.pinLocation;
                      _locationLinkCtrl.text = shop.locationLink;
                    }
                  },
                ),
        ),
        const SizedBox(height: 12),

        // Address Location
        _buildFieldColumn(
          label: 'Address Location',
          child: _buildInput(
            controller: _addressCtrl,
            hint: 'Enter Address',
          ),
        ),
        const SizedBox(height: 12),

        // Row – Pin Location | Location Link
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFieldColumn(
                label: 'Pin Location',
                labelSuffix: _buildHelpIcon(),
                child: _buildInput(
                  controller: _pinLocationCtrl,
                  hint: 'Enter Pin Location',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFieldColumn(
                label: 'Location Link',
                labelSuffix: const Icon(
                  Icons.link,
                  size: 15,
                  color: Color(0xFF2563EB),
                ),
                child: _buildInput(
                  controller: _locationLinkCtrl,
                  hint: '',
                  keyboardType: TextInputType.url,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row – Type Of Service | Vehicle/s
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFieldColumn(
                label: 'Type Of Service',
                child: _buildDropdown(
                  hint: '',
                  value: _selectedServiceType,
                  items: _serviceTypes
                      .map((s) => _asString(s['setypename']))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedServiceType = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFieldColumn(
                label: 'Vehicle/s',
                child: _buildInput(
                  controller: _vehicleCtrl,
                  hint: 'Enter Vehicle name',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row – Toll Amount | Gas Amount | Status
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFieldColumn(
                label: 'Toll Amount',
                child: _buildInput(
                  controller: _tollCtrl,
                  hint: 'Enter Toll amount',
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFieldColumn(
                label: 'Gas Amount',
                child: _buildInput(
                  controller: _gasCtrl,
                  hint: 'Enter Gas amount',
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFieldColumn(
                label: 'Status',
                child: _buildDropdown(
                  hint: 'Select Status',
                  value: _selectedStatus,
                  items: _kStatuses,
                  onChanged: (v) =>
                      setState(() => _selectedStatus = v ?? 'Pending'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Technician row (up to 5 dropdowns)
        _buildFieldColumn(
          label: 'Technician',
          labelSuffix: _buildHelpIcon(),
          child: _buildTechnicianRow(),
        ),
        const SizedBox(height: 12),

        // Notes
        _buildFieldColumn(
          label: 'Notes',
          child: _buildTextArea(
            controller: _notesCtrl,
            hint: 'Enter Notes/Comments',
          ),
        ),
        const SizedBox(height: 20),

        // Save button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Save Schedule',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Shared sub-builders ────────────────────────────────────────────────────

  Widget _buildClientSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _clientSearchCtrl,
          focusNode: _clientSearchFocusNode,
          onTap: () {
            if (_clientSearchCtrl.text.isEmpty) _loadInitialClients();
          },
          onChanged: (v) {
            _selectedClientId = null;
            if (v.isEmpty) {
              _loadInitialClients();
            } else {
              _searchClients(v);
            }
          },
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Search client name...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: _isSearchingClients
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2563EB)),
                    ),
                  )
                : _clientSearchCtrl.text.isEmpty
                    ? Icon(Icons.arrow_drop_down, size: 22, color: Colors.grey[500])
                    : Icon(Icons.search, size: 18, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            isDense: true,
          ),
        ),
        if (_clientSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _clientSuggestions.length,
              itemBuilder: (ctx, i) {
                final client = _clientSuggestions[i];
                final parts = [
                  _asString(client['cfirstname']),
                  _asString(client['cmiddlename']),
                  _asString(client['csurname']),
                ].where((p) => p.isNotEmpty).toList();
                final name = parts.isNotEmpty
                    ? parts.join(' ')
                    : _asString(client['ccompanyname']);
                return InkWell(
                  onTap: () => _selectClient(client),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 8),
          Text('Loading...',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildFieldColumn({
    required String label,
    required Widget child,
    Widget? labelSuffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (labelSuffix != null) ...[
              const SizedBox(width: 4),
              labelSuffix,
            ],
          ],
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildDatePicker() {
    final d = _selectedDate;
    final display = '${d.month}/${d.day}/${d.year}';
    return InkWell(
      onTap: () async {
        final today = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final picked = await showDatePicker(
          context: context,
          initialDate:
              _selectedDate.isBefore(today) ? today : _selectedDate,
          firstDate: today,
          lastDate: DateTime(2030),
        );
        if (picked != null && mounted) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                display,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      hint: Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        isDense: true,
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildRadioOption(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF2563EB) : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpIcon() {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[400],
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianRow() {
    final techNames = _employees
        .map((e) => _asString(e['efullname']))
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    return Row(
      children: List.generate(5, (idx) {
        final currentValue = _techSlotValues[idx] != null &&
                techNames.contains(_techSlotValues[idx])
            ? _techSlotValues[idx]
            : null;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < 4 ? 6 : 0),
            child: DropdownButtonFormField<String>(
              value: currentValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: Colors.black54),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              hint: Text(
                idx == 0 ? 'Select Technic…' : '',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                overflow: TextOverflow.ellipsis,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                isDense: true,
              ),
              items: techNames
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _techSlotValues[idx] = v),
            ),
          ),
        );
      }),
    );
  }

  static String _asString(dynamic v) => (v ?? '').toString().trim();
  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse((v ?? '').toString()) ?? 0;
  }
}