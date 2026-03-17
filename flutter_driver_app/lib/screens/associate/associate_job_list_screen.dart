import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_status_badge.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/associate_provider.dart';

class AssociateJobListScreen extends ConsumerStatefulWidget {
  const AssociateJobListScreen({super.key});

  @override
  ConsumerState<AssociateJobListScreen> createState() =>
      _AssociateJobListScreenState();
}

class _AssociateJobListScreenState
    extends ConsumerState<AssociateJobListScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobListProvider(_statusFilter));

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Jobs',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAssociate,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _chip('All', null),
                _chip('Active', 'active'),
                _chip('Assigned', 'vehicle_assigned'),
                _chip('Completed', 'completed'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: KTColors.roleAssociate,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                ref.invalidate(jobListProvider(_statusFilter));
              },
              child: jobs.when(
                loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
                error: (e, _) => KTErrorState(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(jobListProvider(_statusFilter)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const KTEmptyState(
                      icon: Icons.work_outline,
                      title: 'No Jobs',
                      subtitle: 'No jobs match this filter.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final job = list[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (job.needsLR) {
                              HapticFeedback.lightImpact();
                              context.push(
                                '/associate/lr/create?job_id=${job.id}',
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        job.jobNumber,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: KTColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    KTStatusBadge.fromStatus(job.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  job.clientName ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: KTColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 14,
                                        color: KTColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${job.origin} → ${job.destination}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: KTColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (job.needsLR) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: KTColors.warning
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'LR Required — tap to create',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: KTColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        selectedColor: KTColors.roleAssociate.withValues(alpha: 0.2),
        checkmarkColor: KTColors.roleAssociate,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _statusFilter = status);
        },
      ),
    );
  }
}
