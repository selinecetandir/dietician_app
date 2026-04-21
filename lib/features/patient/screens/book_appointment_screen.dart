import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/dietitian_model.dart';
import '../../../data/models/time_slot_model.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String dietitianId;

  const BookAppointmentScreen({super.key, required this.dietitianId});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _notesCtrl = TextEditingController();

  DietitianModel? _dietitian;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeSlotModel? _selectedSlot;
  bool _loading = true;
  bool _submitting = false;

  List<TimeSlotModel> _availableSlots = [];
  List<TimeSlotModel> _allDietitianSlots = [];

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

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await RepositoryLocator.dietitian.getDietitianById(widget.dietitianId);
    final slots = await RepositoryLocator.dietitian.getAvailableSlots(widget.dietitianId);
    if (!mounted) return;
    setState(() {
      _dietitian = d;
      _allDietitianSlots = slots;
      _loading = false;
    });
  }

  bool get _hasDietitianSlots => _allDietitianSlots.isNotEmpty;

  void _updateSlotsForDate(DateTime date) {
    final dayOfWeek = date.weekday;
    setState(() {
      _selectedSlot = null;
      _selectedTime = null;
      _availableSlots = _allDietitianSlots
          .where((s) => s.dayOfWeek == dayOfWeek)
          .toList()
        ..sort((a, b) =>
            (a.startTime.hour * 60 + a.startTime.minute)
                .compareTo(b.startTime.hour * 60 + b.startTime.minute));
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _updateSlotsForDate(picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    if (_hasDietitianSlots && _availableSlots.isNotEmpty && _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot.')),
      );
      return;
    }

    if (!_hasDietitianSlots && _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time.')),
      );
      return;
    }

    if (_hasDietitianSlots && _availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available slots on this day. Please pick another date.')),
      );
      return;
    }

    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    late DateTime dateTime;
    if (_selectedSlot != null) {
      dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedSlot!.startTime.hour,
        _selectedSlot!.startTime.minute,
      );
    } else if (_selectedTime != null) {
      dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        9,
        0,
      );
    }

    final appointment = AppointmentModel(
      id: '',
      patientId: user.id,
      dietitianId: widget.dietitianId,
      dateTime: dateTime,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      slotId: _selectedSlot?.id,
    );

    await RepositoryLocator.appointment.createAppointment(appointment);

    await RepositoryLocator.notification.createNotification(
      NotificationModel(
        id: '',
        recipientId: widget.dietitianId,
        type: NotificationType.appointmentRequested,
        title: 'New Appointment Request',
        message: '${user.name} requested an appointment on '
            '${_formatDate(dateTime)} at ${_formatSlotTime(dateTime)}.',
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment request sent!')),
    );
    Navigator.pop(context);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  String _formatSlotTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_dietitian != null)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            _dietitian!.name[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text('${_dietitian!.title} ${_dietitian!.name}'),
                        subtitle: Text(_dietitian!.specialization),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // --- DATE PICKER ---
                  Text('Select Date', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate != null
                          ? '${_formatDate(_selectedDate!)} (${_dayNames[_selectedDate!.weekday]})'
                          : 'Choose Date'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- TIME SELECTION ---
                  if (_selectedDate != null) ...[
                    Text('Select Time', style: textTheme.titleMedium),
                    const SizedBox(height: 12),

                    if (_hasDietitianSlots) ...[
                      if (_availableSlots.isEmpty)
                        Card(
                          color: colorScheme.errorContainer.withValues(alpha: 0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: colorScheme.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No available hours on ${_dayNames[_selectedDate!.weekday]}. '
                                    'Please choose another day.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSlots.map((slot) {
                            final isSelected = _selectedSlot?.id == slot.id;
                            return ChoiceChip(
                              label: Text(
                                '${_formatSlotTime(slot.startTime)} - ${_formatSlotTime(slot.endTime)}',
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSlot = selected ? slot : null;
                                });
                              },
                              selectedColor: colorScheme.primaryContainer,
                              checkmarkColor: colorScheme.onPrimaryContainer,
                            );
                          }).toList(),
                        ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_selectedTime != null
                              ? _formatTimeOfDay(_selectedTime!)
                              : 'Choose Time'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This dietitian has not set working hours. Pick any time you prefer.',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),

                  // --- NOTES ---
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Any details for the dietitian...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- SUBMIT ---
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Send Request'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
