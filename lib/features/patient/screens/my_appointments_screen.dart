import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/appointment_model.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  Map<String, String> _dietitianNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;
    final list = await RepositoryLocator.appointment.getAppointmentsForPatient(user.id);
    final names = <String, String>{};
    for (final a in list) {
      if (!names.containsKey(a.dietitianId)) {
        final d = await RepositoryLocator.dietitian.getDietitianById(a.dietitianId);
        names[a.dietitianId] = d != null ? '${d.title} ${d.name}' : 'Unknown';
      }
    }
    setState(() {
      _appointments = list;
      _dietitianNames = names;
      _loading = false;
    });
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.approved:
        return Colors.green;
      case AppointmentStatus.rejected:
        return Colors.red;
      case AppointmentStatus.cancelled:
        return Colors.grey;
    }
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.approved:
        return 'Approved';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _dietitianName(String dietitianId) {
    return _dietitianNames[dietitianId] ?? 'Unknown';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _canCancel(AppointmentStatus status) {
    return status == AppointmentStatus.pending ||
        status == AppointmentStatus.approved;
  }

//Randevu iptal işlemi
  Future<void> _confirmCancel(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel your appointment with '
          '${_dietitianName(appointment.dietitianId)} on '
          '${_formatDate(appointment.dateTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await RepositoryLocator.appointment.updateStatus(
        appointment.id,
        AppointmentStatus.cancelled,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 64,
                          color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No appointments yet.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse dietitians to book one.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _appointments.length,
                    itemBuilder: (ctx, i) {
                      final a = _appointments[i];
                      final canCancel = _canCancel(a.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(a.status).withValues(alpha: 0.15),
                              child: Icon(
                                Icons.calendar_today,
                                color: _statusColor(a.status),
                              ),
                            ),
                            title: Text(_dietitianName(a.dietitianId)),
                            subtitle: Text(_formatDate(a.dateTime)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    _statusLabel(a.status),
                                    style: TextStyle(
                                      color: _statusColor(a.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: _statusColor(a.status).withValues(alpha: 0.1),
                                  side: BorderSide.none,
                                ),
                                if (canCancel) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => _confirmCancel(a),
                                    icon: const Icon(Icons.close, size: 20),
                                    tooltip: 'Cancel appointment',
                                    style: IconButton.styleFrom(
                                      foregroundColor: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
