import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

// ── Driver screens (existing) ──
import '../../screens/home_screen.dart';
import '../../screens/today_screen.dart';
import '../../screens/trip_list_screen.dart';
import '../../screens/trip_detail_screen.dart';
import '../../screens/expense_list_screen.dart';
import '../../screens/add_expense_screen.dart';
import '../../screens/checklist_screen.dart';
import '../../screens/documents_screen.dart';
import '../../screens/notifications_screen.dart';

// ── New screens ──
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/web_only_screen.dart';
import '../../screens/fleet_manager/fleet_home_screen.dart';
import '../../screens/fleet_manager/fleet_live_map_screen.dart';
import '../../screens/fleet_manager/fleet_vehicle_list_screen.dart';
import '../../screens/fleet_manager/fleet_vehicle_detail_screen.dart';
import '../../screens/fleet_manager/fleet_expense_approval_screen.dart';
import '../../screens/fleet_manager/fleet_service_log_screen.dart';
import '../../screens/fleet_manager/fleet_tyre_event_screen.dart';
import '../../screens/accountant/accountant_home_screen.dart';
import '../../screens/accountant/accountant_receivables_screen.dart';
import '../../screens/accountant/accountant_invoices_screen.dart';
import '../../screens/accountant/accountant_invoice_detail_screen.dart';
import '../../screens/accountant/accountant_expense_approval_screen.dart';
import '../../screens/accountant/accountant_payments_screen.dart';
import '../../screens/associate/associate_home_screen.dart';
import '../../screens/associate/associate_job_list_screen.dart';
import '../../screens/associate/associate_lr_create_screen.dart';
import '../../screens/associate/associate_ewb_create_screen.dart';
import '../../screens/associate/associate_trip_close_screen.dart';
import '../../screens/associate/associate_doc_upload_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/notifications/notification_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isOnLogin = location == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) {
        return AuthService.homeRouteForRole(user.primaryRole);
      }
      return null;
    },
    routes: [
      // ── Auth ──
      GoRoute(
        path: '/login',
        builder: (_, __) => const KTLoginScreen(),
      ),
      GoRoute(
        path: '/web-only',
        builder: (_, __) => const WebOnlyScreen(),
      ),

      // ── Driver flow (existing — unchanged) ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/trips', builder: (_, __) => const TripListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/expenses', builder: (_, __) => const ExpenseListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/driver-profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/trips/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => TripDetailScreen(
          tripId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/expenses/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/checklist',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ChecklistScreen(),
      ),
      GoRoute(
        path: '/documents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Fleet Manager flow ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            FleetShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/fleet/home', builder: (_, __) => const FleetHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/fleet/map', builder: (_, __) => const FleetLiveMapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/fleet/vehicles', builder: (_, __) => const FleetVehicleListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/fleet/expenses', builder: (_, __) => const FleetExpenseApprovalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/fleet/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/fleet/vehicle/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => FleetVehicleDetailScreen(
          vehicleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/fleet/service/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const FleetServiceLogScreen(),
      ),
      GoRoute(
        path: '/fleet/tyre/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const FleetTyreEventScreen(),
      ),

      // ── Accountant flow ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AccountantShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/accountant/home', builder: (_, __) => const AccountantHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/accountant/receivables', builder: (_, __) => const AccountantReceivablesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/accountant/invoices', builder: (_, __) => const AccountantInvoicesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/accountant/expenses', builder: (_, __) => const AccountantExpenseApprovalScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/accountant/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/accountant/invoice/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => AccountantInvoiceDetailScreen(
          invoiceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/accountant/payments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AccountantPaymentsScreen(),
      ),

      // ── Project Associate flow ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AssociateShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/associate/home', builder: (_, __) => const AssociateHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/associate/jobs', builder: (_, __) => const AssociateJobListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/associate/lr/list', builder: (_, __) => const AssociateLRCreateScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/associate/upload', builder: (_, __) => const AssociateDocUploadScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/associate/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/associate/lr/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => AssociateLRCreateScreen(
          jobId: state.uri.queryParameters['job_id'],
        ),
      ),
      GoRoute(
        path: '/associate/ewb/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => AssociateEWBCreateScreen(
          lrId: state.uri.queryParameters['lr_id'],
        ),
      ),
      GoRoute(
        path: '/associate/trip/close',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AssociateTripCloseScreen(),
      ),

      // ── Shared ──
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notification-list',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NotificationListScreen(),
      ),
    ],
  );
});

// ── Shell screens for bottom navigation ──

class FleetShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const FleetShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        indicatorColor: const Color(0xFF1B5E20).withValues(alpha: 0.12),
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AccountantShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AccountantShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        indicatorColor: const Color(0xFFF57F17).withValues(alpha: 0.12),
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Receivables'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Invoices'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AssociateShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AssociateShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        indicatorColor: const Color(0xFF4A148C).withValues(alpha: 0.12),
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article), label: 'LR'),
          NavigationDestination(icon: Icon(Icons.upload_file_outlined), selectedIcon: Icon(Icons.upload_file), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
