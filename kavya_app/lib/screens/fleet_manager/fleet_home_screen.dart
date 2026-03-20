import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/theme/kt_text_styles.dart';
import '../../core/widgets/kt_stat_card.dart';
import '../../core/widgets/kt_alert_card.dart';
import '../../core/widgets/kt_action_button.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../providers/fleet_dashboard_provider.dart';

class FleetHomeScreen extends ConsumerWidget {
  const FleetHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(fleetDashboardProvider); // [cite: 50]

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fleet overview"), // [cite: 56]
        leading: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(Icons.local_shipping), // KT logo (small) placeholder [cite: 56]
        ),
        actions: [
          IconButton(
            icon: const Badge(child: Icon(Icons.notifications)), // notification bell (badge count) [cite: 56]
            onPressed: () {}, 
          )
        ],
      ),
      body: dashboardState.when(
        loading: () => const KTLoadingShimmer(type: ShimmerType.card), // Never use CircularProgressIndicator [cite: 109-110]
        error: (error, stack) => KTErrorState( // Every API call must have a catch block [cite: 111-113]
          message: error.toString(),
          onRetry: () => ref.invalidate(fleetDashboardProvider),
        ),
        data: (data) => RefreshIndicator( // Pull-to-refresh wraps entire body [cite: 59, 118]
          color: KTColors.primary,
          onRefresh: () async => ref.invalidate(fleetDashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1 — Fleet status row [cite: 56]
                SizedBox(
                  height: 120,
                  child: Builder(builder: (_) {
                    final fleet = (data['fleet_summary'] as Map<String, dynamic>?) ?? {};
                    final onTrip = fleet['on_trip'] ?? 0;
                    final available = fleet['available'] ?? 0;
                    final maintenance = fleet['maintenance'] ?? 0;
                    final total = fleet['total_vehicles'] ?? 0;
                    final stopped = (total is int ? total : 0) - (onTrip is int ? onTrip : 0) - (available is int ? available : 0) - (maintenance is int ? maintenance : 0);
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(width: 140, child: KTStatCard(title: "On Trip", value: '$onTrip', color: KTColors.success, icon: Icons.trending_up)),
                        SizedBox(width: 140, child: KTStatCard(title: "Available", value: '$available', color: KTColors.warning, icon: Icons.pause_circle_outline)),
                        SizedBox(width: 140, child: KTStatCard(title: "Other", value: '${stopped < 0 ? 0 : stopped}', color: KTColors.info, icon: Icons.stop_circle_outlined)),
                        SizedBox(width: 160, child: KTStatCard(title: "Maintenance", value: '$maintenance', color: KTColors.danger, icon: Icons.build)),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 24),
                
                // Section 2 — Alerts [cite: 57-58]
                Text("Today's alerts", style: KTTextStyles.h3),
                const SizedBox(height: 12),
                Builder(builder: (_) {
                  final expiring = (data['expiring_documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  return KTAlertCard(
                    title: "Documents expiring soon",
                    count: expiring.length,
                    severity: expiring.length > 3 ? AlertSeverity.high : (expiring.isNotEmpty ? AlertSeverity.medium : AlertSeverity.low),
                    items: expiring.take(5).map((d) => "${d['registration'] ?? '—'} — ${d['type'] ?? ''}").toList(),
                    onTap: () => context.go('/fleet/vehicles'),
                  );
                }),
                const SizedBox(height: 12),
                
                // Section 3 — Quick actions grid (2x2) [cite: 58]
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    KTActionButton(icon: Icons.build, label: "Log service", onTap: () => context.go('/fleet/service/new')), // [cite: 58]
                    KTActionButton(icon: Icons.tire_repair, label: "Record tyre", onTap: () => context.go('/fleet/tyre/new')), // [cite: 58]
                    KTActionButton(icon: Icons.receipt_long, label: "Approve expense", onTap: () => context.go('/fleet/expenses')), // [cite: 58]
                    KTActionButton(icon: Icons.map, label: "Live map", onTap: () => context.go('/fleet/map')), // [cite: 58]
                  ],
                ),
                
                // Section 4 & 5 placeholders (Leaderboard & Performance) [cite: 58-59]
                const SizedBox(height: 24),
                Text("Fuel efficiency (last 30 days)", style: KTTextStyles.h3),
                // Add compact list here based on `data['leaderboard']`
              ],
            ),
          ),
        ),
      ),
    );
  }
}