import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_stat_card.dart';
import '../../core/widgets/kt_alert_card.dart';
import '../../core/widgets/kt_action_button.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fleet_provider.dart';

class FleetHomeScreen extends ConsumerWidget {
  const FleetHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final dashboard = ref.watch(fleetDashboardProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      body: RefreshIndicator(
        color: KTColors.roleFleet,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(fleetDashboardProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: KTColors.roleFleet,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Fleet Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        KTColors.roleFleet,
                        KTColors.roleFleet.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notification-list'),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: dashboard.when(
                loading: () => const SliverToBoxAdapter(
                  child: KTLoadingShimmer(variant: ShimmerVariant.stat),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: KTErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(fleetDashboardProvider),
                  ),
                ),
                data: (data) {
                  final totalVehicles = data['total_vehicles'] ?? 0;
                  final activeVehicles = data['active_vehicles'] ?? 0;
                  final idleVehicles = data['idle_vehicles'] ?? 0;
                  final pendingExpenses = data['pending_expenses'] ?? 0;
                  final alerts = (data['alerts'] as List?)?.cast<String>() ?? [];

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Greeting ──
                      Text(
                        'Hello, ${user?.fullName ?? 'Manager'}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KTColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Stats grid ──
                      Row(
                        children: [
                          Expanded(
                            child: KTStatCard(
                              title: 'Total Vehicles',
                              value: '$totalVehicles',
                              icon: Icons.local_shipping,
                              color: KTColors.roleFleet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTStatCard(
                              title: 'Active',
                              value: '$activeVehicles',
                              icon: Icons.play_circle_outline,
                              color: KTColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: KTStatCard(
                              title: 'Idle',
                              value: '$idleVehicles',
                              icon: Icons.pause_circle_outline,
                              color: KTColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTStatCard(
                              title: 'Pending Expenses',
                              value: '$pendingExpenses',
                              icon: Icons.receipt_long,
                              color: KTColors.danger,
                            ),
                          ),
                        ],
                      ),

                      // ── Alerts ──
                      if (alerts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        KTAlertCard(
                          count: alerts.length,
                          title: 'Alerts',
                          severity: AlertSeverity.medium,
                          items: alerts,
                        ),
                      ],

                      // ── Quick Actions ──
                      const SizedBox(height: 20),
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KTColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: KTActionButton(
                              icon: Icons.map,
                              label: 'Live Map',
                              color: KTColors.info,
                              onTap: () => context.go('/fleet/map'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTActionButton(
                              icon: Icons.build,
                              label: 'Log Service',
                              color: KTColors.roleFleet,
                              onTap: () => context.push('/fleet/service/new'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTActionButton(
                              icon: Icons.tire_repair,
                              label: 'Tyre Event',
                              color: KTColors.warning,
                              onTap: () => context.push('/fleet/tyre/new'),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
