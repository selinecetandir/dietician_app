import 'package:flutter/material.dart';

import '../../../core/enums/enums.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repository_locator.dart';
import '../../../utils/user_parser.dart';
import 'schedule_management_screen.dart';

class DailyProgramScreen extends StatefulWidget {
  const DailyProgramScreen({super.key});

  @override
  State<DailyProgramScreen> createState() => _DailyProgramScreenState();
}

class _DailyProgramScreenState extends State<DailyProgramScreen> {
  List<AppointmentModel> _allAppointments = [];
  Map<String, String> _patientNames = {};
  bool _loading = true;

  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    final all = await RepositoryLocator.appointment
        .getAppointmentsForDietitian(user.id);

    final patientIds = all.map((a) => a.patientId).toSet();
    final names = <String, String>{};
    for (final id in patientIds) {
      final patient = await getPatientById(id);
      names[id] = patient?.name ?? 'Unknown';
    }

    if (!mounted) return;
    setState(() {
      _allAppointments = all;
      _patientNames = names;
      _loading = false;
    });
  }

  List<AppointmentModel> _appointmentsForDay(DateTime day) {
    return _allAppointments.where((a) {
      return a.dateTime.year == day.year &&
          a.dateTime.month == day.month &&
          a.dateTime.day == day.day &&
          (a.status == AppointmentStatus.approved ||
           a.status == AppointmentStatus.pending);
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  bool _hasAppointments(DateTime day) {
    return _allAppointments.any((a) =>
        a.dateTime.year == day.year &&
        a.dateTime.month == day.month &&
        a.dateTime.day == day.day &&
        (a.status == AppointmentStatus.approved ||
         a.status == AppointmentStatus.pending));
  }

  bool _hasApproved(DateTime day) {
    return _allAppointments.any((a) =>
        a.dateTime.year == day.year &&
        a.dateTime.month == day.month &&
        a.dateTime.day == day.day &&
        a.status == AppointmentStatus.approved);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(AppointmentStatus status, ColorScheme cs) {
    switch (status) {
      case AppointmentStatus.approved:
        return cs.primary;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.rejected:
        return cs.error;
      case AppointmentStatus.cancelled:
        return cs.outline;
    }
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.approved:
        return 'Approved';
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedDayAppointments = _appointmentsForDay(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleManagementScreen()),
              );
              _load();
            },
            icon: const Icon(Icons.edit_calendar),
            tooltip: 'Manage Working Hours',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  // --- CALENDAR ---
                  _buildCalendar(colorScheme, textTheme),
                  const Divider(height: 1),

                  // --- SELECTED DAY HEADER ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // --- APPOINTMENTS LIST ---
                  if (selectedDayAppointments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.event_available, size: 48,
                              color: colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'No appointments for this day.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...selectedDayAppointments.map((a) => _buildAppointmentCard(a, colorScheme, textTheme)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendar(ColorScheme cs, TextTheme tt) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final today = DateTime.now();

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.outline,
                            )),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: _buildWeeks(
              firstDayOfMonth, daysInMonth, startWeekday, today, cs,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildWeeks(DateTime firstDay, int daysInMonth,
      int startWeekday, DateTime today, ColorScheme cs) {
    final weeks = <Widget>[];
    int dayCounter = 1;
    int weekday = startWeekday;

    while (dayCounter <= daysInMonth) {
      final row = <Widget>[];

      for (int col = 1; col <= 7; col++) {
        if ((weeks.isEmpty && col < weekday) || dayCounter > daysInMonth) {
          row.add(const Expanded(child: SizedBox(height: 44)));
        } else {
          final day = DateTime(_focusedMonth.year, _focusedMonth.month, dayCounter);
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final hasAppts = _hasAppointments(day);
          final hasApproved = _hasApproved(day);

          row.add(Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = day),
              child: Container(
                height: 44,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary
                      : isToday
                          ? cs.primaryContainer.withValues(alpha: 0.4)
                          : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayCounter.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? cs.onPrimary
                            : isToday
                                ? cs.primary
                                : null,
                      ),
                    ),
                    if (hasAppts)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? cs.onPrimary
                              : hasApproved
                                  ? cs.primary
                                  : Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ));
          dayCounter++;
        }
      }
      weeks.add(Row(children: row));
    }
    return weeks;
  }

  Widget _buildAppointmentCard(
      AppointmentModel a, ColorScheme cs, TextTheme tt) {
    final statusColor = _statusColor(a.status, cs);
    final patientName = _patientNames[a.patientId] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTime(a.dateTime),
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName,
                              style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(a.status),
                                  style: tt.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (a.notes != null && a.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(a.notes!,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.outline,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
