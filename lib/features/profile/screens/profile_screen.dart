import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/enums/enums.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/dietitian_model.dart';
import '../../../data/models/patient_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _goalLabels = <PatientGoal, String>{
    PatientGoal.loseWeight: 'Lose Weight',
    PatientGoal.gainWeight: 'Gain Weight',
    PatientGoal.stayHealthy: 'Stay Healthy',
    PatientGoal.buildMuscle: 'Build Muscle',
    PatientGoal.eatBalanced: 'Eat Balanced',
  };

  @override
  Widget build(BuildContext context) {
    final authRepo = RepositoryLocator.auth;
    final user = authRepo.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── Avatar & Name ──
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: colorScheme.primaryContainer,
                    child: user is PatientModel
                        ? Icon(
                            user.gender == Gender.female
                                ? Icons.female
                                : Icons.male,
                            size: 40,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.role == UserRole.dietitian ? 'Dietitian' : 'Patient',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Common Info ──
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),

                  // ── Dietitian Info ──
                  if (user is DietitianModel) ...[
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Title',
                      value: user.title,
                    ),
                    _InfoTile(
                      icon: Icons.local_hospital_outlined,
                      label: 'Clinic',
                      value: user.clinicName,
                    ),
                    _InfoTile(
                      icon: Icons.science_outlined,
                      label: 'Specialization',
                      value: user.specialization,
                    ),
                  ],

                  // ── Patient Info ──
                  if (user is PatientModel) ...[
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phone,
                    ),
                    _InfoTile(
                      icon: user.gender == Gender.female
                          ? Icons.female
                          : Icons.male,
                      label: 'Gender',
                      value:
                          user.gender == Gender.female ? 'Female' : 'Male',
                    ),
                    _InfoTile(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: '${user.age} years old',
                    ),

                    const SizedBox(height: 8),

                    // Weight & Height cards
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Weight',
                            value: '${user.weight.toStringAsFixed(1)} kg',
                            color: colorScheme.primary,
                            bgColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.height,
                            label: 'Height',
                            value: '${user.height.toStringAsFixed(0)} cm',
                            color: colorScheme.tertiary,
                            bgColor: colorScheme.tertiaryContainer
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.speed,
                            label: 'BMI',
                            value: _calcBmi(user.weight, user.height),
                            color: colorScheme.secondary,
                            bgColor: colorScheme.secondaryContainer
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Goal chip
                    _SectionCard(
                      icon: Icons.flag_outlined,
                      label: 'Main Goal',
                      child: Chip(
                        avatar: Icon(Icons.track_changes,
                            size: 18, color: colorScheme.primary),
                        label: Text(
                          _goalLabels[user.goal] ?? '',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: colorScheme.primaryContainer,
                        side: BorderSide.none,
                      ),
                    ),

                    if (user.allergies != null &&
                        user.allergies!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionCard(
                        icon: Icons.warning_amber_outlined,
                        label: 'Allergies',
                        child: Text(
                          user.allergies!,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],

                    if (user.healthCondition != null &&
                        user.healthCondition!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionCard(
                        icon: Icons.medical_information_outlined,
                        label: 'Health Condition',
                        child: Text(
                          user.healthCondition!,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await authRepo.logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.splash,
                            (_) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _calcBmi(double weight, double heightCm) {
    if (heightCm <= 0) return '-';
    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.outline),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
