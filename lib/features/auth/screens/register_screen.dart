import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/dietitian_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/admin_model.dart';
import '../../../data/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepo = RepositoryLocator.auth;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Dietitian-specific
  final _titleCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _specCtrl = TextEditingController();

  // Patient-specific
  final _phoneCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  Gender? _selectedGender;
  PatientGoal? _selectedGoal;
  DateTime? _selectedBirthDate;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String get _roleLabel {
    switch (widget.role) {
      case UserRole.dietitian:
        return 'Dietitian';
      case UserRole.patient:
        return 'Patient';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static const _goalLabels = <PatientGoal, String>{
    PatientGoal.loseWeight: 'Lose Weight',
    PatientGoal.gainWeight: 'Gain Weight',
    PatientGoal.stayHealthy: 'Stay Healthy',
    PatientGoal.buildMuscle: 'Build Muscle',
    PatientGoal.eatBalanced: 'Eat Balanced',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _titleCtrl.dispose();
    _clinicCtrl.dispose();
    _specCtrl.dispose();
    _phoneCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _allergyCtrl.dispose();
    _healthCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.role == UserRole.patient) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender.')),
        );
        return;
      }
      if (_selectedGoal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your main goal.')),
        );
        return;
      }
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth.')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      const id = '';
      final now = DateTime.now();

      final UserModel user;
      if (widget.role == UserRole.admin) {
        user = AdminModel(
          id: id,
          email: _emailCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          createdAt: now,
        );
      } else if (widget.role == UserRole.dietitian) {
        user = DietitianModel(
          id: id,
          email: _emailCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          createdAt: now,
          title: _titleCtrl.text.trim(),
          clinicName: _clinicCtrl.text.trim(),
          specialization: _specCtrl.text.trim(),
        );
      } else {
        user = PatientModel(
              id: id,
              email: _emailCtrl.text.trim(),
              name: _nameCtrl.text.trim(),
              createdAt: now,
              phone: _phoneCtrl.text.trim(),
              gender: _selectedGender!,
              weight: double.parse(_weightCtrl.text.trim()),
              height: double.parse(_heightCtrl.text.trim()),
              goal: _selectedGoal!,
              birthDate: _selectedBirthDate!,
              allergies: _allergyCtrl.text.trim().isEmpty
                  ? null
                  : _allergyCtrl.text.trim(),
              healthCondition: _healthCtrl.text.trim().isEmpty
                  ? null
                  : _healthCtrl.text.trim(),
            );
      }

      await _authRepo.register(user: user, password: _passwordCtrl.text);
      await _authRepo.logout();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please log in.')),
      );

      Navigator.pop(context);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('$_roleLabel Registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Common fields ────────────────────────────
                _field(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: _required,
                ),
                _field(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // ── Dietitian-specific fields ─────────────────
                if (widget.role == UserRole.dietitian) ...[
                  const Divider(height: 32),
                  Text(
                    'Dietitian Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _titleCtrl,
                    label: 'Title (e.g. Specialist Dtt.)',
                    icon: Icons.badge_outlined,
                    validator: _required,
                  ),
                  _field(
                    controller: _clinicCtrl,
                    label: 'Clinic Name',
                    icon: Icons.local_hospital_outlined,
                    validator: _required,
                  ),
                  _field(
                    controller: _specCtrl,
                    label: 'Specialization',
                    icon: Icons.science_outlined,
                    validator: _required,
                  ),
                ],

                // ── Patient-specific fields ───────────────────
                if (widget.role == UserRole.patient) ...[
                  const Divider(height: 32),
                  Text(
                    'Patient Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Gender selection
                  Text(
                    'Gender',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _GenderButton(
                          label: 'Female',
                          icon: Icons.female,
                          selected: _selectedGender == Gender.female,
                          color: Colors.pink,
                          onTap: () =>
                              setState(() => _selectedGender = Gender.female),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GenderButton(
                          label: 'Male',
                          icon: Icons.male,
                          selected: _selectedGender == Gender.male,
                          color: Colors.blue,
                          onTap: () =>
                              setState(() => _selectedGender = Gender.male),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _field(
                    controller: _phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    validator: _required,
                  ),

                  // Date of birth
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                        helpText: 'Select your date of birth',
                      );
                      if (picked != null) {
                        setState(() => _selectedBirthDate = picked);
                      }
                    },
                    child: AbsorbPointer(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: const Icon(Icons.cake_outlined),
                            border: const OutlineInputBorder(),
                            hintText: _selectedBirthDate != null
                                ? '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/'
                                  '${_selectedBirthDate!.month.toString().padLeft(2, '0')}/'
                                  '${_selectedBirthDate!.year}'
                                : 'Tap to select',
                          ),
                          controller: TextEditingController(
                            text: _selectedBirthDate != null
                                ? '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/'
                                  '${_selectedBirthDate!.month.toString().padLeft(2, '0')}/'
                                  '${_selectedBirthDate!.year}'
                                : '',
                          ),
                          validator: (_) {
                            if (_selectedBirthDate == null) {
                              return 'Date of birth is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),

                  // Weight & Height side by side
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _weightCtrl,
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Weight is required';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _heightCtrl,
                          label: 'Height (cm)',
                          icon: Icons.height,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Height is required';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  // Goal selection
                  const SizedBox(height: 4),
                  Text(
                    'What Is Your Main Goal?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PatientGoal.values.map((goal) {
                      final isSelected = _selectedGoal == goal;
                      return ChoiceChip(
                        label: Text(_goalLabels[goal]!),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedGoal = goal),
                        selectedColor:
                            colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        avatar: isSelected
                            ? Icon(Icons.check_circle,
                                size: 18,
                                color: colorScheme.primary)
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  TextFormField(
                    controller: _allergyCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Allergies (if any)',
                      hintText: 'e.g. Peanuts, gluten, lactose...',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Health condition
                  TextFormField(
                    controller: _healthCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Health Conditions (if any)',
                      hintText: 'e.g. Diabetes, thyroid, hypertension...',
                      prefixIcon: Icon(Icons.medical_information_outlined),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _handleRegister,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign Up'),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return null;
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Theme.of(context).colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : Theme.of(context).colorScheme.outline),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? color : Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
