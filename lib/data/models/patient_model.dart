import 'user_model.dart';
import '../../core/enums/enums.dart';

class PatientModel extends UserModel {
  final String phone;
  final Gender gender;
  final double weight;
  final double height;
  final PatientGoal goal;
  final String? allergies;
  final String? healthCondition;
  final DateTime birthDate;

  const PatientModel({
    required super.id,
    required super.email,
    required super.name,
    required super.createdAt,
    required this.phone,
    required this.gender,
    required this.weight,
    required this.height,
    required this.goal,
    required this.birthDate,
    this.allergies,
    this.healthCondition,
    super.isActive,
  }) : super(role: UserRole.patient);

  int get age {
    final now = DateTime.now();
    int a = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      a--;
    }
    return a;
  }

  double get bmi {
    if (height <= 0) return 0;
    final h = height / 100.0;
    return weight / (h * h);
  }
}
