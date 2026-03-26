import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String email, String password);
  Future<UserModel> register({
    required UserModel user,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logout();
  UserModel? get currentUser;
}
