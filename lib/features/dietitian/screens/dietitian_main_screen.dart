import 'package:flutter/material.dart';
import 'dietitian_home_screen.dart';
import 'appointment_requests_screen.dart';
import 'daily_program_screen.dart';
import '../../profile/screens/profile_screen.dart';

class DietitianMainScreen extends StatefulWidget {
  const DietitianMainScreen({super.key});

  @override
  State<DietitianMainScreen> createState() => _DietitianMainScreenState();
}

class _DietitianMainScreenState extends State<DietitianMainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DietitianHomeScreen(),
    DailyProgramScreen(),
    AppointmentRequestsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'My Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
