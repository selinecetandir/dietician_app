import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';
import '../../../data/repository_locator.dart';
import 'dietitian_home_screen.dart';
import 'appointment_requests_screen.dart';
import 'daily_program_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';

class DietitianMainScreen extends StatefulWidget {
  const DietitianMainScreen({super.key});

  @override
  State<DietitianMainScreen> createState() => _DietitianMainScreenState();
}

class _DietitianMainScreenState extends State<DietitianMainScreen> {
  int _currentIndex = 0;
  int _pendingCount = 0;
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSub;

  final _screens = const [
    DietitianHomeScreen(),
    DailyProgramScreen(),
    AppointmentRequestsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  static const int _notificationsTabIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
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

  Future<void> _loadPendingCount() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;
    final all = await RepositoryLocator.appointment
        .getAppointmentsForDietitian(user.id);
    final pending =
        all.where((a) => a.status == AppointmentStatus.pending).length;
    if (mounted) setState(() => _pendingCount = pending);
  }

  void _onTabSelected(int i) {
    setState(() => _currentIndex = i);
    _loadPendingCount();
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
