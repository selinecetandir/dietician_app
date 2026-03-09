import '../models/dietitian_model.dart';
import '../models/time_slot_model.dart';
import '../repositories/dietitian_repository.dart';
import 'mock_database.dart';

class MockDietitianRepository implements DietitianRepository {
  final MockDatabase _db = MockDatabase();

  @override
  Future<List<DietitianModel>> getAllDietitians() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.getAllDietitians();
  }

  @override
  Future<DietitianModel?> getDietitianById(String id) async {
    final user = _db.findUserById(id);
    return user is DietitianModel ? user : null;
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots(String dietitianId) async {
    return _db.getAvailableSlotsForDietitian(dietitianId);
  }

  @override
  Future<void> updateSlots(String dietitianId, List<TimeSlotModel> slots) async {
    _db.replaceSlots(dietitianId, slots);
  }
}
