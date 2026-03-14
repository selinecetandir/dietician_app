import 'package:flutter/material.dart';

import '../../../core/enums/enums.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repository_locator.dart';
import '../../../utils/user_parser.dart';

class AppointmentRequestsScreen extends StatefulWidget {
  const AppointmentRequestsScreen({super.key});

  @override
  State<AppointmentRequestsScreen> createState() =>
      _AppointmentRequestsScreenState();
}

class _AppointmentRequestsScreenState
    extends State<AppointmentRequestsScreen> {
  List<AppointmentModel> _requests = [];
  Map<String, String> _patientNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;
    final all =
        await RepositoryLocator.appointment.getAppointmentsForDietitian(user.id);
    final sorted = all..sort((a, b) {
        final statusOrder = {
          AppointmentStatus.pending: 0,
          AppointmentStatus.approved: 1,
          AppointmentStatus.rejected: 2,
          AppointmentStatus.cancelled: 3,
        };
        final cmp = statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
        if (cmp != 0) return cmp;
        return a.dateTime.compareTo(b.dateTime);
      });

    final patientIds = sorted.map((a) => a.patientId).toSet();
    final names = <String, String>{};
    for (final id in patientIds) {
      final patient = await getPatientById(id);
      names[id] = patient?.name ?? 'Unknown';
    }

    if (!mounted) return;
    setState(() {
      _requests = sorted;
      _patientNames = names;
      _loading = false;
    });
  }

  Future<void> _updateStatus(
      String id, AppointmentStatus status, String patientId) async {
    await RepositoryLocator.appointment.updateStatus(id, status);

    final user = RepositoryLocator.auth.currentUser;
    final isApproved = status == AppointmentStatus.approved;

    await RepositoryLocator.notification.createNotification(
      NotificationModel(
        id: '',
        recipientId: patientId,
        type: isApproved
            ? NotificationType.appointmentApproved
            : NotificationType.appointmentRejected,
        title: isApproved ? 'Appointment Approved' : 'Appointment Rejected',
        message: isApproved
            ? '${user?.name ?? 'Your dietitian'} approved your appointment request.'
            : '${user?.name ?? 'Your dietitian'} rejected your appointment request.',
        createdAt: DateTime.now(),
        referenceId: id,
      ),
    );

    await _load();
    if (mounted) {
      final label = isApproved ? 'approved' : 'rejected';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment $label.')),
      );
    }
  }

  String _patientName(String patientId) => _patientNames[patientId] ?? 'Unknown';

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No appointment requests.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    itemBuilder: (ctx, i) {
                      final a = _requests[i];
                      final isPending = a.status == AppointmentStatus.pending;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _statusColor(a.status)
                                        .withValues(alpha: 0.15),
                                    child: Icon(Icons.person,
                                        color: _statusColor(a.status)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _patientName(a.patientId),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(
                                          _formatDate(a.dateTime),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      _statusLabel(a.status),
                                      style: TextStyle(
                                        color: _statusColor(a.status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: _statusColor(a.status)
                                        .withValues(alpha: 0.1),
                                    side: BorderSide.none,
                                  ),
                                ],
                              ),
                              if (a.notes != null) ...[
                                const SizedBox(height: 8),
                                Text(a.notes!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _updateStatus(
                                          a.id, AppointmentStatus.rejected, a.patientId),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: () => _updateStatus(
                                          a.id, AppointmentStatus.approved, a.patientId),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
