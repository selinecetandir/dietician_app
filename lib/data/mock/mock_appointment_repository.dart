import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';
import '../../core/enums/enums.dart';
import 'mock_database.dart';

class MockAppointmentRepository implements AppointmentRepository {
  final MockDatabase _db = MockDatabase();

  @override
  Future<List<AppointmentModel>> getAppointmentsForPatient(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.getAppointmentsForPatient(patientId);
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForDietitian(String dietitianId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.getAppointmentsForDietitian(dietitianId);
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _db.addAppointment(appointment);
    return appointment;
  }

  @override
  Future<AppointmentModel> updateStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    _db.updateAppointmentStatus(appointmentId, status);
    final updated = _db.findAppointmentById(appointmentId);
    if (updated == null) {
      throw Exception('Appointment not found: $appointmentId');
    }
    return updated;
  }
}
