import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'page_transitions.dart';
// Screens for auth and role-based navigation
import '../../screens/auth/login_screen.dart'; 
import '../../screens/auth/web_only_screen.dart';
// Driver screens
import '../../screens/driver/driver_home_screen.dart';
import '../../screens/driver/driver_today_screen.dart';
import '../../screens/driver/driver_trip_list_screen.dart';
import '../../screens/driver/driver_trip_detail_screen.dart';
import '../../screens/driver/driver_expense_list_screen.dart';
import '../../screens/driver/driver_expense_trips_screen.dart';
import '../../screens/driver/driver_checklist_screen.dart';
import '../../screens/driver/driver_documents_screen.dart';
import '../../screens/driver/driver_vehicle_screen.dart';
import '../../screens/driver/driver_notifications_screen.dart';
import '../../screens/driver/driver_add_expense_screen.dart';
import '../../screens/driver/driver_profile_screen.dart';
import '../../screens/driver/driver_gps_tracking_screen.dart';
import '../../screens/driver/driver_epod_screen.dart';
// Fleet Manager screens
import '../../screens/fleet/fleet_home_screen.dart';
import '../../screens/fleet/fleet_vehicles_screen.dart';
import '../../screens/fleet/fleet_analytics_screen.dart';
import '../../screens/fleet/fleet_driver_list_screen.dart';
import '../../screens/fleet/fleet_trip_management_screen.dart';
import '../../screens/fleet/fleet_profile_screen.dart';
import '../../screens/fleet/fleet_add_vehicle_screen.dart';
import '../../screens/fleet/fleet_edit_vehicle_screen.dart';
import '../../screens/fleet/fleet_driver_detail_screen.dart';
import '../../screens/fleet/fleet_add_driver_screen.dart';
import '../../screens/fleet/fleet_create_trip_screen.dart';
// Accountant screens
import '../../screens/accountant/accountant_home_screen.dart';
import '../../screens/accountant/accountant_shell_screen.dart';
import '../../screens/accountant/accountant_more_screen.dart';
import '../../screens/accountant/accountant_invoices_screen.dart';
import '../../screens/accountant/accountant_invoice_detail_screen.dart';
import '../../screens/accountant/accountant_payments_screen.dart';
import '../../screens/accountant/accountant_receivables_screen.dart';
import '../../screens/accountant/accountant_payables_screen.dart';
import '../../screens/accountant/accountant_ledger_screen.dart';
import '../../screens/accountant/accountant_gst_screen.dart';
import '../../screens/accountant/accountant_vouchers_screen.dart';
import '../../screens/accountant/accountant_statements_screen.dart';
import '../../screens/accountant/accountant_expense_approval_screen.dart';
import '../../screens/accountant/accountant_settlement_screen.dart';
import '../../screens/accountant/accountant_banking_screen.dart';
// Driver settlement
import '../../screens/driver/driver_settlement_screen.dart';
// Pump Shift screen
import '../../screens/pump/pump_shift_screen.dart';
// Branch Manager screens
import '../../screens/branch/branch_home_screen.dart';
import '../../screens/branch/branch_dashboard_screen.dart';
import '../../screens/branch/branch_trips_screen.dart';
import '../../screens/branch/branch_drivers_screen.dart';
import '../../screens/branch/branch_reports_screen.dart';
// Project Associate screens
import '../../screens/associate/associate_home_screen.dart';
// Admin screens
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_fleet_screen.dart';
import '../../screens/admin/admin_team_screen.dart';
import '../../screens/admin/admin_alerts_screen.dart';
import '../../screens/admin/admin_finance_screen.dart';
// Pump Operator screens
import '../../screens/pump/pump_home_screen.dart';
import '../../screens/pump/pump_dashboard_screen.dart';
import '../../screens/pump/pump_fuel_log_screen.dart';
import '../../screens/pump/pump_dispense_screen.dart';
import '../../screens/pump/pump_reports_screen.dart';
import '../../screens/pump/pump_tank_refill_screen.dart';
import '../../screens/pump/pump_create_tank_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  const storage = FlutterSecureStorage();

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) async {
      final token = await storage.read(key: 'access_token');
      final role = await storage.read(key: 'primary_role');
      final isLoginPage = state.matchedLocation == '/login';

      if (token == null && !isLoginPage) {
        return '/login';
      }
      
      if (token != null && isLoginPage) {
        // Redirect to correct home for this role
        switch (role) {
          case 'driver': return '/driver/today';
          case 'fleet_manager': return '/fleet/home';
          case 'accountant': return '/accountant/home';
          case 'project_associate': return '/associate/home';
          case 'admin':
          case 'super_admin': return '/admin/home';
          case 'pump_operator': return '/pump/home';
          case 'branch_manager': return '/branch/home';
          default: return '/web-only';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => PageTransitionPreset.standard(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/web-only',
        pageBuilder: (context, state) => PageTransitionPreset.standard(
          context: context,
          state: state,
          child: const WebOnlyScreen(),
        ),
      ),
      
      // --- DRIVER ROUTES --- (Stateful shell with bottom nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => DriverHomeScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/driver/today',
              pageBuilder: (context, state) => PageTransitionPreset.fast(
                context: context,
                state: state,
                child: const DriverTodayScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/driver/trips',
              pageBuilder: (context, state) => PageTransitionPreset.fast(
                context: context,
                state: state,
                child: const DriverTripListScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/driver/expenses',
              pageBuilder: (context, state) => PageTransitionPreset.fast(
                context: context,
                state: state,
                child: const DriverExpenseTripsScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/driver/profile',
              pageBuilder: (context, state) => PageTransitionPreset.fast(
                context: context,
                state: state,
                child: const DriverProfileScreen(),
              ),
            ),
          ]),
        ],
      ),
      
      // Driver modal routes (outside shell)
      GoRoute(
        path: '/driver/expenses/:tripId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final tripId = int.parse(state.pathParameters['tripId'] ?? '0');
          final tripNumber = state.uri.queryParameters['trip'] ?? '';
          return PageTransitionPreset.modal(
            context: context,
            state: state,
            child: DriverExpenseListScreen(tripId: tripId, tripNumber: tripNumber.isNotEmpty ? tripNumber : null),
          );
        },
      ),
      GoRoute(
        path: '/driver/add-expense',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: const DriverAddExpenseScreen(),
        ),
      ),
      GoRoute(
        path: '/driver/trip/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: DriverTripDetailScreen(tripId: int.parse(state.pathParameters['id'] ?? '0')),
        ),
      ),
      GoRoute(
        path: '/driver/trip/:id/epod',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: DriverEpodScreen(tripId: int.parse(state.pathParameters['id'] ?? '0')),
        ),
      ),
      GoRoute(
        path: '/driver/tracking/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: DriverGpsTrackingScreen(tripId: int.parse(state.pathParameters['id'] ?? '0')),
        ),
      ),
      GoRoute(
        path: '/driver/checklist',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: const DriverChecklistScreen(),
        ),
      ),
      GoRoute(
        path: '/driver/vehicle',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: const DriverVehicleScreen(),
        ),
      ),
      GoRoute(
        path: '/driver/documents',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: const DriverDocumentsScreen(),
        ),
      ),
      GoRoute(
        path: '/driver/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => PageTransitionPreset.modal(
          context: context,
          state: state,
          child: const DriverNotificationsScreen(),
        ),
      ),
      
      // --- Fleet Routes ---
      GoRoute(path: '/fleet/home', builder: (context, state) => const FleetHomeScreen()),
      GoRoute(path: '/fleet/vehicles', builder: (context, state) => const FleetVehiclesScreen()),
      GoRoute(path: '/fleet/analytics', builder: (context, state) => const FleetAnalyticsScreen()),
      GoRoute(path: '/fleet/map', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/fleet/drivers', builder: (context, state) => const FleetDriverListScreen()),
      GoRoute(path: '/fleet/trips', builder: (context, state) => const FleetTripManagementScreen()),
      GoRoute(path: '/fleet/profile', builder: (context, state) => const FleetProfileScreen()),
      GoRoute(path: '/fleet/vehicle/add', builder: (context, state) => const FleetAddVehicleScreen()),
      GoRoute(
        path: '/fleet/vehicle/:id/edit',
        builder: (context, state) => FleetEditVehicleScreen(
          vehicleId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/fleet/vehicle/:id',
        builder: (context, state) => FleetEditVehicleScreen(
          vehicleId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/fleet/driver/add', builder: (context, state) => const FleetAddDriverScreen()),
      GoRoute(
        path: '/fleet/driver/:id',
        builder: (context, state) => FleetDriverDetailScreen(
          driverId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/fleet/trip/create', builder: (context, state) => const FleetCreateTripScreen()),
      GoRoute(path: '/fleet/expenses', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/fleet/service/new', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/fleet/tyre/new', builder: (context, state) => const Scaffold()),
      
      // --- Accountant Routes --- (Stateful shell with bottom nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AccountantShellScreen(navigationShell: navigationShell),
        branches: [
          // index 0 → Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/accountant/home',
              builder: (context, state) => const AccountantHomeScreen(),
            ),
          ]),
          // index 1 → Invoices
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/accountant/invoices',
              builder: (context, state) => const AccountantInvoicesScreen(),
            ),
          ]),
          // index 2 → Ledger
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/accountant/ledger',
              builder: (context, state) => const AccountantLedgerScreen(),
            ),
          ]),
          // index 3 → Statements / Reports
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/accountant/statements',
              builder: (context, state) => const AccountantStatementsScreen(),
            ),
          ]),
          // index 4 → More
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/accountant/more',
              builder: (context, state) => const AccountantMoreScreen(),
            ),
          ]),
        ],
      ),
      // Accountant modal / detail routes (outside shell)
      GoRoute(
        path: '/accountant/invoice/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AccountantInvoiceDetailScreen(
          id: state.pathParameters['id'] ?? '0',
        ),
      ),
      GoRoute(
        path: '/accountant/payments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantPaymentsScreen(),
      ),
      GoRoute(
        path: '/accountant/receivables',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantReceivablesScreen(),
      ),
      GoRoute(
        path: '/accountant/payables',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantPayablesScreen(),
      ),
      GoRoute(
        path: '/accountant/gst',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantGSTScreen(),
      ),
      GoRoute(
        path: '/accountant/vouchers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantVouchersScreen(),
      ),
      GoRoute(
        path: '/accountant/approvals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantExpenseApprovalScreen(),
      ),
      GoRoute(
        path: '/accountant/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantExpenseApprovalScreen(),
      ),
      GoRoute(
        path: '/accountant/settlements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantSettlementScreen(),
      ),
      GoRoute(
        path: '/accountant/banking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountantBankingScreen(),
      ),
      
      // --- Associate Routes ---
      GoRoute(path: '/associate/home', builder: (context, state) => const AssociateHomeScreen()),
      GoRoute(path: '/associate/jobs', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/associate/lr/create', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/associate/lr/list', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/associate/ewb/create', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/associate/trip/close', builder: (context, state) => const Scaffold()),
      GoRoute(path: '/associate/upload', builder: (context, state) => const Scaffold()),

      // --- Admin Routes --- (Stateful shell with bottom nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdminHomeScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/home', builder: (context, state) => const AdminDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/fleet', builder: (context, state) => const AdminFleetScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/team', builder: (context, state) => const AdminTeamScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/finance', builder: (context, state) => const AdminFinanceScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/admin/alerts', builder: (context, state) => const AdminAlertsScreen()),
          ]),
        ],
      ),

      // --- Pump Operator Routes --- (Stateful shell with bottom nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => PumpHomeScreen(navigationShell: navigationShell),
        branches: [
          // index 0 → Dashboard
          StatefulShellBranch(routes: [
            GoRoute(path: '/pump/home', builder: (context, state) => const PumpDashboardScreen()),
          ]),
          // index 1 → Dispense (was wrongly index 2)
          StatefulShellBranch(routes: [
            GoRoute(path: '/pump/dispense', builder: (context, state) => const PumpDispenseScreen()),
          ]),
          // index 2 → Log (was wrongly index 1)
          StatefulShellBranch(routes: [
            GoRoute(path: '/pump/log', builder: (context, state) => const PumpFuelLogScreen()),
          ]),
          // index 3 → Reports (new)
          StatefulShellBranch(routes: [
            GoRoute(path: '/pump/reports', builder: (context, state) => const PumpReportsScreen()),
          ]),
        ],
      ),
      // Standalone pump screens (no bottom nav)
      GoRoute(
        path: '/pump/shift',
        builder: (context, state) => const PumpShiftScreen(),
      ),
      GoRoute(
        path: '/pump/refill',
        builder: (context, state) => const PumpTankRefillScreen(),
      ),
      // Standalone create tank screen (no bottom nav)
      GoRoute(
        path: '/pump/create-tank',
        builder: (context, state) => const PumpCreateTankScreen(),
      ),

      // Driver settlement (standalone, no shell)
      GoRoute(
        path: '/driver/settlement',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DriverSettlementScreen(),
      ),

      // --- Branch Manager Routes --- (Stateful shell with bottom nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BranchHomeScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch/home', builder: (context, state) => const BranchDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch/trips', builder: (context, state) => const BranchTripsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch/drivers', builder: (context, state) => const BranchDriversScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch/reports', builder: (context, state) => const BranchReportsScreen()),
          ]),
        ],
      ),
    ],
  );
});