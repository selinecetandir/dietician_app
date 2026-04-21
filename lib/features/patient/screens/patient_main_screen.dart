import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repository_locator.dart';
import 'patient_home_screen.dart';
import 'dietitian_list_screen.dart';
import 'my_appointments_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSub;

  final _screens = const [
    PatientHomeScreen(),
    DietitianListScreen(),
    MyAppointmentsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  static const int _notificationsTabIndex = 3;

  @override
  void initState() {
    super.initState();
    final user = RepositoryLocator.auth.currentUser;
    if (user != null) {
      _unreadSub = RepositoryLocator.notification
          .streamUnreadCount(user.id)
          .listen((count) {
        if (mounted) setState(() => _unreadCount = count);
      });
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  void _onTabSelected(int i) {
    setState(() => _currentIndex = i);
    if (i == _notificationsTabIndex) {
      final user = RepositoryLocator.auth.currentUser;
      if (user != null && _unreadCount > 0) {
        RepositoryLocator.notification.markAllAsRead(user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Dietitians',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'My Appointments',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_none),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifications',
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
