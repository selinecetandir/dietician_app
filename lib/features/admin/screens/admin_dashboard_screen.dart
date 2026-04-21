import 'package:flutter/material.dart';

import '../../../data/firebase/firebase_admin_repository.dart';
import '../../../data/repository_locator.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repo = RepositoryLocator.admin;
  AdminStats? _stats;
  bool _loading = true;
  String? _error;

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
      final stats = await _repo.getStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(Icons.error_outline,
                          size: 48, color: colorScheme.error),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Could not load stats.\n$_error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : _buildContent(context, _stats!),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminStats stats) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'System overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'A live snapshot of users and appointments.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),

        _SectionHeader(title: 'Users (${stats.totalUsers})'),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _StatCard(
              label: 'Patients',
              value: stats.patientCount,
              icon: Icons.person_outline,
              color: Colors.teal,
            ),
            _StatCard(
              label: 'Dietitians',
              value: stats.dietitianCount,
              icon: Icons.medical_services_outlined,
              color: Colors.indigo,
            ),
            _StatCard(
              label: 'Admins',
              value: stats.adminCount,
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.deepPurple,
            ),
            _StatCard(
              label: 'Total users',
              value: stats.totalUsers,
              icon: Icons.groups_outlined,
              color: Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 20),
        _SectionHeader(title: 'Appointments (${stats.totalAppointments})'),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _StatCard(
              label: 'Total',
              value: stats.totalAppointments,
              icon: Icons.event_note_outlined,
              color: Colors.blueGrey,
            ),
            _StatCard(
              label: 'Pending',
              value: stats.pendingAppointments,
              icon: Icons.pending_outlined,
              color: Colors.amber.shade800,
            ),
            _StatCard(
              label: 'Approved',
              value: stats.approvedAppointments,
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            _StatCard(
              label: 'Other',
              value: stats.totalAppointments -
                  stats.pendingAppointments -
                  stats.approvedAppointments,
              icon: Icons.more_horiz,
              color: Colors.redAccent,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
