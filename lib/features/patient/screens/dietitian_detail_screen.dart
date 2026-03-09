import 'package:flutter/material.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/dietitian_model.dart';
import 'book_appointment_screen.dart';

class DietitianDetailScreen extends StatefulWidget {
  final String dietitianId;

  const DietitianDetailScreen({super.key, required this.dietitianId});

  @override
  State<DietitianDetailScreen> createState() => _DietitianDetailScreenState();
}

class _DietitianDetailScreenState extends State<DietitianDetailScreen> {
  DietitianModel? _dietitian;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await RepositoryLocator.dietitian.getDietitianById(widget.dietitianId);
    setState(() {
      _dietitian = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dietitian Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dietitian == null
              ? const Center(child: Text('Dietitian not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          _dietitian!.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_dietitian!.title} ${_dietitian!.name}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dietitian!.specialization,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _Row(
                                icon: Icons.local_hospital_outlined,
                                label: 'Clinic',
                                value: _dietitian!.clinicName,
                              ),
                              const Divider(height: 24),
                              _Row(
                                icon: Icons.science_outlined,
                                label: 'Specialization',
                                value: _dietitian!.specialization,
                              ),
                              const Divider(height: 24),
                              _Row(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: _dietitian!.email,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookAppointmentScreen(
                                  dietitianId: widget.dietitianId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Book Appointment'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }
}
