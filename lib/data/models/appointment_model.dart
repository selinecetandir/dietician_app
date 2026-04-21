import '../../core/enums/enums.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String dietitianId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? notes;
  final String? slotId;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.dietitianId,
    required this.dateTime,
    this.status = AppointmentStatus.pending,
    this.notes,
    this.slotId,
  });
}
