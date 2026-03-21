import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/theme/kt_text_styles.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/notification_bell_widget.dart';
import 'pa_providers.dart';

class PAJobListScreen extends ConsumerWidget {
  const PAJobListScreen({super.key});

  static const _filters = [
    ('All', null),
    ('LR Needed', 'VEHICLE_ASSIGNED'),
    ('LR Created', 'LR_CREATED'),
    ('In Transit', 'in_transit'),
    ('Completed', 'completed'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(paJobFilterProvider);
    final jobsAsync = ref.watch(paJobListProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Text('Jobs', style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
        actions: const [NotificationBellWidget()],
      ),
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _filters.map((f) {
                final isActive = filter.status == f.$2;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$1),
                    selected: isActive,
                    onSelected: (_) {
                      ref.read(paJobFilterProvider.notifier).state =
                          PAJobFilter(status: f.$2, page: 1);
                    },
                    backgroundColor: KTColors.darkSurface,
                    selectedColor: KTColors.primary,
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : KTColors.darkTextSecondary,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isActive ? KTColors.primary : KTColors.darkBorder),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Jobs list ─────────────────────────────────────────────────
          Expanded(
            child: jobsAsync.when(
              loading: () => const KTLoadingShimmer(type: ShimmerType.list),
              error: (e, _) => KTErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(paJobListProvider),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      'No jobs found',
                      style: KTTextStyles.body.copyWith(color: KTColors.darkTextSecondary),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: KTColors.primary,
                  backgroundColor: KTColors.darkSurface,
                  onRefresh: () async => ref.invalidate(paJobListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: jobs.length,
                    itemBuilder: (context, i) {
                      final job = Map<String, dynamic>.from(jobs[i] as Map);
                      return _JobListCard(job: job);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobListCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobListCard({required this.job});

  Color _statusColor(String? s) {
    switch (s) {
      case 'VEHICLE_ASSIGNED': return KTColors.warning;
      case 'LR_CREATED': return KTColors.info;
      case 'in_transit': return KTColors.success;
      case 'completed': return KTColors.gray400;
      default: return KTColors.darkTextSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'VEHICLE_ASSIGNED': return 'Vehicle Assigned';
      case 'LR_CREATED': return 'LR Created';
      case 'in_transit': return 'In Transit';
      case 'completed': return 'Completed';
      default: return s ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String?;
    final jobId = job['id'];

    return GestureDetector(
      onTap: () => context.push('/pa/jobs/$jobId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KTColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job['job_number'] ?? 'JOB-???',
                  style: KTTextStyles.body.copyWith(
                    color: KTColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              (job['client_name'] as String?) ?? '',
              style: KTTextStyles.body.copyWith(color: KTColors.darkTextPrimary),
            ),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.route, size: 14, color: KTColors.darkTextSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${job['origin'] ?? ''} → ${job['destination'] ?? ''}',
                  style: KTTextStyles.bodySmall.copyWith(color: KTColors.darkTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            if (status == 'VEHICLE_ASSIGNED') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/pa/jobs/$jobId/lr'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: KTColors.primary),
                    foregroundColor: KTColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Create LR + EWB'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
