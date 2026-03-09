import '../models/diet_plan_model.dart';
import 'firebase_service.dart';

class FirebaseDietPlanRepository {
  final _service = FirebaseService();

  Future<void> addDietPlan(DietPlanModel plan) async {
    final ref = _service.dietPlansRef.push();
    await ref.set(_toMap(plan));
  }

  Future<void> updateDietPlan(DietPlanModel plan) async {
    await _service.dietPlansRef.child(plan.id).update(_toMap(plan));
  }

  Future<void> deleteDietPlan(String planId) async {
    await _service.dietPlansRef.child(planId).remove();
  }

  Future<List<DietPlanModel>> getDietPlansForPatient(String patientId) async {
    final snap = await _service.dietPlansRef
        .orderByChild('patientId')
        .equalTo(patientId)
        .get();

    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final plans = map.entries.map((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      return _fromMap(e.key, data);
    }).toList();
    plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return plans;
  }

  Future<DietPlanModel?> getCurrentDietPlanForPatient(String patientId) async {
    final plans = await getDietPlansForPatient(patientId);
    if (plans.isEmpty) return null;

    final now = DateTime.now();
    try {
      return plans.firstWhere(
        (p) => !p.weekStartDate.isAfter(now) && !p.weekEndDate.isBefore(now),
      );
    } catch (_) {
      return plans.first;
    }
  }

  Map<String, dynamic> _toMap(DietPlanModel p) {
    return {
      'patientId': p.patientId,
      'dietitianId': p.dietitianId,
      'weekStartDate': p.weekStartDate.millisecondsSinceEpoch,
      'weekEndDate': p.weekEndDate.millisecondsSinceEpoch,
      'title': p.title,
      'createdAt': p.createdAt.millisecondsSinceEpoch,
      'dailyPlans': p.dailyPlans.map((d) => {
        'dayName': d.dayName,
        'breakfast': {'name': d.breakfast.name, 'description': d.breakfast.description},
        'lunch': {'name': d.lunch.name, 'description': d.lunch.description},
        'dinner': {'name': d.dinner.name, 'description': d.dinner.description},
        'snack': d.snack != null
            ? {'name': d.snack!.name, 'description': d.snack!.description}
            : null,
      }).toList(),
    };
  }

  DietPlanModel _fromMap(String key, Map<String, dynamic> data) {
    // RTDB may return arrays as List or as Map with integer keys
    final rawPlans = data['dailyPlans'];
    List<dynamic> dailyPlansRaw;
    if (rawPlans is List) {
      dailyPlansRaw = rawPlans;
    } else if (rawPlans is Map) {
      final sorted = Map<int, dynamic>.from(rawPlans)
          .entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      dailyPlansRaw = sorted.map((e) => e.value).toList();
    } else {
      dailyPlansRaw = [];
    }

    return DietPlanModel(
      id: key,
      patientId: data['patientId'] as String,
      dietitianId: data['dietitianId'] as String,
      weekStartDate: DateTime.fromMillisecondsSinceEpoch(data['weekStartDate'] as int),
      weekEndDate: DateTime.fromMillisecondsSinceEpoch(data['weekEndDate'] as int),
      title: data['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      dailyPlans: dailyPlansRaw.map((raw) {
        final d = Map<String, dynamic>.from(raw as Map);
        return DailyMealPlan(
          dayName: d['dayName'] as String,
          breakfast: _mealFromMap(d['breakfast']),
          lunch: _mealFromMap(d['lunch']),
          dinner: _mealFromMap(d['dinner']),
          snack: d['snack'] != null ? _mealFromMap(d['snack']) : null,
        );
      }).toList(),
    );
  }

  MealDetail _mealFromMap(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    return MealDetail(
      name: m['name'] as String? ?? '',
      description: m['description'] as String? ?? '',
    );
  }
}
