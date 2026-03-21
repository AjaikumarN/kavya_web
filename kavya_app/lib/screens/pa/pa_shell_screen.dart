import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/services/fcm_service.dart'; // unreadNotificationCountProvider
import '../../providers/auth_provider.dart';

class PAShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const PAShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: KTColors.darkSurface,
        indicatorColor: KTColors.primary.withOpacity(0.2),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) =>
            navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: KTColors.primary),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work, color: KTColors.primary),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: KTColors.danger,
              label: Text(unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              child: const Icon(Icons.timer_outlined),
            ),
            selectedIcon: const Icon(Icons.timer, color: KTColors.primary),
            label: 'EWB',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance, color: KTColors.primary),
            label: 'Banking',
          ),
        ],
      ),
    );
  }
}
