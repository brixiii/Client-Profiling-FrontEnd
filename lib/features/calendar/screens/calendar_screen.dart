import 'package:flutter/material.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/session_flags.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';
import '../models/schedule_event.dart';
import 'add_schedule_dialog.dart';
import 'day_clients_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final TextEditingController _nameController = TextEditingController();
  String _nameFilter = '';
  ScheduleType? _statusFilter;
  DateTime? _filterDate;
  DateTime? _selectedDay;
  bool _previewVisible = false;
  // Increments on each month change to trigger AnimatedSwitcher
  int _gridKey = 0;

  // Drag-to-reschedule state
  ScheduleEvent? _pendingDragClient;
  int? _pendingDragFromDay;

  late AnimationController _previewController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Backend
  final BackendApi _api = BackendApi();
  bool _isLoading = false;
  String? _loadError;

  // Events from backend (keyed by day-of-month)
  final Map<int, List<ScheduleEvent>> events = {
  };

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = CurvedAnimation(
      parent: _previewController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _previewController,
      curve: Curves.easeOut,
    );
    // Show drag-icon guide only on first visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShowDragGuide();
    });
    _loadEvents();
  }

  @override
  void dispose() {
    _previewController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _maybeShowDragGuide() {
    if (SessionFlags.calendarDragGuideShown || !mounted) return;
    SessionFlags.calendarDragGuideShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => const _DragGuideDialog(),
    );
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;

    final days = <DateTime>[];

    // Add empty days for the start of the week
    final firstWeekday =
        firstDay.weekday % 7; // Convert to 0=Sunday, 6=Saturday
    for (int i = 0; i < firstWeekday; i++) {
      days.add(firstDay.subtract(Duration(days: firstWeekday - i)));
    }

    // Add all days in the month
    for (int i = 0; i < daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }

    return days;
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final rawList = await _api.getEvents(
        month: _currentMonth.month,
        year: _currentMonth.year,
      );
      if (!mounted) return;
      final newEvents = <int, List<ScheduleEvent>>{};
      for (final raw in rawList) {
        final event = ScheduleEvent.fromJson(raw);
        final startStr = (raw['start'] ?? '').toString();
        if (startStr.isEmpty) continue;
        final dt = DateTime.tryParse(startStr);
        if (dt == null) continue;
        newEvents.putIfAbsent(dt.day, () => []).add(event);
      }
      setState(() {
        events
          ..clear()
          ..addAll(newEvents);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load schedule.';
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _gridKey++;
      events.clear();
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _gridKey++;
      events.clear();
    });
    _loadEvents();
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      events.clear();
    });
    _loadEvents();
  }

  void _onDayTapped(DateTime day) {
    if (day.month != _currentMonth.month) return;
    setState(() {
      _selectedDay = day;
      _previewVisible = true;
    });
    _previewController.forward(from: 0);
  }

  void _dismissPreview() {
    _previewController.reverse().then((_) {
      if (mounted) setState(() => _previewVisible = false);
    });
  }

  // ── Drag-to-reschedule helpers ──────────────────────────────────────────────

  /// Selects [client] as the active draggable and dismisses any open preview.
  void _selectClientForDrag(ScheduleEvent client, int fromDay) {
    if (client.type == ScheduleType.resolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resolved schedules cannot be moved.'),
          backgroundColor: Color(0xFF27AE60),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _previewController.stop();
    setState(() {
      _previewVisible = false;
      _pendingDragClient = client;
      _pendingDragFromDay = fromDay;
    });
  }

  void _cancelDrag() {
    setState(() {
      _pendingDragClient = null;
      _pendingDragFromDay = null;
    });
  }

  /// Moves [client] from [fromDay] to [targetDay] in the events map.
  void _dropClientOnDay(ScheduleEvent client, DateTime targetDay, int fromDay) {
    if (targetDay.month != _currentMonth.month) return;
    setState(() {
      events[fromDay]?.removeWhere((e) => e.id == client.id);
      if (events[fromDay]?.isEmpty ?? false) {
        events.remove(fromDay);
      }
      events.putIfAbsent(targetDay.day, () => []).add(client);
      _pendingDragClient = null;
      _pendingDragFromDay = null;
    });
    // Persist to backend (optimistic – local state already updated)
    if (client.id > 0) {
      final d = targetDay;
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      _api
          .updateEvent(id: client.id, payload: {'start': dateStr, 'end': dateStr})
          .catchError((_) {});
    }
  }

  void _navigateToDayClients() {
    if (_selectedDay == null) return;
    final sel = _selectedDay!;
    final dayEvents = events[sel.day] ?? [];
    _dismissPreview();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => DayClientsScreen(
          date: sel,
          clients: dayEvents,
          onReschedule: (original, updated, toDate) {
            setState(() {
              // Remove from original day
              events[sel.day]?.remove(original);
              // Add to target day (keyed by day-of-month)
              events.putIfAbsent(toDate.day, () => []).add(updated);
            });
          },
          onClientSelectForDrag: (client, fromDate) {
            _selectClientForDrag(client, fromDate.day);
          },
        ),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_currentMonth);
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;
    final isMobile = screenWidth < 600;
    final horizontalMargin = isMobile ? 12.0 : 16.0;
    final sectionPadding = isMobile ? 14.0 : 20.0;
    final dayCellHeight = isNarrow ? 86.0 : (isMobile ? 98.0 : 120.0);
    final childAspectRatio =
        ((screenWidth - (horizontalMargin * 2)) / 7) / dayCellHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Calendar',
        showMenuButton: true,
        actions: [],
      ),
      drawer: const AppDrawer(currentPage: 'Calendar'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: _pendingDragClient != null ? 120 : 0,
            ),
            child: Column(
              children: [
                SizedBox(height: isMobile ? 12 : 20),

                // Legend
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                  padding: EdgeInsets.all(sectionPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF87CEEB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Color(0xFF87CEEB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Schedule Legend',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: isMobile ? 6 : 10,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem('PENDING', const Color(0xFF5B9BD5), type: ScheduleType.pending),
                          _buildLegendItem('TENTATIVE', const Color(0xFFFFA500), type: ScheduleType.tentative),
                          _buildLegendItem('FINAL', const Color(0xFFE74C3C), type: ScheduleType.final_),
                          _buildLegendItem('RESOLVED', const Color(0xFF27AE60), type: ScheduleType.resolved),
                          _buildLegendItem('*NAME', const Color(0xFF9E9E9E), type: ScheduleType.name),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 20),

                // Search and Controls
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildNameSearchField()),
                                const SizedBox(width: 8),
                                _buildDatePickerIcon(),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildGoButton(compact: true)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _buildClearButton(compact: true)),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildNameSearchField()),
                            const SizedBox(width: 8),
                            _buildDatePickerIcon(),
                            const SizedBox(width: 10),
                            _buildGoButton(),
                            const SizedBox(width: 8),
                            _buildClearButton(),
                          ],
                        ),
                ),
                SizedBox(height: isMobile ? 12 : 20),

                // Calendar Container
                Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Calendar Header
                      Container(
                        padding: EdgeInsets.all(sectionPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF87CEEB).withOpacity(0.1),
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: isMobile
                            ? Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF87CEEB)
                                          .withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month,
                                      color: Color(0xFF87CEEB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      monthName,
                                      style: TextStyle(
                                        fontSize: isNarrow ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  _buildMonthNavButtons(),
                                ],
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF87CEEB)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month,
                                          color: Color(0xFF87CEEB),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        monthName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildMonthNavButtons(),
                                ],
                              ),
                      ),

                      // Days of week header
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children:
                              ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                                  .map((day) => Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isMobile ? 10 : 12,
                                          ),
                                          child: Text(
                                            day,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isNarrow ? 11 : 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                        ),
                      ),

                      // Loading / error banner
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: LinearProgressIndicator(
                            color: Color(0xFF87CEEB),
                            backgroundColor: Color(0xFFE0F7FA),
                          ),
                        ),
                      if (_loadError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFFB91C1C)),
                          ),
                        ),

                      // Calendar grid — AnimatedSwitcher fades on month change
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: CurvedAnimation(
                              parent: anim, curve: Curves.easeOut),
                          child: child,
                        ),
                        child: GridView.builder(
                          key: ValueKey(_gridKey),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: days.length,
                          itemBuilder: (context, index) {
                            final day = days[index];
                            final isCurrentMonth =
                                day.month == _currentMonth.month;
                            final isToday = day.year == DateTime.now().year &&
                                day.month == DateTime.now().month &&
                                day.day == DateTime.now().day;
                            // Apply name filter — show only matching events
                            final allDayEvents =
                                isCurrentMonth ? events[day.day] ?? [] : [];
                            final dayEvents = allDayEvents.where((e) {
                              final matchesName = _nameFilter.isEmpty ||
                                  e.name.toLowerCase().contains(_nameFilter.toLowerCase());
                              final matchesStatus =
                                  _statusFilter == null || e.type == _statusFilter;
                              return matchesName && matchesStatus;
                            }).toList();

                            final isSelected = _selectedDay != null &&
                                _selectedDay!.day == day.day &&
                                _selectedDay!.month == day.month &&
                                _selectedDay!.year == day.year;
                            final _todayNorm = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                            final isPastDate = isCurrentMonth && DateTime(day.year, day.month, day.day).isBefore(_todayNorm);
                            return DragTarget<_CalendarDragData>(
                              onWillAccept: (data) => isCurrentMonth,
                              onAccept: (data) {
                                if (isPastDate) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cannot move a schedule to a past date.'),
                                      backgroundColor: Color(0xFFEF5350),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  _dropClientOnDay(data.event, day, data.fromDay);
                                }
                              },
                              builder: (ctx, candidateData, rejectedData) {
                                final hasCandidate = candidateData.isNotEmpty && isCurrentMonth;
                                final isValidDropTarget = hasCandidate && !isPastDate;
                                final isInvalidDropTarget = hasCandidate && isPastDate;
                                return GestureDetector(
                                  onTap: () => _onDayTapped(day),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeInOut,
                                    decoration: BoxDecoration(
                                      color: isValidDropTarget
                                          ? const Color(0xFF2563EB)
                                              .withOpacity(0.18)
                                          : isInvalidDropTarget
                                              ? const Color(0xFFEF5350)
                                                  .withOpacity(0.15)
                                              : isSelected
                                                  ? const Color(0xFF2563EB)
                                                      .withOpacity(0.06)
                                                  : isToday
                                                      ? const Color(0xFF87CEEB)
                                                          .withOpacity(0.05)
                                                      : Colors.transparent,
                                      border: Border(
                                        right: BorderSide(
                                          color: isValidDropTarget
                                              ? const Color(0xFF2563EB)
                                                  .withOpacity(0.35)
                                              : isInvalidDropTarget
                                                  ? const Color(0xFFEF5350)
                                                      .withOpacity(0.35)
                                                  : Colors.grey[100]!,
                                          width: 0.5,
                                        ),
                                        bottom: BorderSide(
                                          color: isValidDropTarget
                                              ? const Color(0xFF2563EB)
                                                  .withOpacity(0.35)
                                              : isInvalidDropTarget
                                                  ? const Color(0xFFEF5350)
                                                      .withOpacity(0.35)
                                                  : Colors.grey[100]!,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsets.all(isNarrow ? 4 : 6),
                                          child: Container(
                                            width: isToday
                                                ? (isNarrow ? 24 : 28)
                                                : null,
                                            height: isToday
                                                ? (isNarrow ? 24 : 28)
                                                : null,
                                            decoration: isToday
                                                ? BoxDecoration(
                                                    color:
                                                        const Color(0xFF2563EB),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFF2563EB)
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  )
                                                : null,
                                            alignment: Alignment.center,
                                            child: Text(
                                              isCurrentMonth
                                                  ? day.day.toString()
                                                  : '',
                                              style: TextStyle(
                                                fontSize: isNarrow ? 10 : 12,
                                                fontWeight: isToday
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: isToday
                                                    ? Colors.white
                                                    : isCurrentMonth
                                                        ? Colors.black87
                                                        : Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isNarrow ? 2 : 3,
                                            ),
                                            child: Column(
                                              children: dayEvents
                                                  .map((event) {
                                                final _card = Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 3),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 4,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: event.color,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: event.color
                                                            .withOpacity(0.3),
                                                        blurRadius: 2,
                                                        offset:
                                                            const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 4,
                                                        height: 4,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.8),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Expanded(
                                                        child: Text(
                                                          event.displayName,
                                                          style: TextStyle(
                                                            fontSize: isNarrow
                                                                ? 6.5
                                                                : 7,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            height: 1.2,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (event.type == ScheduleType.resolved) {
                                                  return _card;
                                                }
                                                return LongPressDraggable<_CalendarDragData>(
                                                  data: _CalendarDragData(
                                                    event: event,
                                                    fromDay: day.day,
                                                  ),
                                                  delay: const Duration(milliseconds: 200),
                                                  feedback: Material(
                                                    color: Colors.transparent,
                                                    elevation: 6,
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      constraints: const BoxConstraints(maxWidth: 120),
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: event.color,
                                                        borderRadius: BorderRadius.circular(6),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: event.color.withOpacity(0.5),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        event.displayName,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  childWhenDragging: Opacity(
                                                    opacity: 0.3,
                                                    child: _card,
                                                  ),
                                                  child: _card,
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      if (_statusFilter != null &&
                          !events.values.any(
                              (list) => list.any((e) => e.type == _statusFilter)))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 28, horizontal: 16),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No ${_scheduleTypeLabel(_statusFilter!)} schedules found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap the filter again to show all schedules',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 20),
              ],
            ),
          ),
          if (_previewVisible) ..._buildOverlay(),
          if (_pendingDragClient != null) _buildDragPanel(),
        ],
      ),
    );
  }

  List<Widget> _buildOverlay() {
    return [
      GestureDetector(
        onTap: _dismissPreview,
        child: Container(color: Colors.black45),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: _buildPreviewCard(),
          ),
        ),
      ),
    ];
  }

  Widget _buildPreviewCard() {
    final sel = _selectedDay!;
    final dayEvents = events[sel.day] ?? [];
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(sel);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 600 ? 16 : 24,
        16,
        MediaQuery.of(context).size.width < 600 ? 16 : 24,
        28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Color(0xFF2563EB), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismissPreview,
                child: Icon(Icons.close, color: Colors.grey[400], size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dayEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No clients scheduled for this day.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            )
          else
            ..._buildPreviewEventList(dayEvents),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Builder(builder: (ctx) {
                  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  final isPast = _selectedDay != null && _selectedDay!.isBefore(today);
                  return ElevatedButton.icon(
                  onPressed: isPast ? null : () => showAddScheduleDialog(
                    context,
                    date: _selectedDay,
                    onCreated: _loadEvents,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToDayClients,
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text('View All Clients'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPreviewEventList(List<ScheduleEvent> dayEvents) {
    return [
      Text(
        '${dayEvents.length} client(s) scheduled',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 10),
      ...dayEvents.take(3).map(
            (e) => _buildPreviewEventRow(
              e,
              onSelectForDrag: () => _selectClientForDrag(e, _selectedDay!.day),
            ),
          ),
      if (dayEvents.length > 3)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '+${dayEvents.length - 3} more clients',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
    ];
  }

  Widget _buildPreviewEventRow(
    ScheduleEvent event, {
    VoidCallback? onSelectForDrag,
  }) {
    return GestureDetector(
      onTap: onSelectForDrag,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: event.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: event.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _scheduleTypeLabel(event.type),
                style: TextStyle(
                  fontSize: 10,
                  color: event.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onSelectForDrag != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.open_with, size: 14, color: Colors.grey[400])
            ],
          ],
        ),
      ),
    );
  }

  String _scheduleTypeLabel(ScheduleType type) {
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

  Widget _buildNameSearchField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Search by name',
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 20,
          color: Colors.grey[600],
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerIcon() {
    return GestureDetector(
      onTap: _pickFilterDate,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _filterDate != null
              ? const Color(0xFF2563EB).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _filterDate != null
                ? const Color(0xFF2563EB).withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          Icons.calendar_month_outlined,
          size: 22,
          color: _filterDate != null
              ? const Color(0xFF2563EB)
              : Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2563EB),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _filterDate = picked;
        // Also navigate to the picked month and select that day
        _currentMonth = DateTime(picked.year, picked.month, 1);
        _gridKey++;
        _selectedDay = picked;
        _previewVisible = true;
      });
      _previewController.forward(from: 0);
    }
  }

  Widget _buildGoButton({bool compact = false}) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _nameFilter = _nameController.text.trim());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Go',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildClearButton({bool compact = false}) {
    return OutlinedButton(
      onPressed: () {
        _nameController.clear();
        setState(() {
          _nameFilter = '';
          _filterDate = null;
          _statusFilter = null;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: 14,
        ),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'Clear',
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMonthNavButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
            iconSize: 24,
            color: const Color(0xFF2563EB),
            tooltip: 'Previous Month',
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey[200],
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
            iconSize: 24,
            color: const Color(0xFF2563EB),
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  // ── Drag panel ─────────────────────────────────────────────────────────────

  Widget _buildDragPanel() {
    final client = _pendingDragClient!;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.drag_indicator,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Drag to a new date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _cancelDrag,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Hold and drag the chip below onto any calendar date:',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 10),
            Draggable<_CalendarDragData>(
              data: _CalendarDragData(
                event: client,
                fromDay: _pendingDragFromDay ?? 0,
              ),
              feedback: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: client.color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: client.color.withOpacity(0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        client.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: _buildClientChip(client),
              ),
              child: _buildClientChip(client),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientChip(ScheduleEvent client) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: client.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: client.color.withOpacity(0.45),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: client.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            client.displayName,
            style: TextStyle(
              color: client.color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.drag_handle,
            size: 16,
            color: client.color.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleButton({bool compact = false}) {
    return ElevatedButton.icon(
      onPressed: () => showAddScheduleDialog(
        context,
        date: _selectedDay ?? DateTime.now(),
        onCreated: _loadEvents,
      ),
      icon: const Icon(Icons.add, size: 16),
      label: const Text(
        'Schedule',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    );
  }

  static const _legendTooltips = {
    ScheduleType.pending:
        'The schedule is not yet confirmed and is waiting for approval, customer confirmation, or resource availability before it can be set.',
    ScheduleType.tentative:
        'A provisional schedule that has been set but may still change depending on confirmation, availability, or other conditions.',
    ScheduleType.final_:
        'The schedule has been finalized and approved, and the activity or transaction is officially set to proceed on the specified date and time.',
    ScheduleType.resolved:
        'Marked as Resolved — event is locked from further changes.',
    ScheduleType.name:
        'Marked as the client opted to make the Back-end Set-up. Please exercise careful evaluation on the completeness of the materials needed, most especially the GAS FITTINGS.',
  };

  Widget _buildLegendItem(String label, Color color, {ScheduleType? type}) {
    final isActive = type != null && _statusFilter == type;
    return Tooltip(
      message: type != null ? (_legendTooltips[type] ?? '') : '',
      preferBelow: true,
      child: GestureDetector(
      onTap: type == null
          ? null
          : () {
              setState(() {
                _statusFilter = _statusFilter == type ? null : type;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? color : Colors.grey[800],
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    ), // GestureDetector
    ); // Tooltip
  }
}

// ── Drag data carrier ────────────────────────────────────────────────────────

class _CalendarDragData {
  final ScheduleEvent event;
  final int fromDay;
  const _CalendarDragData({required this.event, required this.fromDay});
}

// ── One-time drag guide dialog with fade+scale animation ─────────────────────

class _DragGuideDialog extends StatefulWidget {
  const _DragGuideDialog();

  @override
  State<_DragGuideDialog> createState() => _DragGuideDialogState();
}

class _DragGuideDialogState extends State<_DragGuideDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.open_with,
                    size: 32,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 18),
                // Title
                const Text(
                  'Drag to Reschedule',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  'Tap the  icon on any client card to pick it up, '
                  'then drag and drop it onto a new date in the calendar to reschedule.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                // Inline icon hint row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(Icons.open_with,
                          size: 16, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '= Item is draggable',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Got It button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got It',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
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