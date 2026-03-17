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
import '../../providers/associate_provider.dart';

class AssociateHomeScreen extends ConsumerWidget {
  const AssociateHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final dashboard = ref.watch(associateDashboardProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      body: RefreshIndicator(
        color: KTColors.roleAssociate,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(associateDashboardProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: KTColors.roleAssociate,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Operations',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
                    onRetry: () => ref.invalidate(associateDashboardProvider),
                  ),
                ),
                data: (data) {
                  final totalJobs = data['total_jobs'] ?? 0;
                  final needsLr = data['jobs_pending_lr'] ?? 0;
                  final needsEwb = data['lr_pending_ewb'] ?? 0;
                  final activeTrips = data['active_trips'] ?? 0;
                  final alerts = (data['alerts'] as List?)?.cast<String>() ?? [];

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'Hello, ${user?.fullName ?? 'Associate'}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KTColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: KTStatCard(
                              title: 'Total Jobs',
                              value: '$totalJobs',
                              icon: Icons.work,
                              color: KTColors.roleAssociate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTStatCard(
                              title: 'Needs LR',
                              value: '$needsLr',
                              icon: Icons.article,
                              color: KTColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: KTStatCard(
                              title: 'Needs E-Way Bill',
                              value: '$needsEwb',
                              icon: Icons.fact_check,
                              color: KTColors.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KTStatCard(
                              title: 'Active Trips',
                              value: '$activeTrips',
                              icon: Icons.directions,
                              color: KTColors.success,
                            ),
                          ),
                        ],
                      ),

                      if (alerts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        KTAlertCard(
                          count: alerts.length,
                          title: 'Action Items',
                          severity: AlertSeverity.medium,
                          items: alerts,
                        ),
                      ],

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
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 56) / 3,
                            child: KTActionButton(
                              icon: Icons.article,
                              label: 'Create LR',
                              color: KTColors.roleAssociate,
                              onTap: () => context.push('/associate/lr/create'),
                            ),
                          ),
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 56) / 3,
                            child: KTActionButton(
                              icon: Icons.fact_check,
                              label: 'Create EWB',
                              color: KTColors.info,
                              onTap: () => context.push('/associate/ewb/create'),
                            ),
                          ),
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 56) / 3,
                            child: KTActionButton(
                              icon: Icons.check_circle,
                              label: 'Close Trip',
                              color: KTColors.success,
                              onTap: () => context.push('/associate/trip/close'),
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
