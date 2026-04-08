import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule_event.dart';
import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/paginated_response.dart';
import '../../../shared/models/shop.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../service_type/models/service_type_model.dart';

class DayClientsScreen extends StatefulWidget {
  final DateTime date;
  final List<ScheduleEvent> clients;

  /// Called after the user saves in the edit modal.
  /// [original] – unmodified client, [updated] – new client, [toDate] – new date.
  final void Function(
    ScheduleEvent original,
    ScheduleEvent updated,
    DateTime toDate,
  )? onReschedule;

  /// Called when the user taps a client card to drag-reschedule it on the
  /// Calendar screen.  Receives the selected client and the current date.
  final void Function(ScheduleEvent client, DateTime fromDate)?
      onClientSelectForDrag;

  const DayClientsScreen({
    Key? key,
    required this.date,
    required this.clients,
    this.onReschedule,
    this.onClientSelectForDrag,
  }) : super(key: key);

  @override
  State<DayClientsScreen> createState() => _DayClientsScreenState();
}

class _DayClientsScreenState extends State<DayClientsScreen> {
  late List<ScheduleEvent> _clients;

  @override
  void initState() {
    super.initState();
    // Shallow copy so local mutations don't affect the caller's list directly.
    _clients = List.from(widget.clients);
  }

  // ─── Permission helper ────────────────────────────────────────────────────

  /// Returns true if the current user may edit/move [client].
  /// Super Admins can edit all schedules; others only their own.
  bool _canEdit(ScheduleEvent client) {
    if (SessionFlags.userRole == 'Super Admin') return true;
    final me = SessionFlags.loggedInUser;
    if (me == null) return false;
    final cb = client.createdBy.trim();
    if (cb.isEmpty) return false;
    return cb == me.id.toString();
  }

  // ─── Edit modal ─────────────────────────────────────────────────────────────

