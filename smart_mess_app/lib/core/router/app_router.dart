// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/attendance/presentation/qr_scanner_screen.dart';
import '../../features/attendance/presentation/meal_history_screen.dart';
import '../../features/billing/presentation/bill_screen.dart';
import '../../features/complaints/presentation/complaints_screen.dart';
import '../../features/complaints/presentation/submit_complaint_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/mess_off/presentation/mess_off_screen.dart';
import '../../features/orders/presentation/food_order_screen.dart';

// Manager Screens
import '../../features/manager/presentation/manager_dashboard_screen.dart';
import '../../features/manager/presentation/manager_qr_screen.dart';
import '../../features/manager/presentation/manager_wastage_screen.dart';
import '../../features/manager/presentation/manager_attendance_screen.dart';
import '../../features/manager/presentation/manager_meals_screen.dart';
import '../../features/manager/presentation/manager_mess_offs_screen.dart';
import '../../features/manager/presentation/manager_complaints_screen.dart';
import '../../features/manager/presentation/manager_broadcast_screen.dart';
import '../../features/manager/presentation/manager_orders_screen.dart';

import '../constants/h4_students_data.dart';
import '../widgets/top_notification_overlay.dart';

final authStateProvider = StateProvider<bool>((ref) => false);
final userRoleProvider = StateProvider<String>((ref) => 'student'); // 'student' or 'manager'
final currentStudentProvider = StateProvider<H4Student>((ref) => H4StudentDirectory.students[0]);

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuth = ref.watch(authStateProvider);
  final role = ref.watch(userRoleProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggingIn = state.uri.toString() == '/login';
      if (!isAuth && !loggingIn) return '/login';
      if (isAuth && loggingIn) {
        return role == 'manager' ? '/manager-dashboard' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      
      // Student Routes
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/scanner', builder: (context, state) => const QRScannerScreen()),
      GoRoute(path: '/mess-off', builder: (context, state) => const MessOffScreen()),
      GoRoute(path: '/meal-history', builder: (context, state) => const MealHistoryScreen()),
      GoRoute(path: '/bill', builder: (context, state) => const BillScreen()),
      GoRoute(path: '/order-food', builder: (context, state) => const FoodOrderScreen()),
      GoRoute(path: '/complaints', builder: (context, state) => const ComplaintsScreen(),
        routes: [
          GoRoute(path: 'submit', builder: (context, state) => const SubmitComplaintScreen()),
        ],
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),

      // Complete Manager Routes (Mirrors Web Version)
      GoRoute(path: '/manager-dashboard', builder: (context, state) => const ManagerDashboardScreen()),
      GoRoute(path: '/manager/qr-generate', builder: (context, state) => const ManagerQRScreen()),
      GoRoute(path: '/manager/attendance', builder: (context, state) => const ManagerAttendanceScreen()),
      GoRoute(path: '/manager/meals', builder: (context, state) => const ManagerMealsScreen()),
      GoRoute(path: '/manager/mess-offs', builder: (context, state) => const ManagerMessOffsScreen()),
      GoRoute(path: '/manager/wastage', builder: (context, state) => const ManagerWastageScreen()),
      GoRoute(path: '/manager/complaints', builder: (context, state) => const ManagerComplaintsScreen()),
      GoRoute(path: '/manager/broadcast', builder: (context, state) => const ManagerBroadcastScreen()),
      GoRoute(path: '/manager/orders', builder: (context, state) => const ManagerOrdersScreen()),
    ],
  );
});
