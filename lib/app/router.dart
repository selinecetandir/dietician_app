import 'package:flutter/material.dart';
import '../core/enums/enums.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/patient/screens/patient_main_screen.dart';
import '../features/patient/screens/dietitian_detail_screen.dart';
import '../features/patient/screens/book_appointment_screen.dart';
import '../features/dietitian/screens/dietitian_main_screen.dart';
import '../features/dietitian/screens/schedule_management_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String patientHome = '/patient';
  static const String dietitianDetail = '/patient/dietitian-detail';
  static const String bookAppointment = '/patient/book-appointment';
  static const String dietitianHome = '/dietitian';
  static const String scheduleManagement = '/dietitian/schedule';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return _page(const SplashScreen());

    case AppRoutes.login:
      final role = settings.arguments as UserRole;
      return _page(LoginScreen(role: role));

    case AppRoutes.register:
      final role = settings.arguments as UserRole;
      return _page(RegisterScreen(role: role));

    case AppRoutes.patientHome:
      return _page(const PatientMainScreen());

    case AppRoutes.dietitianDetail:
      final id = settings.arguments as String;
      return _page(DietitianDetailScreen(dietitianId: id));

    case AppRoutes.bookAppointment:
      final id = settings.arguments as String;
      return _page(BookAppointmentScreen(dietitianId: id));

    case AppRoutes.dietitianHome:
      return _page(const DietitianMainScreen());

    case AppRoutes.scheduleManagement:
      return _page(const ScheduleManagementScreen());

    default:
      return _page(const SplashScreen());
  }
}

MaterialPageRoute<dynamic> _page(Widget child) {
  return MaterialPageRoute(builder: (_) => child);
}
