import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../core/widgets/offline_banner.dart';

class DriverHomeScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const DriverHomeScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.fullName ?? 'Driver'}'),
        actions: [
          Consumer(
            builder: (ctx, ref, _) {
              final unread = ref.watch(unreadCountProvider);
              return Badge(
                isLabelVisible: unread > 0,
                label: Text(
                  '$unread',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                backgroundColor: KTColors.danger,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => ctx.push('/driver/notifications'),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'profile', child: Text('My Profile')),
              const PopupMenuItem(
                  value: 'logout', child: Text('Logout')),
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
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        indicatorColor: KTColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Trips'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Expenses'),
          NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
