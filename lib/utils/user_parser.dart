import '../core/enums/enums.dart';
import '../data/firebase/firebase_service.dart';
import '../data/models/patient_model.dart';

/// Fetches and parses a patient from Realtime Database users node.
/// Returns null if data doesn't exist or is not a patient.
Future<PatientModel?> getPatientById(String id) async {
  final snap = await FirebaseService().usersRef.child(id).get();
  if (!snap.exists || snap.value == null) return null;
  final data = Map<String, dynamic>.from(snap.value as Map);
  if (data['role'] != UserRole.patient.name) return null;
  return _patientFromMap(id, data);
}

PatientModel _patientFromMap(String id, Map<String, dynamic> data) {
  return PatientModel(
    id: id,
    email: data['email'] as String? ?? '',
    name: data['name'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int? ?? 0),
    phone: data['phone'] as String? ?? '',
    gender: Gender.values.byName(data['gender'] as String? ?? 'male'),
    weight: (data['weight'] as num?)?.toDouble() ?? 0,
    height: (data['height'] as num?)?.toDouble() ?? 0,
    goal: PatientGoal.values.byName(data['goal'] as String? ?? 'stayHealthy'),
    birthDate: DateTime.fromMillisecondsSinceEpoch(data['birthDate'] as int? ?? 0),
    allergies: _nullIfEmpty(data['allergies']),
    diet: _nullIfEmpty(data['diet']),
    healthCondition: _nullIfEmpty(data['healthCondition']),
    isActive: data['isActive'] as bool? ?? true,
  );
}

String? _nullIfEmpty(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}
