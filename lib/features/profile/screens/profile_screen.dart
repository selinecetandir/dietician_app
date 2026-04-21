import 'package:flutter/material.dart';
import '../../../app/router.dart';
import '../../../core/enums/enums.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/dietitian_model.dart';
import '../../../data/models/patient_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _goalLabels = <PatientGoal, String>{
    PatientGoal.loseWeight: 'Lose Weight',
    PatientGoal.gainWeight: 'Gain Weight',
    PatientGoal.stayHealthy: 'Stay Healthy',
    PatientGoal.buildMuscle: 'Build Muscle',
    PatientGoal.eatBalanced: 'Eat Balanced',
  };

  void _refresh() => setState(() {});

  Future<void> _showEditPatientSheet(PatientModel patient) async {
    final nameCtrl = TextEditingController(text: patient.name);
    final phoneCtrl = TextEditingController(text: patient.phone);
    final weightCtrl =
        TextEditingController(text: patient.weight.toStringAsFixed(1));
    final heightCtrl =
        TextEditingController(text: patient.height.toStringAsFixed(0));
    final allergyCtrl =
        TextEditingController(text: patient.allergies ?? '');
    final healthCtrl =
        TextEditingController(text: patient.healthCondition ?? '');
    PatientGoal selectedGoal = patient.goal;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditPatientSheet(
        nameCtrl: nameCtrl,
        phoneCtrl: phoneCtrl,
        weightCtrl: weightCtrl,
        heightCtrl: heightCtrl,
        allergyCtrl: allergyCtrl,
        healthCtrl: healthCtrl,
        initialGoal: selectedGoal,
        goalLabels: _goalLabels,
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    allergyCtrl.dispose();
    healthCtrl.dispose();

    if (saved == true) _refresh();
  }

  Future<void> _showEditDietitianSheet(DietitianModel dietitian) async {
    final nameCtrl = TextEditingController(text: dietitian.name);
    final titleCtrl = TextEditingController(text: dietitian.title);
    final clinicCtrl = TextEditingController(text: dietitian.clinicName);
    final specCtrl = TextEditingController(text: dietitian.specialization);
    final eduCtrl = TextEditingController(text: dietitian.education);
    final certCtrl = TextEditingController(text: dietitian.certificates);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditDietitianSheet(
        nameCtrl: nameCtrl,
        titleCtrl: titleCtrl,
        clinicCtrl: clinicCtrl,
        specCtrl: specCtrl,
        eduCtrl: eduCtrl,
        certCtrl: certCtrl,
      ),
    );

    nameCtrl.dispose();
    titleCtrl.dispose();
    clinicCtrl.dispose();
    specCtrl.dispose();
    eduCtrl.dispose();
    certCtrl.dispose();

    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = RepositoryLocator.auth;
    final user = authRepo.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () {
                if (user is PatientModel) {
                  _showEditPatientSheet(user);
                } else if (user is DietitianModel) {
                  _showEditDietitianSheet(user);
                }
              },
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
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

                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),

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
                    if (user.education.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionCard(
                        icon: Icons.school_outlined,
                        label: 'Education',
                        child: Text(
                          user.education,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                    if (user.certificates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionCard(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Certificates',
                        child: Text(
                          user.certificates,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],

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

// ---------------------------------------------------------------------------
// Edit sheets
// ---------------------------------------------------------------------------

class _EditPatientSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController allergyCtrl;
  final TextEditingController healthCtrl;
  final PatientGoal initialGoal;
  final Map<PatientGoal, String> goalLabels;

  const _EditPatientSheet({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.weightCtrl,
    required this.heightCtrl,
    required this.allergyCtrl,
    required this.healthCtrl,
    required this.initialGoal,
    required this.goalLabels,
  });

  @override
  State<_EditPatientSheet> createState() => _EditPatientSheetState();
}

class _EditPatientSheetState extends State<_EditPatientSheet> {
  final _formKey = GlobalKey<FormState>();
  late PatientGoal _selectedGoal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final weight = double.tryParse(widget.weightCtrl.text.trim());
    final height = double.tryParse(widget.heightCtrl.text.trim());

    final updates = <String, dynamic>{
      'name': widget.nameCtrl.text.trim(),
      'phone': widget.phoneCtrl.text.trim(),
      'goal': _selectedGoal.name,
      'allergies': widget.allergyCtrl.text.trim(),
      'healthCondition': widget.healthCtrl.text.trim(),
    };
    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;

    await RepositoryLocator.firebaseAuth.updateUserProfile(updates);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profile',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _formField(widget.nameCtrl, 'Full Name', Icons.person_outline,
                  required: true),
              _formField(widget.phoneCtrl, 'Phone', Icons.phone_outlined,
                  required: true, keyboard: TextInputType.phone),
              Row(
                children: [
                  Expanded(
                    child: _formField(
                      widget.weightCtrl,
                      'Weight (kg)',
                      Icons.monitor_weight_outlined,
                      required: true,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _formField(
                      widget.heightCtrl,
                      'Height (cm)',
                      Icons.height,
                      required: true,
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Main Goal',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PatientGoal.values.map((goal) {
                  final isSelected = _selectedGoal == goal;
                  return ChoiceChip(
                    label: Text(widget.goalLabels[goal]!),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedGoal = goal),
                    selectedColor: colorScheme.primaryContainer,
                    showCheckmark: false,
                    avatar: isSelected
                        ? Icon(Icons.check_circle,
                            size: 18, color: colorScheme.primary)
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _formField(
                widget.allergyCtrl,
                'Allergies',
                Icons.warning_amber_outlined,
                maxLines: 2,
              ),
              _formField(
                widget.healthCtrl,
                'Health Conditions',
                Icons.medical_information_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }
}

class _EditDietitianSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController clinicCtrl;
  final TextEditingController specCtrl;
  final TextEditingController eduCtrl;
  final TextEditingController certCtrl;

  const _EditDietitianSheet({
    required this.nameCtrl,
    required this.titleCtrl,
    required this.clinicCtrl,
    required this.specCtrl,
    required this.eduCtrl,
    required this.certCtrl,
  });

  @override
  State<_EditDietitianSheet> createState() => _EditDietitianSheetState();
}

class _EditDietitianSheetState extends State<_EditDietitianSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'name': widget.nameCtrl.text.trim(),
      'title': widget.titleCtrl.text.trim(),
      'clinicName': widget.clinicCtrl.text.trim(),
      'specialization': widget.specCtrl.text.trim(),
      'education': widget.eduCtrl.text.trim(),
      'certificates': widget.certCtrl.text.trim(),
    };

    await RepositoryLocator.firebaseAuth.updateUserProfile(updates);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profile',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _formField(widget.nameCtrl, 'Full Name', Icons.person_outline,
                  required: true),
              _formField(
                  widget.titleCtrl, 'Title', Icons.badge_outlined,
                  required: true),
              _formField(widget.clinicCtrl, 'Clinic Name',
                  Icons.local_hospital_outlined,
                  required: true),
              _formField(widget.specCtrl, 'Specialization',
                  Icons.science_outlined,
                  required: true),
              _formField(
                widget.eduCtrl,
                'Education',
                Icons.school_outlined,
                maxLines: 3,
                hint: 'e.g. PhD in Nutrition, BSc in Biochemistry',
              ),
              _formField(
                widget.certCtrl,
                'Certificates',
                Icons.workspace_premium_outlined,
                maxLines: 3,
                hint: 'e.g. Certified Diabetes Educator, Sports Nutrition',
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared display widgets
// ---------------------------------------------------------------------------

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
