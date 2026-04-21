import 'firebase/firebase_auth_repository.dart';
import 'firebase/firebase_appointment_repository.dart';
import 'firebase/firebase_dietitian_repository.dart';
import 'firebase/firebase_diet_plan_repository.dart';
import 'firebase/firebase_weight_repository.dart';
import 'firebase/firebase_notification_repository.dart';
import 'firebase/firebase_blood_test_repository.dart';
import 'firebase/firebase_admin_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/appointment_repository.dart';
import 'repositories/dietitian_repository.dart';

/// Central place to get repository instances.
/// Switch between Mock and Firebase by changing the implementations here.
class RepositoryLocator {
  RepositoryLocator._();

  static final AuthRepository auth = FirebaseAuthRepository();
  static final AppointmentRepository appointment =
      FirebaseAppointmentRepository();
  static final DietitianRepository dietitian = FirebaseDietitianRepository();
  static final FirebaseDietPlanRepository dietPlan =
      FirebaseDietPlanRepository();
  static final FirebaseWeightRepository weight = FirebaseWeightRepository();
  static final FirebaseNotificationRepository notification =
      FirebaseNotificationRepository();
  static final FirebaseBloodTestRepository bloodTest =
      FirebaseBloodTestRepository();
  static final FirebaseAdminRepository admin = FirebaseAdminRepository();

  // Typed accessors for Firebase-specific methods
  static FirebaseAuthRepository get firebaseAuth =>
      auth as FirebaseAuthRepository;
  static FirebaseAppointmentRepository get firebaseAppointment =>
      appointment as FirebaseAppointmentRepository;
  static FirebaseDietitianRepository get firebaseDietitian =>
      dietitian as FirebaseDietitianRepository;
}
