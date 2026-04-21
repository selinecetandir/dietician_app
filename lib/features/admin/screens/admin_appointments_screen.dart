import 'package:flutter/material.dart';

import '../../../core/enums/enums.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repository_locator.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final _repo = RepositoryLocator.admin;

  List<AppointmentModel> _all = [];
  final Map<String, UserModel> _usersById = {};
  bool _loading = true;
  String? _error;
  AppointmentStatus? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getAllAppointments(),
        _repo.getAllUsers(),
      ]);
      final appointments = results[0] as List<AppointmentModel>;
      final users = results[1] as List<UserModel>;
      _usersById
        ..clear()
        ..addEntries(users.map((u) => MapEntry(u.id, u)));
      if (!mounted) return;
      setState(() {
        _all = appointments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<AppointmentModel> get _filtered {
    if (_filter == null) return _all;
    return _all.where((a) => a.status == _filter).toList();
  }

  Future<void> _deleteAppointment(AppointmentModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete appointment?'),
        content: const Text('This permanently removes the appointment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.deleteAppointment(a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Appointment deleted.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(
                    label: 'All',
                    selected: _filter == null,
                    onSelected: () => setState(() => _filter = null),
                  ),
                  _StatusChip(
                    label: 'Pending',
                    selected: _filter == AppointmentStatus.pending,
                    onSelected: () =>
                        setState(() => _filter = AppointmentStatus.pending),
                  ),
                  _StatusChip(
                    label: 'Approved',
                    selected: _filter == AppointmentStatus.approved,
                    onSelected: () =>
                        setState(() => _filter = AppointmentStatus.approved),
                  ),
                  _StatusChip(
                    label: 'Rejected',
                    selected: _filter == AppointmentStatus.rejected,
                    onSelected: () =>
                        setState(() => _filter = AppointmentStatus.rejected),
                  ),
                  _StatusChip(
                    label: 'Cancelled',
                    selected: _filter == AppointmentStatus.cancelled,
                    onSelected: () =>
                        setState(() => _filter = AppointmentStatus.cancelled),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Could not load appointments.\n$_error',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(child: Text('No appointments.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final a = _filtered[i];
                                return _AppointmentCard(
                                  appointment: a,
                                  patient: _usersById[a.patientId],
                                  dietitian: _usersById[a.dietitianId],
                                  onDelete: () => _deleteAppointment(a),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final UserModel? patient;
  final UserModel? dietitian;
  final VoidCallback onDelete;

  const _AppointmentCard({
    required this.appointment,
    required this.patient,
    required this.dietitian,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(appointment.status);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    appointment.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmtDateTime(appointment.dateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: colorScheme.error,
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 4),
            _PersonLine(
              icon: Icons.person_outline,
              label: 'Patient',
              name: patient?.name ?? '(unknown)',
              email: patient?.email ?? appointment.patientId,
            ),
            const SizedBox(height: 4),
            _PersonLine(
              icon: Icons.medical_services_outlined,
              label: 'Dietitian',
              name: dietitian?.name ?? '(unknown)',
              email: dietitian?.email ?? appointment.dietitianId,
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                appointment.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.amber.shade800;
      case AppointmentStatus.approved:
        return Colors.green;
      case AppointmentStatus.rejected:
        return Colors.red;
      case AppointmentStatus.cancelled:
        return Colors.grey;
    }
  }

  String _fmtDateTime(DateTime d) {
    final date = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }
}

class _PersonLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String name;
  final String email;

  const _PersonLine({
    required this.icon,
    required this.label,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: '  $email',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
