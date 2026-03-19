import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../core/widgets/offline_banner.dart';

/// Pump Operator shell — dark slate with amber accents.
/// Industrial, functional, high contrast for outdoor/standing use.
class PumpHomeScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const PumpHomeScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // dark slate
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          'Hi, ${user?.fullName ?? 'Operator'}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (_) => [
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
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFFFBBF24).withValues(alpha: 0.15),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFBBF24)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.local_gas_station, color: Color(0xFFFBBF24)),
            label: 'Dispense',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.list_alt, color: Color(0xFFFBBF24)),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFFFBBF24)),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
