import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../providers/admin_providers.dart';

/// Admin shell with 5-tab bottom navigation.
class AdminShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KTColors.darkBg,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: KTColors.darkSurface,
        indicatorColor: KTColors.amber600.withAlpha(30),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.home, color: KTColors.amber600),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.work, color: KTColors.amber600),
            label: 'Ops',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.bar_chart, color: KTColors.amber600),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.people, color: KTColors.amber600),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.settings, color: KTColors.amber600),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Compliance bell icon button with badge.
class ComplianceBellButton extends ConsumerWidget {
  const ComplianceBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(complianceAlertCountProvider);
    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count', style: const TextStyle(fontSize: 10)),
        backgroundColor: KTColors.danger,
        child: const Icon(Icons.verified_user_outlined, color: Colors.white),
      ),
      onPressed: () => context.push('/admin/compliance'),
    );
  }
}
