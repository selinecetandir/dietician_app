import '../models/user_model.dart';
import '../models/dietitian_model.dart';
import '../models/patient_model.dart';
import '../models/appointment_model.dart';
import '../models/time_slot_model.dart';
import '../models/diet_plan_model.dart';
import '../models/weight_entry_model.dart';
import '../../core/enums/enums.dart';

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._();
  factory MockDatabase() => _instance;
  MockDatabase._();

  UserModel? currentUser;

  final List<UserModel> _users = [];
  final List<AppointmentModel> _appointments = [];
  final List<TimeSlotModel> _timeSlots = [];
  final List<DietPlanModel> _dietPlans = [];
  final List<WeightEntryModel> _weightEntries = [];
  final Map<String, String> _passwords = {};

  int _userIdCounter = 0;
  int _appointmentIdCounter = 0;
  int _slotIdCounter = 0;
  int _dietPlanIdCounter = 0;
  int _weightEntryIdCounter = 0;

  // ── Users ──────────────────────────────────────────────

  String _nextUserId() => 'u${++_userIdCounter}';

  void addUser(UserModel user, String password) {
    _users.add(user);
    _passwords[user.id] = password;
  }

  String generateUserId() => _nextUserId();

  UserModel? findUserByEmail(String email) {
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  UserModel? findUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  bool checkPassword(String userId, String password) {
    return _passwords[userId] == password;
  }

  List<DietitianModel> getAllDietitians() {
    return _users.whereType<DietitianModel>().toList();
  }

  List<PatientModel> getAllPatients() {
    return _users.whereType<PatientModel>().toList();
  }

  // ── Appointments ───────────────────────────────────────

  String generateAppointmentId() => 'a${++_appointmentIdCounter}';

  void addAppointment(AppointmentModel appointment) {
    _appointments.add(appointment);
  }

  List<AppointmentModel> getAppointmentsForPatient(String patientId) {
    return _appointments.where((a) => a.patientId == patientId).toList();
  }

  List<AppointmentModel> getAppointmentsForDietitian(String dietitianId) {
    return _appointments.where((a) => a.dietitianId == dietitianId).toList();
  }

  AppointmentModel? findAppointmentById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateAppointmentStatus(String appointmentId, AppointmentStatus status) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return;
    final old = _appointments[index];
    _appointments[index] = AppointmentModel(
      id: old.id,
      patientId: old.patientId,
      dietitianId: old.dietitianId,
      dateTime: old.dateTime,
      status: status,
      notes: old.notes,
    );
  }

  // ── Time Slots ─────────────────────────────────────────

  String generateSlotId() => 'ts${++_slotIdCounter}';

  void addTimeSlot(TimeSlotModel slot) {
    _timeSlots.add(slot);
  }

  List<TimeSlotModel> getSlotsForDietitian(String dietitianId) {
    return _timeSlots.where((s) => s.dietitianId == dietitianId).toList();
  }

  List<TimeSlotModel> getAvailableSlotsForDietitian(String dietitianId) {
    return _timeSlots
        .where((s) => s.dietitianId == dietitianId && s.status == SlotStatus.available)
        .toList();
  }

  void replaceSlots(String dietitianId, List<TimeSlotModel> newSlots) {
    _timeSlots.removeWhere((s) => s.dietitianId == dietitianId);
    _timeSlots.addAll(newSlots);
  }

  // ── Diet Plans ──────────────────────────────────────────

  String generateDietPlanId() => 'dp${++_dietPlanIdCounter}';

  void addDietPlan(DietPlanModel plan) {
    _dietPlans.add(plan);
  }

//Diyet planı düzenleme/silme
  void updateDietPlan(DietPlanModel updated) {
    final index = _dietPlans.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    _dietPlans[index] = updated;
  }

  void deleteDietPlan(String planId) {
    _dietPlans.removeWhere((p) => p.id == planId);
  }

  List<DietPlanModel> getDietPlansForPatient(String patientId) {
    return _dietPlans.where((p) => p.patientId == patientId).toList();
  }

  DietPlanModel? getCurrentDietPlanForPatient(String patientId) {
    final now = DateTime.now();
    try {
      return _dietPlans.firstWhere(
        (p) =>
            p.patientId == patientId &&
            !p.weekStartDate.isAfter(now) &&
            !p.weekEndDate.isBefore(now),
      );
    } catch (_) {
      final plans = getDietPlansForPatient(patientId);
      if (plans.isEmpty) return null;
      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plans.first;
    }
  }

  // ── Weight Entries ────────────────────────────────────

  String generateWeightEntryId() => 'we${++_weightEntryIdCounter}';

  void addWeightEntry(WeightEntryModel entry) {
    _weightEntries.add(entry);
  }

  List<WeightEntryModel> getWeightEntriesForPatient(String patientId) {
    final entries = _weightEntries
        .where((e) => e.patientId == patientId)
        .toList();
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  void deleteWeightEntry(String entryId) {
    _weightEntries.removeWhere((e) => e.id == entryId);
  }

  /// Returns the dietitian ID from the patient's approved appointments.
  String? getPatientDietitianId(String patientId) {
    final approved = _appointments
        .where((a) =>
            a.patientId == patientId &&
            a.status == AppointmentStatus.approved)
        .toList();
    if (approved.isEmpty) {
      final any = _appointments
          .where((a) => a.patientId == patientId)
          .toList();
      if (any.isEmpty) return null;
      any.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return any.first.dietitianId;
    }
    approved.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return approved.first.dietitianId;
  }

  /// Returns unique patients who have approved appointments with the given dietitian.
  List<PatientModel> getPatientsForDietitian(String dietitianId) {
    final patientIds = _appointments
        .where((a) =>
            a.dietitianId == dietitianId &&
            a.status == AppointmentStatus.approved)
        .map((a) => a.patientId)
        .toSet();
    return patientIds
        .map((id) => findUserById(id))
        .whereType<PatientModel>()
        .toList();
  }

  /// Returns the next upcoming appointment for the patient.
  AppointmentModel? getNextAppointmentForPatient(String patientId) {
    final now = DateTime.now();
    final upcoming = _appointments
        .where((a) =>
            a.patientId == patientId &&
            a.dateTime.isAfter(now) &&
            (a.status == AppointmentStatus.approved ||
                a.status == AppointmentStatus.pending))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.first;
  }
}
