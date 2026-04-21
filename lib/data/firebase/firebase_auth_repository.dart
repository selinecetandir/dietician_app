import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/dietitian_model.dart';
import '../models/admin_model.dart';
import '../repositories/auth_repository.dart';
import '../../core/enums/enums.dart';
import 'firebase_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  final _service = FirebaseService();
  UserModel? _cachedUser;

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _service.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) return null;

      final snap = await _service.usersRef.child(credential.user!.uid).get();
      if (!snap.exists || snap.value == null) return null;

      _cachedUser = _userFromSnapshot(credential.user!.uid, snap.value!);
      return _cachedUser;
    } on FirebaseAuthException {
      return null;
    }
  }

  @override
  Future<UserModel> register({
    required UserModel user,
    required String password,
  }) async {
    final credential = await _service.auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    final uid = credential.user!.uid;
    final data = _userToMap(user);

    await _service.usersRef.child(uid).set(data);

    final registeredUser = _createUserWithId(user, uid);

    await _service.auth.signOut();
    _cachedUser = null;

    return registeredUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _service.auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> logout() async {
    await _service.auth.signOut();
    _cachedUser = null;
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final user = _cachedUser;
    if (user == null) return;
    await _service.usersRef.child(user.id).update(updates);
    final snap = await _service.usersRef.child(user.id).get();
    if (snap.exists && snap.value != null) {
      _cachedUser = _userFromSnapshot(user.id, snap.value!);
    }
  }

  Future<UserModel?> tryAutoLogin() async {
    final firebaseUser = _service.auth.currentUser;
    if (firebaseUser == null) return null;

    final snap = await _service.usersRef.child(firebaseUser.uid).get();
    if (!snap.exists || snap.value == null) return null;

    _cachedUser = _userFromSnapshot(firebaseUser.uid, snap.value!);
    return _cachedUser;
  }

  Map<String, dynamic> _userToMap(UserModel user) {
    final map = <String, dynamic>{
      'email': user.email,
      'name': user.name,
      'role': user.role.name,
      'createdAt': user.createdAt.millisecondsSinceEpoch,
    };

    if (user is PatientModel) {
      map.addAll({
        'phone': user.phone,
        'gender': user.gender.name,
        'weight': user.weight,
        'height': user.height,
        'goal': user.goal.name,
        'birthDate': user.birthDate.millisecondsSinceEpoch,
        'allergies': user.allergies ?? '',
        'healthCondition': user.healthCondition ?? '',
      });
    } else if (user is DietitianModel) {
      map.addAll({
        'title': user.title,
        'clinicName': user.clinicName,
        'specialization': user.specialization,
        'education': user.education ?? '',
        'certificates': user.certificates ?? '',
      });
    }

    return map;
  }

  UserModel _userFromSnapshot(String uid, Object rawData) {
    final data = Map<String, dynamic>.from(rawData as Map);
    final role = UserRole.values.byName(data['role'] as String);

    if (role == UserRole.admin) {
      return AdminModel(
        id: uid,
        email: data['email'] as String? ?? '',
        name: data['name'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          data['createdAt'] as int? ?? 0,
        ),
      );
    }

    if (role == UserRole.patient) {
      return PatientModel(
        id: uid,
        email: data['email'] as String? ?? '',
        name: data['name'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          data['createdAt'] as int? ?? 0,
        ),
        phone: data['phone'] as String? ?? '',
        gender: Gender.values.byName(data['gender'] as String? ?? 'male'),
        weight: (data['weight'] as num?)?.toDouble() ?? 0,
        height: (data['height'] as num?)?.toDouble() ?? 0,
        goal: PatientGoal.values.byName(
          data['goal'] as String? ?? 'stayHealthy',
        ),
        birthDate: DateTime.fromMillisecondsSinceEpoch(
          data['birthDate'] as int? ?? 0,
        ),
        allergies: _nullIfEmpty(data['allergies']),
        healthCondition: _nullIfEmpty(data['healthCondition']),
      );
    } else {
      return DietitianModel(
        id: uid,
        email: data['email'] as String? ?? '',
        name: data['name'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          data['createdAt'] as int? ?? 0,
        ),
        title: data['title'] as String? ?? '',
        clinicName: data['clinicName'] as String? ?? '',
        specialization: data['specialization'] as String? ?? '',
        education: _nullIfEmpty(data['education']),
        certificates: _nullIfEmpty(data['certificates']),
      );
    }
  }

  String? _nullIfEmpty(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  UserModel _createUserWithId(UserModel user, String uid) {
    if (user is AdminModel) {
      return AdminModel(
        id: uid,
        email: user.email,
        name: user.name,
        createdAt: user.createdAt,
      );
    }
    if (user is PatientModel) {
      return PatientModel(
        id: uid,
        email: user.email,
        name: user.name,
        createdAt: user.createdAt,
        phone: user.phone,
        gender: user.gender,
        weight: user.weight,
        height: user.height,
        goal: user.goal,
        birthDate: user.birthDate,
        allergies: user.allergies,
        healthCondition: user.healthCondition,
      );
    } else if (user is DietitianModel) {
      return DietitianModel(
        id: uid,
        email: user.email,
        name: user.name,
        createdAt: user.createdAt,
        title: user.title,
        clinicName: user.clinicName,
        specialization: user.specialization,
        education: user.education,
        certificates: user.certificates,
      );
    }
    return user;
  }
}
