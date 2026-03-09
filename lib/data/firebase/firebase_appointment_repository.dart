import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';
import '../../core/enums/enums.dart';
import 'firebase_service.dart';

class FirebaseAppointmentRepository implements AppointmentRepository {
  final _service = FirebaseService();

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    final ref = _service.appointmentsRef.push();
    final data = _toMap(appointment);
    await ref.set(data);
    return AppointmentModel(
      id: ref.key!,
      patientId: appointment.patientId,
      dietitianId: appointment.dietitianId,
      dateTime: appointment.dateTime,
      status: appointment.status,
      notes: appointment.notes,
    );
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForPatient(String patientId) async {
    final snap = await _service.appointmentsRef
        .orderByChild('patientId')
        .equalTo(patientId)
        .get();
    return _parseList(snap);
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForDietitian(String dietitianId) async {
    final snap = await _service.appointmentsRef
        .orderByChild('dietitianId')
        .equalTo(dietitianId)
        .get();
    return _parseList(snap);
  }

  @override
  Future<AppointmentModel> updateStatus(String appointmentId, AppointmentStatus status) async {
    await _service.appointmentsRef
        .child(appointmentId)
        .update({'status': status.name});

    final snap = await _service.appointmentsRef.child(appointmentId).get();
    return _fromEntry(appointmentId, snap.value!);
  }

  Future<List<AppointmentModel>> getApprovedAppointmentsForDietitian(String dietitianId) async {
    final all = await getAppointmentsForDietitian(dietitianId);
    return all.where((a) => a.status == AppointmentStatus.approved).toList();
  }

  Future<String?> getPatientDietitianId(String patientId) async {
    final all = await getAppointmentsForPatient(patientId);

    final approved = all.where((a) => a.status == AppointmentStatus.approved).toList();
    if (approved.isNotEmpty) {
      approved.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return approved.first.dietitianId;
    }

    if (all.isNotEmpty) {
      all.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return all.first.dietitianId;
    }
    return null;
  }

  Future<AppointmentModel?> getNextAppointmentForPatient(String patientId) async {
    final now = DateTime.now();
    final all = await getAppointmentsForPatient(patientId);

    final upcoming = all
        .where((a) =>
            a.dateTime.isAfter(now) &&
            (a.status == AppointmentStatus.approved ||
             a.status == AppointmentStatus.pending))
        .toList();

    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.first;
  }

  Future<Set<String>> getApprovedPatientIdsForDietitian(String dietitianId) async {
    final approved = await getApprovedAppointmentsForDietitian(dietitianId);
    return approved.map((a) => a.patientId).toSet();
  }

  Map<String, dynamic> _toMap(AppointmentModel a) {
    return {
      'patientId': a.patientId,
      'dietitianId': a.dietitianId,
      'dateTime': a.dateTime.millisecondsSinceEpoch,
      'status': a.status.name,
      'notes': a.notes ?? '',
    };
  }

  AppointmentModel _fromEntry(String key, Object rawData) {
    final data = Map<String, dynamic>.from(rawData as Map);
    return AppointmentModel(
      id: key,
      patientId: data['patientId'] as String,
      dietitianId: data['dietitianId'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(data['dateTime'] as int),
      status: AppointmentStatus.values.byName(data['status'] as String),
      notes: _nullIfEmpty(data['notes']),
    );
  }

  List<AppointmentModel> _parseList(dynamic snap) {
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map.entries.map((e) => _fromEntry(e.key, e.value)).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  String? _nullIfEmpty(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }
}
