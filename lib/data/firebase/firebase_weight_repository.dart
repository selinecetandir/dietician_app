import '../models/weight_entry_model.dart';
import 'firebase_service.dart';

class FirebaseWeightRepository {
  final _service = FirebaseService();

  Future<void> addWeightEntry(WeightEntryModel entry) async {
    final ref = _service.weightEntriesRef.push();
    await ref.set(_toMap(entry));
  }

  Future<List<WeightEntryModel>> getWeightEntriesForPatient(String patientId) async {
    final snap = await _service.weightEntriesRef
        .orderByChild('patientId')
        .equalTo(patientId)
        .get();

    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final entries = map.entries.map((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      return _fromMap(e.key, data);
    }).toList();
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  Future<void> deleteWeightEntry(String entryId) async {
    await _service.weightEntriesRef.child(entryId).remove();
  }

  Map<String, dynamic> _toMap(WeightEntryModel e) {
    return {
      'patientId': e.patientId,
      'weight': e.weight,
      'date': e.date.millisecondsSinceEpoch,
      'note': e.note ?? '',
    };
  }

  WeightEntryModel _fromMap(String key, Map<String, dynamic> data) {
    return WeightEntryModel(
      id: key,
      patientId: data['patientId'] as String,
      weight: (data['weight'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      note: _nullIfEmpty(data['note']),
    );
  }

  String? _nullIfEmpty(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }
}
