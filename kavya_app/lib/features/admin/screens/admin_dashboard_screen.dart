import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kt_colors.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_shell_screen.dart';
import '../widgets/role_health_tile.dart';
import '../widgets/quick_action_tile.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardStatsProvider);
    final roleHealth = ref.watch(adminRoleHealthProvider);
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kavya Transports',
                style: TextStyle(
                    color: KTColors.darkTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            Text('Admin · $today',
                style: const TextStyle(
                    color: KTColors.darkTextSecondary, fontSize: 12)),
          ],
        ),
        actions: const [ComplianceBellButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
          ref.invalidate(adminRoleHealthProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── KPI Grid 2×2 ──
            stats.when(
              data: (d) => _buildKPIGrid(context, d, ref),
              loading: () => const SizedBox(
                  height: 120,
                  child: Center(
                      child:
                          CircularProgressIndicator(color: KTColors.amber600))),
              error: (e, _) => _kpiErrorFallback(ref, e),
            ),

            const SizedBox(height: 16),

            // ── Alert banner ──
            stats.when(
              data: (d) {
                final alerts = d['compliance_alerts'] as int? ?? 0;
                if (alerts == 0) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => context.push('/admin/compliance'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: KTColors.danger.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: KTColors.danger, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: KTColors.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$alerts compliance alert${alerts > 1 ? 's' : ''} — action needed',
                            style: const TextStyle(
                                color: KTColors.darkTextPrimary, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: KTColors.darkTextSecondary, size: 18),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Role Health ──
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('ROLE HEALTH STATUS',
                  style: TextStyle(
                      color: KTColors.darkTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
            roleHealth.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No role data available',
                        style: TextStyle(color: KTColors.darkTextSecondary, fontSize: 12)),
                  );
                }
                return Column(
                  children: list.map<Widget>((r) {
                    final m = r as Map<String, dynamic>;
                    return RoleHealthTile(
                      role: m['role'] as String? ?? '',
                      label: m['label'] as String? ?? '',
                      detailText: m['detail_text'] as String? ?? '',
                      statusLabel: m['status_label'] as String? ?? 'Active',
                      statusColor: _statusColor(m['status_label'] as String?),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                  height: 80,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: KTColors.amber600))),
              error: (e, _) => GestureDetector(
                onTap: () => ref.invalidate(adminRoleHealthProvider),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: KTColors.darkSurface, borderRadius: BorderRadius.circular(10)),
                  child: const Column(children: [
                    Text('Could not load role data', style: TextStyle(color: KTColors.darkTextSecondary, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Tap to retry', style: TextStyle(color: KTColors.amber600, fontSize: 11)),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick Actions ──
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('QUICK ACTIONS',
                  style: TextStyle(
                      color: KTColors.darkTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: [
                QuickActionTile(
                    color: KTColors.amber600,
                    label: 'Create LR',
                    onTap: () => context.go('/admin/operations')),
                QuickActionTile(
                    color: KTColors.success,
                    label: 'New trip',
                    onTap: () => context.go('/admin/operations')),
                QuickActionTile(
                    color: KTColors.info,
                    label: 'Upload doc',
                    onTap: () => context.go('/admin/operations')),
                QuickActionTile(
                    color: const Color(0xFF6366F1),
                    label: 'EWB',
                    onTap: () => context.go('/admin/operations')),
                QuickActionTile(
                    color: Colors.grey,
                    label: 'Add user',
                    onTap: () => context.push('/admin/employees/create')),
                QuickActionTile(
                    color: KTColors.danger,
                    label: 'Finance',
                    onTap: () => context.go('/admin/finance')),
                QuickActionTile(
                    color: const Color(0xFF0EA5E9),
                    label: 'Live Map',
                    onTap: () => context.push('/fleet/map')),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(
      BuildContext context, Map<String, dynamic> d, WidgetRef ref) {
    // Update compliance count for the bell badge
    final alertCount = d['compliance_alerts'] as int? ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(complianceAlertCountProvider.notifier).state = alertCount;
    });

    return Column(
      children: [
        Row(
          children: [
            _kpi(context, '${d['active_trips'] ?? 0}', 'Active trips',
                KTColors.info, () => context.go('/admin/operations')),
            const SizedBox(width: 10),
            _kpi(context, _fmtCurrency(d['month_revenue']), 'Month revenue',
                KTColors.success, () => context.go('/admin/finance')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _kpi(context, '${d['compliance_alerts'] ?? 0}',
                'Compliance alerts', KTColors.danger,
                () => context.push('/admin/compliance')),
            const SizedBox(width: 10),
            _kpi(context, '${d['active_employees'] ?? 0}',
                'Active employees', KTColors.amber600,
                () => context.go('/admin/employees')),
          ],
        ),
      ],
    );
  }

  Widget _kpi(BuildContext context, String value, String label, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KTColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: KTColors.darkTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: KTColors.darkTextSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? label) {
    switch (label?.toLowerCase()) {
      case 'active':
        return KTColors.success;
      case 'busy':
        return KTColors.amber600;
      case 'overdue':
        return KTColors.danger;
      default:
        return KTColors.info;
    }
  }

  Widget _kpiErrorFallback(WidgetRef ref, Object error) {
    return GestureDetector(
      onTap: () => ref.invalidate(adminDashboardStatsProvider),
      child: Column(
        children: [
          Row(children: [
            _greyKpi('—', 'Active trips'),
            const SizedBox(width: 10),
            _greyKpi('—', 'Month revenue'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _greyKpi('—', 'Compliance alerts'),
            const SizedBox(width: 10),
            _greyKpi('—', 'Active employees'),
          ]),
          const SizedBox(height: 6),
          const Text('Could not load stats · Tap to retry',
              style: TextStyle(color: KTColors.darkTextSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _greyKpi(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: const Border(left: BorderSide(color: Colors.grey, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: KTColors.darkTextSecondary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: KTColors.darkTextSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _fmtCurrency(dynamic val) {
    final v = (val is num) ? val.toDouble() : 0.0;
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}
