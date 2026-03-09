import 'package:flutter/material.dart';

import '../../../core/enums/enums.dart';
import '../../../data/models/diet_plan_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/weight_entry_model.dart';
import '../../../data/repository_locator.dart';
import '../../../shared/widgets/weight_progress_chart.dart';
import '../../../utils/user_parser.dart';
import 'add_diet_plan_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  PatientModel? _patient;
  List<DietPlanModel> _dietPlans = [];
  List<WeightEntryModel> _weightEntries = [];
  bool _loading = true;

  static const _goalLabels = <PatientGoal, String>{
    PatientGoal.loseWeight: 'Lose Weight',
    PatientGoal.gainWeight: 'Gain Weight',
    PatientGoal.stayHealthy: 'Stay Healthy',
    PatientGoal.buildMuscle: 'Build Muscle',
    PatientGoal.eatBalanced: 'Eat Balanced',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patient = await getPatientById(widget.patientId);
    final plans = await RepositoryLocator.dietPlan
        .getDietPlansForPatient(widget.patientId);
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final weightEntries = await RepositoryLocator.weight
        .getWeightEntriesForPatient(widget.patientId);

    if (!mounted) return;
    setState(() {
      _patient = patient;
      _dietPlans = plans;
      _weightEntries = weightEntries;
      _loading = false;
    });
  }

  String _calcBmi(double weight, double heightCm) {
    if (heightCm <= 0) return '-';
    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Future<void> _confirmDelete(DietPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Diet Plan'),
        content: Text('Are you sure you want to delete "${plan.title}"?\nThis action cannot be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await RepositoryLocator.dietPlan.deleteDietPlan(plan.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet plan deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
              ? const Center(child: Text('Patient not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: _patient!.gender == Gender.female
                                  ? Colors.pink.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              child: Icon(
                                _patient!.gender == Gender.female
                                    ? Icons.female
                                    : Icons.male,
                                size: 38,
                                color: _patient!.gender == Gender.female
                                    ? Colors.pink
                                    : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _patient!.name,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_patient!.age} years old  •  ${_patient!.gender == Gender.female ? 'Female' : 'Male'}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Metrics ──
                      Row(
                        children: [
                          _MetricChip(label: 'Weight', value: '${_patient!.weight.toStringAsFixed(1)} kg', color: colorScheme.primary, bgColor: colorScheme.primaryContainer.withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          _MetricChip(label: 'Height', value: '${_patient!.height.toStringAsFixed(0)} cm', color: colorScheme.tertiary, bgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          _MetricChip(label: 'BMI', value: _calcBmi(_patient!.weight, _patient!.height), color: colorScheme.secondary, bgColor: colorScheme.secondaryContainer.withValues(alpha: 0.4)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Info cards ──
                      _infoCard(context, Icons.flag_outlined, 'Goal', _goalLabels[_patient!.goal] ?? ''),
                      _infoCard(context, Icons.phone_outlined, 'Phone', _patient!.phone),
                      _infoCard(context, Icons.email_outlined, 'Email', _patient!.email),

                      if (_patient!.allergies != null && _patient!.allergies!.isNotEmpty)
                        _infoCard(context, Icons.warning_amber_outlined, 'Allergies', _patient!.allergies!),

                      if (_patient!.healthCondition != null && _patient!.healthCondition!.isNotEmpty)
                        _infoCard(context, Icons.medical_information_outlined, 'Health Condition', _patient!.healthCondition!),

                      const SizedBox(height: 24),

                      // ── Weight Progress ──
                      Row(
                        children: [
                          Icon(Icons.show_chart, size: 22, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Weight Progress',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: WeightProgressChart(entries: _weightEntries),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Diet Plans section ──
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, size: 22, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Diet Plans',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddDietPlanScreen(
                                    patientId: widget.patientId,
                                  ),
                                ),
                              );
                              _load();
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Plan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_dietPlans.isEmpty)
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No diet plans yet.\nTap "Add Plan" to create one.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._dietPlans.map((plan) => _DietPlanCard(
                              plan: plan,
                              formatDate: _formatDate,
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddDietPlanScreen(
                                      patientId: widget.patientId,
                                      existingPlan: plan,
                                    ),
                                  ),
                                );
                                _load();
                              },
                              onDelete: () => _confirmDelete(plan),
                            )),
                    ],
                  ),
                ),
    );
  }

  Widget _infoCard(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.outline),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
      ),
    );
  }
}

class _DietPlanCard extends StatelessWidget {
  final DietPlanModel plan;
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DietPlanCard({
    required this.plan,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ExpansionTile(
            leading: Icon(Icons.calendar_view_week, color: colorScheme.primary),
            title: Text(
              plan.title,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${formatDate(plan.weekStartDate)} - ${formatDate(plan.weekEndDate)}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            children: [
              ...plan.dailyPlans.map((day) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.dayName,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _mealLine(context, 'Breakfast', day.breakfast),
                      _mealLine(context, 'Lunch', day.lunch),
                      _mealLine(context, 'Dinner', day.dinner),
                      if (day.snack != null)
                        _mealLine(context, 'Snack', day.snack!),
                      const Divider(height: 16),
                    ],
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealLine(BuildContext context, String label, MealDetail meal) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: meal.name),
            if (meal.description.isNotEmpty)
              TextSpan(
                text: ' — ${meal.description}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
