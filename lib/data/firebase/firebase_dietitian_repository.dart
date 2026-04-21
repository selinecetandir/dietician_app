import '../models/dietitian_model.dart';
import '../models/time_slot_model.dart';
import '../repositories/dietitian_repository.dart';
import '../../core/enums/enums.dart';
import 'firebase_service.dart';

class FirebaseDietitianRepository implements DietitianRepository {
  final _service = FirebaseService();

  @override
  Future<List<DietitianModel>> getAllDietitians() async {
    final snap = await _service.usersRef
        .orderByChild('role')
        .equalTo(UserRole.dietitian.name)
        .get();

    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map.entries.map((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      return _dietitianFromMap(e.key, data);
    }).toList();
  }

  @override
  Future<DietitianModel?> getDietitianById(String id) async {
    final snap = await _service.usersRef.child(id).get();
    if (!snap.exists || snap.value == null) return null;
    final data = Map<String, dynamic>.from(snap.value as Map);
    if (data['role'] != UserRole.dietitian.name) return null;
    return _dietitianFromMap(id, data);
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots(String dietitianId) async {
    final all = await getAllSlotsForDietitian(dietitianId);
    return all.where((s) => s.status == SlotStatus.available).toList();
  }

  @override
  Future<void> updateSlots(String dietitianId, List<TimeSlotModel> slots) async {
    final existing = await getAllSlotsForDietitian(dietitianId);
    for (final slot in existing) {
      await _service.timeSlotsRef.child(slot.id).remove();
    }
    for (final slot in slots) {
      await addSlot(slot);
    }
  }

  Future<List<TimeSlotModel>> getAllSlotsForDietitian(String dietitianId) async {
    final snap = await _service.timeSlotsRef
        .orderByChild('dietitianId')
        .equalTo(dietitianId)
        .get();

    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map.entries.map((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      return _slotFromMap(e.key, data);
    }).toList();
  }

  Future<void> addSlot(TimeSlotModel slot) async {
    final ref = _service.timeSlotsRef.push();
    await ref.set(_slotToMap(slot));
  }

  Future<void> deleteSlot(String slotId) async {
    final snap = await _service.timeSlotsRef.child(slotId).get();
    if (snap.exists && snap.value != null) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      final status = SlotStatus.values.byName(
        data['status'] as String? ?? 'available',
      );
      if (status != SlotStatus.available) {
        throw StateError('Booked or blocked slots cannot be deleted.');
      }
    }
    await _service.timeSlotsRef.child(slotId).remove();
  }

  DietitianModel _dietitianFromMap(String id, Map<String, dynamic> data) {
    return DietitianModel(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int? ?? 0),
      title: data['title'] as String? ?? '',
      clinicName: data['clinicName'] as String? ?? '',
      specialization: data['specialization'] as String? ?? '',
      education: data['education'] as String? ?? '',
      certificates: data['certificates'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _slotToMap(TimeSlotModel s) {
    return {
      'dietitianId': s.dietitianId,
      'dayOfWeek': s.dayOfWeek,
      'startHour': s.startTime.hour,
      'startMinute': s.startTime.minute,
      'endHour': s.endTime.hour,
      'endMinute': s.endTime.minute,
      'status': s.status.name,
    };
  }

  TimeSlotModel _slotFromMap(String key, Map<String, dynamic> data) {
    final now = DateTime.now();
    return TimeSlotModel(
      id: key,
      dietitianId: data['dietitianId'] as String,
      dayOfWeek: data['dayOfWeek'] as int,
      startTime: DateTime(now.year, now.month, now.day,
          data['startHour'] as int, data['startMinute'] as int),
      endTime: DateTime(now.year, now.month, now.day,
          data['endHour'] as int, data['endMinute'] as int),
      status: SlotStatus.values.byName(data['status'] as String? ?? 'available'),
    );
  }
}
