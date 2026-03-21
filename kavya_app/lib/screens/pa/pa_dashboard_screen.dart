import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/theme/kt_text_styles.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/notification_bell_widget.dart';
import 'pa_providers.dart';

class PADashboardScreen extends ConsumerStatefulWidget {
  const PADashboardScreen({super.key});

  @override
  ConsumerState<PADashboardScreen> createState() => _PADashboardScreenState();
}

class _PADashboardScreenState extends ConsumerState<PADashboardScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Refresh countdown every minute so "expires in X h" stays current
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatExpiry(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'EXPIRED';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(paDashboardStatsProvider);
    final actionsAsync = ref.watch(paPriorityActionsProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Text('Dashboard', style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
        actions: const [NotificationBellWidget()],
      ),
      body: RefreshIndicator(
        color: KTColors.primary,
        backgroundColor: KTColors.darkSurface,
        onRefresh: () async {
          ref.invalidate(paDashboardStatsProvider);
          ref.invalidate(paPriorityActionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── KPI Grid ──────────────────────────────────────────────
              statsAsync.when(
                loading: () => const _KPIShimmer(),
                error: (e, _) => KTErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(paDashboardStatsProvider),
                ),
                data: (stats) => _KPIGrid(stats: stats, onFormatExpiry: _formatExpiry),
              ),
              const SizedBox(height: 20),

              // ── Priority Actions ──────────────────────────────────────
              Text('Priority Actions', style: KTTextStyles.h3.copyWith(color: KTColors.darkTextPrimary)),
              const SizedBox(height: 12),
              actionsAsync.when(
                loading: () => const KTLoadingShimmer(type: ShimmerType.list),
                error: (e, _) => KTErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(paPriorityActionsProvider),
                ),
                data: (actions) {
                  if (actions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'All caught up!',
                          style: KTTextStyles.body.copyWith(color: KTColors.darkTextSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: actions
                        .map((a) => _PriorityActionCard(action: Map<String, dynamic>.from(a as Map)))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI Grid ─────────────────────────────────────────────────────────────────

class _KPIGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String Function(String?) onFormatExpiry;
  const _KPIGrid({required this.stats, required this.onFormatExpiry});

  @override
  Widget build(BuildContext context) {
    final ewbExpiring = stats['ewb_expiring'] ?? 0;
    final hoursUntil = (stats['hours_until_expiry'] as num?)?.toDouble();
    final expiryLabel = hoursUntil != null && hoursUntil > 0
        ? 'in ${hoursUntil.toStringAsFixed(0)}h'
        : ewbExpiring > 0 ? 'Urgent' : 'None';

    return Column(
      children: [
        // ── Urgent EWB Banner ───────────────────────────────────────────
        if (ewbExpiring > 0)
          GestureDetector(
            onTap: () => context.push('/pa/ewb'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: KTColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: KTColors.danger, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: KTColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$ewbExpiring EWB${ewbExpiring > 1 ? 's' : ''} expiring $expiryLabel  — EWB ${stats['earliest_ewb_lr_number'] ?? ''}',
                      style: KTTextStyles.bodySmall.copyWith(color: KTColors.danger),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: KTColors.danger, size: 18),
                ],
              ),
            ),
          ),

        // ── 2×2 KPI tiles ──────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _KPICard(
              label: 'Jobs Awaiting LR',
              value: '${stats['jobs_awaiting_lr'] ?? 0}',
              color: KTColors.warning,
              icon: Icons.work_outline,
              onTap: () => context.go('/pa/jobs'),
            ),
            _KPICard(
              label: 'EWB Expiring',
              value: '${stats['ewb_expiring'] ?? 0}',
              color: KTColors.danger,
              icon: Icons.timer_outlined,
              onTap: () => context.go('/pa/ewb'),
            ),
            _KPICard(
              label: 'Trips In Transit',
              value: '${stats['trips_in_transit'] ?? 0}',
              color: KTColors.info,
              icon: Icons.local_shipping_outlined,
              onTap: () {},
            ),
            _KPICard(
              label: 'PODs Pending',
              value: '${stats['pods_pending'] ?? 0}',
              color: KTColors.success,
              icon: Icons.inventory_2_outlined,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _KPICard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(value, style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
            ]),
            const SizedBox(height: 4),
            Text(label, style: KTTextStyles.bodySmall.copyWith(color: KTColors.darkTextSecondary)),
          ],
        ),
      ),
    );
  }
}

class _KPIShimmer extends StatelessWidget {
  const _KPIShimmer();

  @override
  Widget build(BuildContext context) => const KTLoadingShimmer(type: ShimmerType.card);
}

// ── Priority Action Card ──────────────────────────────────────────────────────

class _PriorityActionCard extends StatelessWidget {
  final Map<String, dynamic> action;
  const _PriorityActionCard({required this.action});

  String _statusLabel(String status) {
    switch (status) {
      case 'POD_UPLOADED': return 'POD Uploaded';
      case 'EWB_EXPIRING': return 'EWB Expiring';
      case 'VEHICLE_ASSIGNED': return 'Vehicle Assigned';
      case 'LR_CREATED': return 'LR Created';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'POD_UPLOADED': return KTColors.success;
      case 'EWB_EXPIRING': return KTColors.danger;
      case 'VEHICLE_ASSIGNED': return KTColors.warning;
      default: return KTColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (action['status'] as String?) ?? '';
    final jobId = action['job_id'];

    return GestureDetector(
      onTap: () {
        if (jobId != null) context.push('/pa/jobs/$jobId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KTColors.darkBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: KTTextStyles.bodySmall.copyWith(color: _statusColor(status)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      action['job_number'] ?? '',
                      style: KTTextStyles.bodySmall.copyWith(color: KTColors.darkTextSecondary),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    action['client_name'] ?? '',
                    style: KTTextStyles.body.copyWith(
                      color: KTColors.darkTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action['route'] ?? '',
                    style: KTTextStyles.bodySmall.copyWith(color: KTColors.darkTextSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: KTColors.darkTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
