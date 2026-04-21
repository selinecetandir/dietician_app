import 'user_model.dart';
import '../../core/enums/enums.dart';

class AdminModel extends UserModel {
  const AdminModel({
    required super.id,
    required super.email,
    required super.name,
    required super.createdAt,
    super.isActive,
  }) : super(role: UserRole.admin);
}
