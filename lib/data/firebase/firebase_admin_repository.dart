import 'package:firebase_database/firebase_database.dart';

import '../../core/enums/enums.dart';
import '../models/admin_model.dart';
import '../models/appointment_model.dart';
import '../models/dietitian_model.dart';
import '../models/patient_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AdminStats {
  final int patientCount;
  final int dietitianCount;
  final int adminCount;
  final int totalAppointments;
  final int pendingAppointments;
  final int approvedAppointments;

  const AdminStats({
    required this.patientCount,
    required this.dietitianCount,
    required this.adminCount,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.approvedAppointments,
  });

  int get totalUsers => patientCount + dietitianCount + adminCount;
}

class FirebaseAdminRepository {
  final _service = FirebaseService();

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _service.usersRef.get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final users = <UserModel>[];
    map.forEach((key, value) {
      final data = Map<String, dynamic>.from(value as Map);
      final parsed = _userFromMap(key, data);
      if (parsed != null) users.add(parsed);
    });
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  }

  Future<void> deleteUserRecord(String userId) async {
    await _service.usersRef.child(userId).remove();
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _service.usersRef.child(userId).update({'role': newRole.name});
  }

  Future<void> updateUserBasics(
    String userId, {
    String? name,
    String? email,
  }) async {
    final updates = <String, Object?>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (updates.isEmpty) return;
    await _service.usersRef.child(userId).update(updates);
  }

  Future<void> setUserActive(String userId, bool active) async {
    await _service.usersRef.child(userId).update({'isActive': active});
  }

  Future<List<AppointmentModel>> getAllAppointments() async {
    final snap = await _service.appointmentsRef.get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final list = <AppointmentModel>[];
    map.forEach((key, value) {
      final data = Map<String, dynamic>.from(value as Map);
      list.add(_appointmentFromMap(key, data));
    });
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<AdminStats> getStats() async {
    final users = await getAllUsers();
    final appointments = await getAllAppointments();

    return AdminStats(
      patientCount: users.whereType<PatientModel>().length,
      dietitianCount: users.whereType<DietitianModel>().length,
      adminCount: users.whereType<AdminModel>().length,
      totalAppointments: appointments.length,
      pendingAppointments: appointments
          .where((a) => a.status == AppointmentStatus.pending)
          .length,
      approvedAppointments: appointments
          .where((a) => a.status == AppointmentStatus.approved)
          .length,
    );
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    await _service.appointmentsRef
        .child(appointmentId)
        .update({'status': status.name});
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _service.appointmentsRef.child(appointmentId).remove();
  }

  UserModel? _userFromMap(String uid, Map<String, dynamic> data) {
    final roleStr = data['role'];
    if (roleStr is! String) return null;

    final UserRole role;
    try {
      role = UserRole.values.byName(roleStr);
    } catch (_) {
      return null;
    }

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      data['createdAt'] as int? ?? 0,
    );
    final isActive = data['isActive'] as bool? ?? true;

    switch (role) {
      case UserRole.admin:
        return AdminModel(
          id: uid,
          email: data['email'] as String? ?? '',
          name: data['name'] as String? ?? '',
          createdAt: createdAt,
          isActive: isActive,
        );
      case UserRole.dietitian:
        return DietitianModel(
          id: uid,
          email: data['email'] as String? ?? '',
          name: data['name'] as String? ?? '',
          createdAt: createdAt,
          title: data['title'] as String? ?? '',
          clinicName: data['clinicName'] as String? ?? '',
          specialization: data['specialization'] as String? ?? '',
          education: data['education'] as String? ?? '',
          certificates: data['certificates'] as String? ?? '',
          isActive: isActive,
        );
      case UserRole.patient:
        return PatientModel(
          id: uid,
          email: data['email'] as String? ?? '',
          name: data['name'] as String? ?? '',
          createdAt: createdAt,
          phone: data['phone'] as String? ?? '',
          gender: _parseGender(data['gender']),
          weight: (data['weight'] as num?)?.toDouble() ?? 0,
          height: (data['height'] as num?)?.toDouble() ?? 0,
          goal: _parseGoal(data['goal']),
          birthDate: DateTime.fromMillisecondsSinceEpoch(
            data['birthDate'] as int? ?? 0,
          ),
          allergies: _nullIfEmpty(data['allergies']),
          diet: _nullIfEmpty(data['diet']),
          healthCondition: _nullIfEmpty(data['healthCondition']),
          isActive: isActive,
        );
    }
  }

  AppointmentModel _appointmentFromMap(String id, Map<String, dynamic> data) {
    return AppointmentModel(
      id: id,
      patientId: data['patientId'] as String? ?? '',
      dietitianId: data['dietitianId'] as String? ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        data['dateTime'] as int? ?? 0,
      ),
      status: _parseStatus(data['status']),
      notes: _nullIfEmpty(data['notes']),
      slotId: _nullIfEmpty(data['slotId']),
    );
  }

  Gender _parseGender(Object? value) {
    if (value is String) {
      try {
        return Gender.values.byName(value);
      } catch (_) {}
    }
    return Gender.male;
  }

  PatientGoal _parseGoal(Object? value) {
    if (value is String) {
      try {
        return PatientGoal.values.byName(value);
      } catch (_) {}
    }
    return PatientGoal.stayHealthy;
  }

  AppointmentStatus _parseStatus(Object? value) {
    if (value is String) {
      try {
        return AppointmentStatus.values.byName(value);
      } catch (_) {}
    }
    return AppointmentStatus.pending;
  }

  String? _nullIfEmpty(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  // Exposed for tests / future streaming use.
  DatabaseReference get usersRef => _service.usersRef;
  DatabaseReference get appointmentsRef => _service.appointmentsRef;
}
