import 'user_model.dart';
import '../../core/enums/enums.dart';

class DietitianModel extends UserModel {
  final String title;
  final String clinicName;
  final String specialization;

  const DietitianModel({
    required super.id,
    required super.email,
    required super.name,
    required super.createdAt,
    required this.title,
    required this.clinicName,
    required this.specialization,
  }) : super(role: UserRole.dietitian);
}
