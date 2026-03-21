import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_shell_screen.dart';
import '../../manager/widgets/job_card_widget.dart';

class AdminOperationsScreen extends ConsumerWidget {
  const AdminOperationsScreen({super.key});

  static const _statuses = [null, 'DRAFT', 'IN_PROGRESS', 'COMPLETED', 'CLOSED'];
  static const _labels = ['All', 'Unassigned', 'In transit', 'Delivered', 'Closed'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardStatsProvider);
    final filter = ref.watch(adminOpsFilterProvider);
    final jobs = ref.watch(adminOperationsJobsProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: const Text('Operations',
            style: TextStyle(color: KTColors.darkTextPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: const [ComplianceBellButton()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: KTColors.amber600,
        onPressed: () => context.push('/manager/jobs/create'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
          ref.invalidate(adminOperationsJobsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── KPI mini cards ──
            stats.when(
              data: (d) => _buildKPIRow(d),
              loading: () => const SizedBox(height: 70),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // ── Filter chips ──
            const Text('FILTER BY STATUS',
                style: TextStyle(
                    color: KTColors.darkTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(_statuses.length, (i) {
                final active = filter == _statuses[i];
                return ChoiceChip(
                  label: Text(_labels[i]),
                  selected: active,
                  selectedColor: KTColors.amber600,
                  backgroundColor: KTColors.darkSurface,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : KTColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                  onSelected: (_) =>
                      ref.read(adminOpsFilterProvider.notifier).state =
                          _statuses[i],
                );
              }),
            ),
            const SizedBox(height: 14),

            // ── Job list ──
            jobs.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                        child: Text('No jobs found',
                            style: TextStyle(
                                color: KTColors.darkTextSecondary))),
                  );
                }
                return Column(
                  children: list.map<Widget>((j) {
                    final job = j as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: JobCardWidget(
                        job: job,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                  height: 120,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: KTColors.amber600))),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: KTColors.danger)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIRow(Map<String, dynamic> d) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _miniKPI('${d['active_trips'] ?? 0}', 'Active trips', KTColors.info),
          _miniKPI('${d['pending_assignment'] ?? 0}', 'Unassigned',
              KTColors.amber600),
          _miniKPI('—', 'Total this month', KTColors.success),
          _miniKPI('—', 'Awaiting closure', const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _miniKPI(String value, String label, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: KTColors.darkTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
