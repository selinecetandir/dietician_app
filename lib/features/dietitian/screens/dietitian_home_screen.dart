import 'package:flutter/material.dart';

import '../../../core/enums/enums.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/repository_locator.dart';
import '../../../utils/user_parser.dart';
import 'patient_detail_screen.dart';

class DietitianHomeScreen extends StatefulWidget {
  const DietitianHomeScreen({super.key});

  @override
  State<DietitianHomeScreen> createState() => _DietitianHomeScreenState();
}

class _DietitianHomeScreenState extends State<DietitianHomeScreen> {
  List<PatientModel> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    final patientIds = await RepositoryLocator.firebaseAppointment
        .getApprovedPatientIdsForDietitian(user.id);
    final patients = <PatientModel>[];
    for (final id in patientIds) {
      final patient = await getPatientById(id);
      if (patient != null) patients.add(patient);
    }

    if (!mounted) return;
    setState(() {
      _patients = patients;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Patients')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No patients yet.',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patients will appear here once they book\nan appointment with you.',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _patients.length,
                    itemBuilder: (ctx, i) {
                      final patient = _patients[i];
                      return _PatientCard(
                        patient: patient,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientDetailScreen(patientId: patient.id),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: patient.gender == Gender.female
              ? Colors.pink.withValues(alpha: 0.15)
              : Colors.blue.withValues(alpha: 0.15),
          child: Icon(
            patient.gender == Gender.female ? Icons.female : Icons.male,
            color: patient.gender == Gender.female ? Colors.pink : Colors.blue,
          ),
        ),
        title: Text(
          patient.name,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${patient.age} years old',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
