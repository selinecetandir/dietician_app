import 'package:flutter/material.dart';

import '../../../data/models/diet_plan_model.dart';
import '../../../data/repository_locator.dart';

class AddDietPlanScreen extends StatefulWidget {
  final String patientId;
  final DietPlanModel? existingPlan;

  const AddDietPlanScreen({
    super.key,
    required this.patientId,
    this.existingPlan,
  });

  @override
  State<AddDietPlanScreen> createState() => _AddDietPlanScreenState();
}

class _AddDietPlanScreenState extends State<AddDietPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  DateTime? _weekStart;
  DateTime? _weekEnd;
  bool _saving = false;
  int _currentStep = 0;

  bool get _isEditing => widget.existingPlan != null;

  static const _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  late final List<_DayControllers> _days;

  @override
  void initState() {
    super.initState();
    _days = List.generate(7, (i) => _DayControllers());

    if (_isEditing) {
      final plan = widget.existingPlan!;
      _titleCtrl.text = plan.title;
      _weekStart = plan.weekStartDate;
      _weekEnd = plan.weekEndDate;

      for (int i = 0; i < plan.dailyPlans.length && i < 7; i++) {
        final day = plan.dailyPlans[i];
        _days[i].breakfastNameCtrl.text = day.breakfast.name;
        _days[i].breakfastDescCtrl.text = day.breakfast.description;
        _days[i].lunchNameCtrl.text = day.lunch.name;
        _days[i].lunchDescCtrl.text = day.lunch.description;
        _days[i].dinnerNameCtrl.text = day.dinner.name;
        _days[i].dinnerDescCtrl.text = day.dinner.description;
        if (day.snack != null) {
          _days[i].snackNameCtrl.text = day.snack!.name;
          _days[i].snackDescCtrl.text = day.snack!.description;
        }
      }
    } else {
      final now = DateTime.now();
      _weekStart = now.subtract(Duration(days: now.weekday - 1));
      _weekEnd = _weekStart!.add(const Duration(days: 6));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _pickWeekStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Select week start date (Monday)',
    );
    if (picked != null) {
      setState(() {
        _weekStart = picked;
        _weekEnd = picked.add(const Duration(days: 6));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekStart == null || _weekEnd == null) return;

    setState(() => _saving = true);

    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    final dailyPlans = <DailyMealPlan>[];
    for (int i = 0; i < 7; i++) {
      final d = _days[i];
      dailyPlans.add(DailyMealPlan(
        dayName: _dayNames[i],
        breakfast: MealDetail(
          name: d.breakfastNameCtrl.text.trim(),
          description: d.breakfastDescCtrl.text.trim(),
        ),
        lunch: MealDetail(
          name: d.lunchNameCtrl.text.trim(),
          description: d.lunchDescCtrl.text.trim(),
        ),
        dinner: MealDetail(
          name: d.dinnerNameCtrl.text.trim(),
          description: d.dinnerDescCtrl.text.trim(),
        ),
        snack: d.snackNameCtrl.text.trim().isEmpty
            ? null
            : MealDetail(
                name: d.snackNameCtrl.text.trim(),
                description: d.snackDescCtrl.text.trim(),
              ),
      ));
    }

    final plan = DietPlanModel(
      id: _isEditing ? widget.existingPlan!.id : '',
      patientId: widget.patientId,
      dietitianId: user.id,
      weekStartDate: _weekStart!,
      weekEndDate: _weekEnd!,
      title: _titleCtrl.text.trim(),
      dailyPlans: dailyPlans,
      createdAt: _isEditing ? widget.existingPlan!.createdAt : DateTime.now(),
    );

    if (_isEditing) {
      await RepositoryLocator.dietPlan.updateDietPlan(plan);
    } else {
      await RepositoryLocator.dietPlan.addDietPlan(plan);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Diet plan updated successfully!'
            : 'Diet plan added successfully!'),
      ),
    );
    Navigator.pop(context);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Diet Plan' : 'Add Diet Plan'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 7) {
              setState(() => _currentStep++);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          onStepTapped: (index) {
            setState(() => _currentStep = index);
          },
          controlsBuilder: (context, details) {
            final isLast = details.stepIndex == 7;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (!isLast)
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isEditing ? Icons.save : Icons.check),
                      label: Text(_isEditing ? 'Update Plan' : 'Save Plan'),
                    ),
                  if (details.stepIndex > 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Plan Information'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Plan Title',
                      hintText: 'e.g. Weekly Diet Plan - Week 1',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Title is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickWeekStart,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Week Period', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                              Text(
                                _weekStart != null && _weekEnd != null
                                    ? '${_formatDate(_weekStart!)} - ${_formatDate(_weekEnd!)}'
                                    : 'Tap to select start date',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < 7; i++)
              Step(
                title: Text(_dayNames[i]),
                content: _DayForm(
                  dayName: _dayNames[i],
                  controllers: _days[i],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayControllers {
  final breakfastNameCtrl = TextEditingController();
  final breakfastDescCtrl = TextEditingController();
  final lunchNameCtrl = TextEditingController();
  final lunchDescCtrl = TextEditingController();
  final dinnerNameCtrl = TextEditingController();
  final dinnerDescCtrl = TextEditingController();
  final snackNameCtrl = TextEditingController();
  final snackDescCtrl = TextEditingController();

  void dispose() {
    breakfastNameCtrl.dispose();
    breakfastDescCtrl.dispose();
    lunchNameCtrl.dispose();
    lunchDescCtrl.dispose();
    dinnerNameCtrl.dispose();
    dinnerDescCtrl.dispose();
    snackNameCtrl.dispose();
    snackDescCtrl.dispose();
  }
}

class _DayForm extends StatelessWidget {
  final String dayName;
  final _DayControllers controllers;

  const _DayForm({required this.dayName, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _mealSection(context, 'Breakfast', Icons.wb_sunny_outlined,
            controllers.breakfastNameCtrl, controllers.breakfastDescCtrl, true),
        const SizedBox(height: 12),
        _mealSection(context, 'Lunch', Icons.lunch_dining,
            controllers.lunchNameCtrl, controllers.lunchDescCtrl, true),
        const SizedBox(height: 12),
        _mealSection(context, 'Dinner', Icons.dinner_dining,
            controllers.dinnerNameCtrl, controllers.dinnerDescCtrl, true),
        const SizedBox(height: 12),
        _mealSection(context, 'Snack (optional)', Icons.apple,
            controllers.snackNameCtrl, controllers.snackDescCtrl, false),
      ],
    );
  }

  Widget _mealSection(
    BuildContext context,
    String label,
    IconData icon,
    TextEditingController nameCtrl,
    TextEditingController descCtrl,
    bool required,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Meal name',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: descCtrl,
          decoration: const InputDecoration(
            labelText: 'Details / portions',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
