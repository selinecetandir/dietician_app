import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._();
  factory FirebaseService() => _instance;
  FirebaseService._();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;

  DatabaseReference get usersRef => database.ref('users');
  DatabaseReference get appointmentsRef => database.ref('appointments');
  DatabaseReference get timeSlotsRef => database.ref('timeSlots');
  DatabaseReference get dietPlansRef => database.ref('dietPlans');
  DatabaseReference get weightEntriesRef => database.ref('weightEntries');
  DatabaseReference get notificationsRef => database.ref('notifications');
}
