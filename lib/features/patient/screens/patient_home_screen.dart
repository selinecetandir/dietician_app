import 'package:flutter/material.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/dietitian_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/diet_plan_model.dart';
import '../../../data/models/weight_entry_model.dart';
import '../../../core/enums/enums.dart';
import '../../../shared/widgets/weight_progress_chart.dart';
import 'patient_documents_screen.dart';
import 'weight_log_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  DietitianModel? _dietitian;
  DietitianModel? _nextAppointmentDietitian;
  DietPlanModel? _dietPlan;
  AppointmentModel? _nextAppointment;
  List<WeightEntryModel> _weightEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    await Future.delayed(const Duration(milliseconds: 200));

    final dietitianId = await RepositoryLocator.firebaseAppointment
        .getPatientDietitianId(user.id);
    DietitianModel? dietitian;
    if (dietitianId != null) {
      dietitian = await RepositoryLocator.dietitian.getDietitianById(
        dietitianId,
      );
    }

    final dietPlan = await RepositoryLocator.dietPlan
        .getCurrentDietPlanForPatient(user.id);
    final nextAppointment = await RepositoryLocator.firebaseAppointment
        .getNextAppointmentForPatient(user.id);
    final weightEntries = await RepositoryLocator.weight
        .getWeightEntriesForPatient(user.id);

    DietitianModel? nextAppointmentDietitian;
    if (nextAppointment != null) {
      nextAppointmentDietitian = await RepositoryLocator.dietitian
          .getDietitianById(nextAppointment.dietitianId);
    }

    setState(() {
      _dietitian = dietitian;
      _dietPlan = dietPlan;
      _nextAppointment = nextAppointment;
      _nextAppointmentDietitian = nextAppointmentDietitian;
      _weightEntries = weightEntries;
      _loading = false;
    });
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}, ${days[dt.weekday - 1]}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _remainingText(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays > 0) {
      return 'in ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'in ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inMinutes > 0) {
      return 'in ${diff.inMinutes} min';
    }
    return 'Now';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildDietitianPin(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildPatientDocumentsCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildDietPlanCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildWeightProgressCard(colorScheme, textTheme),
                  const SizedBox(height: 20),
                  _buildAppointmentCard(colorScheme, textTheme),
                ],
              ),
            ),
    );
  }

  Widget _buildDietitianPin(ColorScheme colorScheme, TextTheme textTheme) {
    if (_dietitian == null) {
      return Card(
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                child: Icon(Icons.person_add, color: colorScheme.outline),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'You are not registered with a dietitian yet.\nBrowse the Dietitians tab to book an appointment.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primary,
              child: Text(
                _dietitian!.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_dietitian!.title} ${_dietitian!.name}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dietitian!.specialization,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    _dietitian!.clinicName,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.push_pin, size: 20, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDietPlanCard(ColorScheme colorScheme, TextTheme textTheme) {
    if (_dietPlan == null) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No weekly diet plan uploaded yet',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Your diet plan will appear here once your dietitian uploads it.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final today = DateTime.now().weekday;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: colorScheme.onPrimary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dietPlan!.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_formatDate(_dietPlan!.weekStartDate).split(',')[0]} - '
                        '${_formatDate(_dietPlan!.weekEndDate).split(',')[0]}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: _dietPlan!.dailyPlans.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final isToday = (index + 1) == today;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isToday
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : colorScheme.surfaceContainerLow,
                    border: isToday
                        ? Border.all(color: colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      leading: isToday
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Today',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      title: Text(
                        day.dayName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isToday ? colorScheme.primary : null,
                        ),
                      ),
                      initiallyExpanded: isToday,
                      children: [
                        _mealRow(
                          Icons.wb_sunny_outlined,
                          'Breakfast',
                          day.breakfast,
                          colorScheme,
                          textTheme,
                        ),
                        const SizedBox(height: 8),
                        _mealRow(
                          Icons.lunch_dining,
                          'Lunch',
                          day.lunch,
                          colorScheme,
                          textTheme,
                        ),
                        const SizedBox(height: 8),
                        _mealRow(
                          Icons.dinner_dining,
                          'Dinner',
                          day.dinner,
                          colorScheme,
                          textTheme,
                        ),
                        if (day.snack != null) ...[
                          const SizedBox(height: 8),
                          _mealRow(
                            Icons.apple,
                            'Snack',
                            day.snack!,
                            colorScheme,
                            textTheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDocumentsCard(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
          child: Icon(
            Icons.description_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          'Patient documents',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Lab reports and other PDFs linked to your profile.',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientDocumentsScreen()),
          );
          _load();
        },
      ),
    );
  }

  Widget _mealRow(
    IconData icon,
    String label,
    MealDetail meal,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                meal.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (meal.description.isNotEmpty)
                Text(
                  meal.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightProgressCard(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                Icon(Icons.show_chart, size: 22, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Weight Progress',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeightLogScreen(),
                      ),
                    );
                    _load();
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Details'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: WeightProgressChart(entries: _weightEntries),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(ColorScheme colorScheme, TextTheme textTheme) {
    if (_nextAppointment == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.event_available, size: 28, color: colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No upcoming appointments.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPending = _nextAppointment!.status == AppointmentStatus.pending;
    final statusText = isPending ? 'Pending' : 'Approved';
    final statusColor = isPending ? Colors.orange : Colors.green;

    String dietitianName = 'Dietitian';
    if (_nextAppointmentDietitian != null) {
      dietitianName =
          '${_nextAppointmentDietitian!.title} ${_nextAppointmentDietitian!.name}';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_filled,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Appointment',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _nextAppointment!.dateTime.day.toString(),
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          height: 1,
                        ),
                      ),
                      Text(
                        [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ][_nextAppointment!.dateTime.month - 1],
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dietitianName,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatDate(_nextAppointment!.dateTime),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_nextAppointment!.dateTime),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _remainingText(_nextAppointment!.dateTime),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
