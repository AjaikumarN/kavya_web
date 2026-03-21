import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../core/theme/kt_text_styles.dart';
import '../../../core/widgets/kt_loading_shimmer.dart';
import '../../../core/widgets/kt_error_state.dart';
import '../providers/manager_providers.dart';
import '../widgets/job_card_widget.dart';

class ManagerJobListScreen extends ConsumerWidget {
  const ManagerJobListScreen({super.key});

  static const _filters = ['all', 'PENDING_APPROVAL', 'IN_PROGRESS', 'DELIVERED', 'CLOSED'];
  static const _filterLabels = ['All', 'Unassigned', 'In transit', 'Delivered', 'Closed'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(managerJobFilterProvider);
    final jobsAsync = ref.watch(managerJobListProvider);
    final currentStatus = currentFilter.status;

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Text('Jobs', style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: KTColors.primary),
            onPressed: () => context.push('/manager/jobs/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ─────────────────────────────
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final filterStatus = _filters[i] == 'all' ? null : _filters[i];
                final sel = currentStatus == filterStatus;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabels[i]),
                    selected: sel,
                    selectedColor: KTColors.primary,
                    backgroundColor: KTColors.darkElevated,
                    labelStyle: TextStyle(color: sel ? Colors.white : KTColors.darkTextSecondary, fontSize: 13),
                    onSelected: (_) => ref.read(managerJobFilterProvider.notifier).state = ManagerJobFilter(status: filterStatus),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          // ── Job list ─────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: KTColors.primary,
              backgroundColor: KTColors.darkSurface,
              onRefresh: () async => ref.invalidate(managerJobListProvider),
              child: jobsAsync.when(
                loading: () => const KTLoadingShimmer(type: ShimmerType.list),
                error: (e, _) => KTErrorState(message: e.toString(), onRetry: () => ref.invalidate(managerJobListProvider)),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_outlined, color: KTColors.darkTextSecondary, size: 48),
                          const SizedBox(height: 12),
                          Text('No jobs found', style: KTTextStyles.body.copyWith(color: KTColors.darkTextSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: jobs.length,
                    itemBuilder: (_, i) => JobCardWidget(job: Map<String, dynamic>.from(jobs[i] as Map)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
