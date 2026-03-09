import '../../core/enums/enums.dart';

class TimeSlotModel {
  final String id;
  final String dietitianId;
  final int dayOfWeek; // 1 = Monday … 7 = Sunday
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;

  const TimeSlotModel({
    required this.id,
    required this.dietitianId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.status = SlotStatus.available,
  });
}
