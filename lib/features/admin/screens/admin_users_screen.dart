import 'package:flutter/material.dart';

import '../../../core/enums/enums.dart';
import '../../../data/models/admin_model.dart';
import '../../../data/models/dietitian_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repository_locator.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = RepositoryLocator.admin;
  List<UserModel> _all = [];
  bool _loading = true;
  String? _error;
  UserRole? _filter;
  String _query = '';

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
      final users = await _repo.getAllUsers();
      if (!mounted) return;
      setState(() {
        _all = users;
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

  List<UserModel> get _filtered {
    Iterable<UserModel> list = _all;
    if (_filter != null) {
      list = list.where((u) => u.role == _filter);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where(
        (u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q),
      );
    }
    return list.toList();
  }

  Future<void> _confirmDelete(UserModel user) async {
    final currentAdmin = RepositoryLocator.auth.currentUser;
    if (currentAdmin != null && currentAdmin.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own admin account here.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'This removes the database record for "${user.name}" (${user.email}).\n\n'
          'Note: the Firebase Auth account itself is not deleted — that requires '
          'the Admin SDK on a backend.',
        ),
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
      await _repo.deleteUserRecord(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} removed.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or email',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onSelected: () => setState(() => _filter = null),
                  ),
                  _FilterChip(
                    label: 'Patients',
                    selected: _filter == UserRole.patient,
                    onSelected: () =>
                        setState(() => _filter = UserRole.patient),
                  ),
                  _FilterChip(
                    label: 'Dietitians',
                    selected: _filter == UserRole.dietitian,
                    onSelected: () =>
                        setState(() => _filter = UserRole.dietitian),
                  ),
                  _FilterChip(
                    label: 'Admins',
                    selected: _filter == UserRole.admin,
                    onSelected: () => setState(() => _filter = UserRole.admin),
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
                            'Could not load users.\n$_error',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(child: Text('No users match.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, i) =>
                                  _UserTile(user: _filtered[i], onDelete: () {
                                _confirmDelete(_filtered[i]);
                              }),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
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

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDelete;

  const _UserTile({required this.user, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (IconData icon, Color color, String roleLabel, String subtitle) =
        _presentation(user);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          user.name.isEmpty ? '(no name)' : user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showDetails(context, user, roleLabel),
      ),
    );
  }

  (IconData, Color, String, String) _presentation(UserModel user) {
    if (user is PatientModel) {
      return (
        Icons.person,
        Colors.teal,
        'Patient',
        'Patient · ${user.goal.name}',
      );
    }
    if (user is DietitianModel) {
      return (
        Icons.medical_services,
        Colors.indigo,
        'Dietitian',
        'Dietitian · ${user.clinicName}',
      );
    }
    if (user is AdminModel) {
      return (
        Icons.admin_panel_settings,
        Colors.deepPurple,
        'Admin',
        'Administrator',
      );
    }
    return (Icons.person_outline, Colors.grey, 'User', 'Unknown role');
  }

  void _showDetails(BuildContext context, UserModel user, String roleLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final entries = <MapEntry<String, String>>[
          MapEntry('Role', roleLabel),
          MapEntry('ID', user.id),
          MapEntry('Name', user.name),
          MapEntry('Email', user.email),
          MapEntry('Created', _fmtDate(user.createdAt)),
        ];

        if (user is PatientModel) {
          entries.addAll([
            MapEntry('Phone', user.phone),
            MapEntry('Gender', user.gender.name),
            MapEntry('Goal', user.goal.name),
            MapEntry('Weight', '${user.weight} kg'),
            MapEntry('Height', '${user.height} cm'),
            MapEntry('Allergies', user.allergies ?? '—'),
            MapEntry('Health', user.healthCondition ?? '—'),
          ]);
        } else if (user is DietitianModel) {
          entries.addAll([
            MapEntry('Title', user.title),
            MapEntry('Clinic', user.clinicName),
            MapEntry('Specialization', user.specialization),
            MapEntry('Education', user.education ?? '—'),
            MapEntry('Certificates', user.certificates ?? '—'),
          ]);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  user.name.isEmpty ? '(no name)' : user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(height: 24),
                ...entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    if (d.millisecondsSinceEpoch == 0) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
