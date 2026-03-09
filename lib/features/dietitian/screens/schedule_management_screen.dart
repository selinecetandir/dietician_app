import 'package:flutter/material.dart';

import '../../../core/enums/enums.dart';
import '../../../data/models/time_slot_model.dart';
import '../../../data/repository_locator.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  Map<int, List<TimeSlotModel>> _slotsByDay = {};
  bool _loading = true;

  static const _dayNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    final slots = await RepositoryLocator.firebaseDietitian
        .getAllSlotsForDietitian(user.id);
    final map = <int, List<TimeSlotModel>>{};
    for (int d = 1; d <= 7; d++) {
      map[d] = slots.where((s) => s.dayOfWeek == d).toList()
        ..sort((a, b) => _timeValue(a.startTime).compareTo(_timeValue(b.startTime)));
    }

    if (!mounted) return;
    setState(() {
      _slotsByDay = map;
      _loading = false;
    });
  }

  int _timeValue(DateTime dt) => dt.hour * 60 + dt.minute;

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addSlot(int dayOfWeek) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Select start time',
    );
    if (startTime == null || !mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
      helpText: 'Select end time',
    );
    if (endTime == null || !mounted) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final slot = TimeSlotModel(
      id: '',
      dietitianId: user.id,
      dayOfWeek: dayOfWeek,
      startTime: DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute),
      endTime: DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute),
    );

    await RepositoryLocator.firebaseDietitian.addSlot(slot);
    _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Slot added: ${_dayNames[dayOfWeek]} '
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - '
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteSlot(TimeSlotModel slot) async {
    await RepositoryLocator.firebaseDietitian.deleteSlot(slot.id);
    _load();
  }

  Future<void> _confirmDeleteSlot(TimeSlotModel slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Slot'),
        content: Text(
          'Remove ${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)} '
          'on ${_dayNames[slot.dayOfWeek]}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteSlot(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Working Hours')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 7,
              itemBuilder: (ctx, i) {
                final day = i + 1;
                final slots = _slotsByDay[day] ?? [];
                final isWeekend = day >= 6;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isWeekend
                          ? colorScheme.tertiaryContainer
                          : colorScheme.primaryContainer,
                      child: Text(
                        _dayNames[day]![0],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isWeekend
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      _dayNames[day]!,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      slots.isEmpty
                          ? 'No available hours'
                          : '${slots.length} slot${slots.length > 1 ? 's' : ''}',
                      style: textTheme.bodySmall?.copyWith(
                        color: slots.isEmpty
                            ? colorScheme.outline
                            : colorScheme.primary,
                      ),
                    ),
                    children: [
                      if (slots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'No available hours set for this day.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        )
                      else
                        ...slots.map((slot) => ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.schedule,
                                size: 20,
                                color: slot.status == SlotStatus.available
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                              title: Text(
                                '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: slot.status == SlotStatus.available
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      slot.status == SlotStatus.available
                                          ? 'Available'
                                          : 'Booked',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: slot.status == SlotStatus.available
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => _confirmDeleteSlot(slot),
                                    icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                                    tooltip: 'Remove slot',
                                  ),
                                ],
                              ),
                            )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _addSlot(day),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Slot'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