  void _showEditModal(BuildContext screenContext, int index) {
    final originalClient = _clients[index];
    showDialog(
      context: screenContext,
      barrierDismissible: true,
      builder: (dialogCtx) => _EditScheduleDialog(
        client: originalClient,
        currentDate: widget.date,
        onSave: (updatedClient, toDate) {
          final isDateChanged = toDate.day != widget.date.day ||
              toDate.month != widget.date.month ||
              toDate.year != widget.date.year;
          setState(() {
            if (isDateChanged) {
              _clients.removeAt(index);
            } else {
              _clients[index] = updatedClient;
            }
          });
          widget.onReschedule?.call(originalClient, updatedClient, toDate);
          Navigator.pop(dialogCtx);
        },
        onDelete: () {
          setState(() => _clients.removeAt(index));
          Navigator.pop(dialogCtx);
        },
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(widget.date);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(
        title: 'Day Schedule',
        showMenuButton: false,
      ),
      body: Column(
        children: [
          // Date header banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _clients.isEmpty
                            ? 'No clients scheduled'
                            : '${_clients.length} client(s) scheduled',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Client list
          Expanded(
            child: _clients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 72, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No clients scheduled for this day',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select another day from the calendar.',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _clients.length,
                    itemBuilder: (context, index) =>
                        _buildClientCard(context, index),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Client card ─────────────────────────────────────────────────────────────

  Widget _buildClientCard(BuildContext context, int index) {
    final client = _clients[index];
    final label = _labelForType(client.type);
    final number = index + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color accent bar
              Container(width: 4, color: client.color),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: client.color.withOpacity(0.12),
                            radius: 22,
                            child: Text(
                              '$number',
                              style: TextStyle(
                                color: client.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: client.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: client.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: client.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Move button — triggers drag-reschedule on Calendar
                          GestureDetector(
                            onTap: () {
                              if (!_canEdit(client)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'You can only move schedules you created.'),
                                    backgroundColor: Color(0xFFEF5350),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              widget.onClientSelectForDrag
                                  ?.call(client, widget.date);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _canEdit(client)
                                    ? Colors.grey[50]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              child: Icon(
                                Icons.open_with,
                                size: 16,
                                color: _canEdit(client)
                                    ? Colors.grey[500]
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit icon — opens the status/date edit modal
                          GestureDetector(
                            onTap: () {
                              if (!_canEdit(client)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'You can only edit schedules you created.'),
                                    backgroundColor: Color(0xFFEF5350),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              _showEditModal(context, index);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _canEdit(client)
                                    ? Colors.grey[50]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: _canEdit(client)
                                    ? Colors.grey[500]
                                    : Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _labelForType(ScheduleType type) {
    switch (type) {
      case ScheduleType.pending:
        return 'PENDING';
      case ScheduleType.tentative:
        return 'TENTATIVE';
      case ScheduleType.final_:
        return 'FINAL';
      case ScheduleType.resolved:
        return 'RESOLVED';
      case ScheduleType.name:
        return 'NAME';
    }
  }
}

// ─── Edit Schedule Dialog ────────────────────────────────────────────────────

class _EditScheduleDialog extends StatefulWidget {
  final ScheduleEvent client;
  final DateTime currentDate;
  final void Function(ScheduleEvent updated, DateTime toDate) onSave;
  final VoidCallback onDelete;

  const _EditScheduleDialog({
    required this.client,
    required this.currentDate,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<_EditScheduleDialog> {
  // ── Dynamic options (loaded from API) ─────────────────────────────────────
  List<String> _shopNames = [];
  List<String> _serviceTypeNames = [];
  List<String> _technicianOptions = ['N/A'];
  final Map<String, int> _shopIdByName = {};
  final Map<String, int> _serviceTypeIdByName = {};
  final Map<String, int> _techIdByName = {};
  bool _isLoadingDeps = false;
  bool _isSaving = false;

  final BackendApi _api = BackendApi();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _vehiclesCtrl;
  late final TextEditingController _tollCtrl;
  late final TextEditingController _gasCtrl;
  late final TextEditingController _notesCtrl;

  late ScheduleType _status;
  late NameType _nameType;
  late String _shop;
  late String _serviceType;
  late List<String> _technicians;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameCtrl = TextEditingController(text: c.name);
    _contactCtrl = TextEditingController(text: c.contactNo);
    _addressCtrl = TextEditingController(text: c.addressLocation);
    _pinCtrl = TextEditingController(text: c.pinLocation);
    _linkCtrl = TextEditingController(text: c.locationLink);
    _vehiclesCtrl = TextEditingController(text: c.vehicles);
    _tollCtrl = TextEditingController(text: c.tollAmount);
    _gasCtrl = TextEditingController(text: c.gasAmount);
    _notesCtrl = TextEditingController(text: c.notes);
    _status = c.type;
    _nameType = c.nameType;
    _shop = c.shop;
    _serviceType = c.serviceType;
    // Preserve original technician names (padded to 5 slots with 'N/A').
    // They will be re-resolved against loaded options in _loadDeps().
    final rawTechs = List<String>.from(c.technicians);
    _technicians = List.generate(
        5, (i) => i < rawTechs.length ? rawTechs[i].trim() : 'N/A');
    _selectedDate = widget.currentDate;
    _loadDeps();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _addressCtrl.dispose();
    _pinCtrl.dispose();
    _linkCtrl.dispose();
    _vehiclesCtrl.dispose();
    _tollCtrl.dispose();
    _gasCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeps() async {
    setState(() => _isLoadingDeps = true);
    try {
      // Await each call separately with correct types to avoid _CastError
      final shopResp = await _api
          .getShops(page: 1, perPage: 100)
          .catchError((_) => PaginatedResponse<Shop>(
              data: const [],
              currentPage: 1,
              perPage: 100,
              total: 0,
              lastPage: 1,
              links: const []));
      final stResp = await _api
          .getServiceTypes(page: 1, perPage: 100)
          .catchError((_) => PaginatedResponse<ServiceTypeModel>(
              data: const [],
              currentPage: 1,
              perPage: 100,
              total: 0,
              lastPage: 1,
              links: const []));
      final empResp = await _api
          .getCalendarEmployees(page: 1, perPage: 100)
          .catchError((_) => PaginatedResponse<Map<String, dynamic>>(
              data: const [],
              currentPage: 1,
              perPage: 100,
              total: 0,
              lastPage: 1,
              links: const []));
      if (!mounted) return;

      final shops = shopResp.data;
      final serviceTypes = stResp.data
          .map((s) => <String, dynamic>{'id': s.id, 'setypename': s.setypename})
          .toList();
      final employees = empResp.data;

      final shopNames = shops.map((s) => s.shopname).toList();
      final shopIdByName = <String, int>{
        for (final s in shops) s.shopname: s.id,
      };
      final stNames = serviceTypes
          .map((s) => (s['setypename'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      final stIdByName = <String, int>{
        for (final s in serviceTypes)
          (s['setypename'] ?? '').toString().trim():
              (s['id'] is int ? s['id'] as int : int.tryParse((s['id'] ?? '').toString()) ?? 0),
      };
      final techNames = [
        'N/A',
        ...employees
            .map((e) => (e['efullname'] ?? '').toString().trim())
            .where((n) => n.isNotEmpty),
      ];
      final techIdByName = <String, int>{
        for (final e in employees)
          (e['efullname'] ?? '').toString().trim():
              (e['id'] is int ? e['id'] as int : int.tryParse((e['id'] ?? '').toString()) ?? 0),
      };

      setState(() {
        _shopNames = shopNames;
        _serviceTypeNames = stNames;
        _technicianOptions = techNames;
        _shopIdByName
          ..clear()
          ..addAll(shopIdByName);
        _serviceTypeIdByName
          ..clear()
          ..addAll(stIdByName);
        _techIdByName
          ..clear()
          ..addAll(techIdByName);

        // Re-resolve _shop by shopId if current value not found
        if (!_shopNames.contains(_shop)) {
          final match = shops
              .where((s) => s.id == widget.client.shopId)
              .map((s) => s.shopname)
              .firstOrNull;
          if (match != null) _shop = match;
        }
        // Re-resolve _serviceType by serviceTypeId if current value not found
        if (!_serviceTypeNames.contains(_serviceType)) {
          final match = serviceTypes
              .where((s) =>
                  (s['id'] is int ? s['id'] as int : int.tryParse((s['id'] ?? '').toString()) ?? 0) ==
                  widget.client.serviceTypeId)
              .map((s) => (s['setypename'] ?? '').toString().trim())
              .firstOrNull;
          if (match != null) _serviceType = match;
        }

        // Re-resolve technicians: keep names that exist in loaded options,
        // fallback to 'N/A' for any that are missing.
        for (int i = 0; i < _technicians.length; i++) {
          if (!techNames.contains(_technicians[i])) {
            _technicians[i] = 'N/A';
          }
        }

        _isLoadingDeps = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDeps = false);
    }
  }

  String _statusLabel(ScheduleType t) {
    switch (t) {
      case ScheduleType.pending:
        return 'PENDING';
      case ScheduleType.tentative:
        return 'TENTATIVE';
      case ScheduleType.final_:
        return 'FINAL';
      case ScheduleType.resolved:
        return 'RESOLVED';
      case ScheduleType.name:
        return 'NAME';
    }
  }

  String _statusBadgeLabel(ScheduleType t) {
    switch (t) {
      case ScheduleType.pending:
        return 'Pending';
      case ScheduleType.tentative:
        return 'Tentative';
      case ScheduleType.final_:
        return 'Final';
      case ScheduleType.resolved:
        return 'Resolved Concern';
      case ScheduleType.name:
        return 'Name';
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        borderSide:
            const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = ScheduleEvent.colorForType(_status);
    final createdBy = widget.client.createdBy.isEmpty
        ? 'Event created by User'
        : widget.client.createdBy;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF4FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Edit Schedule',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusBadgeLabel(_status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey[500], size: 22),
                ),
              ],
            ),
          ),

          // ── Scrollable content ───────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Name | Contact No.
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: _fieldDecoration('Client Name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _contactCtrl,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration('Contact No.'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Default | *Asterisk radio
                  Row(
                    children: [
                      Radio<NameType>(
                        value: NameType.default_,
                        groupValue: _nameType,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (v) =>
                            setState(() => _nameType = v!),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('Default',
                          style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 16),
                      Radio<NameType>(
                        value: NameType.asterisk,
                        groupValue: _nameType,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (v) =>
                            setState(() => _nameType = v!),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const Text('* Asterisk',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Shop (read-only)
                  _buildLabel('Shop'),
                  const SizedBox(height: 6),
                  _buildReadOnlyField(_shop),
                  const SizedBox(height: 12),

                  // Address Location
                  TextField(
                    controller: _addressCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration('Address Location'),
                  ),
                  const SizedBox(height: 12),

                  // Pin Location | Location Link
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pinCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: _fieldDecoration('Pin Location'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _linkCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: _fieldDecoration('Location Link'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Type Of Service | Vehicle/s
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Type Of Service'),
                            const SizedBox(height: 6),
                            _buildReadOnlyField(_serviceType),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _vehiclesCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: _fieldDecoration('Vehicle/s'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Toll Amount | Gas Amount | Status
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tollCtrl,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('Toll Amount'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _gasCtrl,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('Gas Amount'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Status'),
                            const SizedBox(height: 6),
                            _buildDropdown<ScheduleType>(
                              value: _status,
                              items: [
                                ScheduleType.pending,
                                ScheduleType.tentative,
                                ScheduleType.final_,
                                ScheduleType.resolved,
                              ],
                              onChanged: (v) =>
                                  setState(() => _status = v!),
                              labelFn: _statusLabel,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Technician (read-only)
                  _buildLabel('Technician'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(5, (i) {
                      return SizedBox(
                        width: (MediaQuery.of(context).size.width -
                                    56 -
                                    32) /
                                2.5,
                        child: _buildReadOnlyField(_technicians[i]),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: _notesCtrl,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    decoration: _fieldDecoration('Notes'),
                  ),
                  const SizedBox(height: 12),

                  // Created by footer
                  Text(
                    createdBy,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Footer buttons ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (widget.client.id <= 0) {
                            widget.onDelete();
                            return;
                          }
                          setState(() => _isSaving = true);
                          try {
                            await _api.deleteEvent(widget.client.id);
                            if (!mounted) return;
                            widget.onDelete();
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _isSaving = false);
                            final msg = e is ApiException &&
                                    e.statusCode == 403
                                ? 'You do not have permission to delete this schedule.'
                                : 'Failed to delete schedule.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                // Copy
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Schedule copied'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF374151),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('Copy',
                      style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                // Save Schedule
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final d = _selectedDate;
                          final dateStr =
                              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

                          final techIds = <int>[];
                          for (final name in _technicians) {
                            if (name.isEmpty) continue;
                            final id = _techIdByName[name];
                            if (id != null && id > 0) techIds.add(id);
                          }

                          final payload = <String, dynamic>{
                            'client_name': _nameCtrl.text.trim(),
                            'phone': _contactCtrl.text.trim(),
                            'location': _addressCtrl.text.trim(),
                            'start': dateStr,
                            'end': dateStr,
                            'status': ScheduleEvent.typeToString(_status),
                            if (_shopIdByName[_shop] != null)
                              'shop_id': _shopIdByName[_shop],
                            if (_serviceTypeIdByName[_serviceType] != null)
                              'service_type_id':
                                  _serviceTypeIdByName[_serviceType],
                            'services': _serviceType,
                            if (_vehiclesCtrl.text.trim().isNotEmpty)
                              'vehicles': _vehiclesCtrl.text.trim(),
                            if (_tollCtrl.text.trim().isNotEmpty)
                              'toll_amount': _tollCtrl.text.trim(),
                            if (_gasCtrl.text.trim().isNotEmpty)
                              'gas_amount': _gasCtrl.text.trim(),
                            if (_pinCtrl.text.trim().isNotEmpty)
                              'pin_location': _pinCtrl.text.trim(),
                            if (_linkCtrl.text.trim().isNotEmpty)
                              'location_link': _linkCtrl.text.trim(),
                            if (_notesCtrl.text.trim().isNotEmpty)
                              'notes': _notesCtrl.text.trim(),
                            'technician_ids': techIds,
                          };

                          setState(() => _isSaving = true);
                          try {
                            if (widget.client.id > 0) {
                              await _api.updateEvent(
                                  id: widget.client.id, payload: payload);
                            }
                            if (!mounted) return;
                            final updatedClient = widget.client.copyWith(
                              name: _nameCtrl.text.trim(),
                              type: _status,
                              contactNo: _contactCtrl.text.trim(),
                              nameType: _nameType,
                              shop: _shop,
                              addressLocation: _addressCtrl.text.trim(),
                              pinLocation: _pinCtrl.text.trim(),
                              locationLink: _linkCtrl.text.trim(),
                              serviceType: _serviceType,
                              vehicles: _vehiclesCtrl.text.trim(),
                              tollAmount: _tollCtrl.text.trim(),
                              gasAmount: _gasCtrl.text.trim(),
                              technicians: List.from(_technicians),
                              notes: _notesCtrl.text.trim(),
                            );
                            widget.onSave(updatedClient, _selectedDate);
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _isSaving = false);
                            final msg = e is ApiException &&
                                    e.statusCode == 403
                                ? 'You do not have permission to edit this schedule.'
                                : 'Failed to save schedule.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Schedule',
                          style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) labelFn,
  }) {
    // Deduplicate items to prevent DropdownButton assertion error
    final uniqueItems = items.toSet().toList();
    final safeValue = uniqueItems.contains(value)
        ? value
        : (uniqueItems.isNotEmpty ? uniqueItems.first : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: uniqueItems
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(labelFn(e),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}