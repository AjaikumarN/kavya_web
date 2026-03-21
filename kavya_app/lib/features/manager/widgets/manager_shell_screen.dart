import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../core/widgets/notification_bell_widget.dart';
import '../providers/manager_providers.dart';

class ManagerShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const ManagerShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: KTColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work, color: KTColors.primary),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: KTColors.primary),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: KTColors.primary),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: KTColors.primary),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
