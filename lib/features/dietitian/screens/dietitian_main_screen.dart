import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';
import '../../../data/repository_locator.dart';
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
  int _pendingCount = 0;

  final _screens = const [
    DietitianHomeScreen(),
    DailyProgramScreen(),
    AppointmentRequestsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;
    final all = await RepositoryLocator.appointment
        .getAppointmentsForDietitian(user.id);
    final pending =
        all.where((a) => a.status == AppointmentStatus.pending).length;
    if (mounted) setState(() => _pendingCount = pending);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          _loadPendingCount();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'My Patients',
          ),
          const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendingCount > 0,
              label: Text('$_pendingCount'),
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _pendingCount > 0,
              label: Text('$_pendingCount'),
              child: const Icon(Icons.inbox),
            ),
            label: 'Requests',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
