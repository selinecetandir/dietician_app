class MealDetail {
  final String name;
  final String description;

  const MealDetail({required this.name, required this.description});
}

class DailyMealPlan {
  final String dayName;
  final MealDetail breakfast;
  final MealDetail lunch;
  final MealDetail dinner;
  final MealDetail? snack;

  const DailyMealPlan({
    required this.dayName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.snack,
  });
}

class DietPlanModel {
  final String id;
  final String patientId;
  final String dietitianId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final String title;
  final List<DailyMealPlan> dailyPlans;
  final DateTime createdAt;

  const DietPlanModel({
    required this.id,
    required this.patientId,
    required this.dietitianId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.title,
    required this.dailyPlans,
    required this.createdAt,
  });
}
