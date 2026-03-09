import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';
import '../core/constants/app_constants.dart';

class DieticianApp extends StatelessWidget {
  const DieticianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
