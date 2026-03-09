import '../models/dietitian_model.dart';
import '../models/time_slot_model.dart';

abstract class DietitianRepository {
  Future<List<DietitianModel>> getAllDietitians();
  Future<DietitianModel?> getDietitianById(String id);
  Future<List<TimeSlotModel>> getAvailableSlots(String dietitianId);
  Future<void> updateSlots(String dietitianId, List<TimeSlotModel> slots);
}
