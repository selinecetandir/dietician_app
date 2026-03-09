import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'mock_database.dart';

class MockAuthRepository implements AuthRepository {
  final MockDatabase _db = MockDatabase();

  @override
  UserModel? get currentUser => _db.currentUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _db.findUserByEmail(email);
    if (user == null) return null;
    if (!_db.checkPassword(user.id, password)) return null;
    _db.currentUser = user;
    return user;
  }

  @override
  Future<UserModel> register({
    required UserModel user,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_db.findUserByEmail(user.email) != null) {
      throw Exception('This email is already registered.');
    }
    _db.addUser(user, password);
    _db.currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _db.currentUser = null;
  }
}
