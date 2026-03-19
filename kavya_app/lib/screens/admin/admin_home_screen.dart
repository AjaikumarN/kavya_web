import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../core/widgets/offline_banner.dart';

/// Admin shell — deep navy command center with bottom navigation.
class AdminHomeScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminHomeScreen({super.key, required this.navigationShell});

  // Navy palette per spec
  static const _navyDark = Color(0xFF0F172A);
  static const _navySurface = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: _navyDark,
      appBar: AppBar(
        backgroundColor: _navySurface,
        foregroundColor: Colors.white,
        title: Text('Hi, ${user?.fullName ?? 'Admin'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/admin/alerts'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('My Profile')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline) const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _navySurface,
        indicatorColor: const Color(0xFFF59E0B).withAlpha(30),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFF59E0B)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.local_shipping, color: Color(0xFFF59E0B)),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFFF59E0B)),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.people, color: Color(0xFFF59E0B)),
            label: 'Team',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
