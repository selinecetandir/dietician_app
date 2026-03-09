import '../models/appointment_model.dart';
import '../../core/enums/enums.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentModel>> getAppointmentsForPatient(String patientId);
  Future<List<AppointmentModel>> getAppointmentsForDietitian(String dietitianId);
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<AppointmentModel> updateStatus(String appointmentId, AppointmentStatus status);
}
