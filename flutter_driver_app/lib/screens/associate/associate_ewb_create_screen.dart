import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/associate_provider.dart';
import '../../services/api_service.dart';

class AssociateEWBCreateScreen extends ConsumerStatefulWidget {
  final String? lrId;
  const AssociateEWBCreateScreen({super.key, this.lrId});

  @override
  ConsumerState<AssociateEWBCreateScreen> createState() =>
      _AssociateEWBCreateScreenState();
}

class _AssociateEWBCreateScreenState
    extends ConsumerState<AssociateEWBCreateScreen> {
  final _api = ApiService();
  bool _submitting = false;
  String? _selectedLrId;

  @override
  void initState() {
    super.initState();
    _selectedLrId = widget.lrId;
  }

  Future<void> _generate() async {
    if (_submitting || _selectedLrId == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await _api.generateEWB({'lr_id': _selectedLrId});
      ref.invalidate(lrsNeedingEwbProvider);
      ref.invalidate(lrListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('E-Way Bill generated'),
              backgroundColor: KTColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lrsNeedingEwb = ref.watch(lrsNeedingEwbProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Generate E-Way Bill',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAssociate,
        foregroundColor: Colors.white,
      ),
      body: lrsNeedingEwb.when(
        loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
        error: (e, _) => KTErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(lrsNeedingEwbProvider),
        ),
        data: (lrs) {
          if (lrs.isEmpty && widget.lrId == null) {
            return const KTEmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No LRs Need EWB',
              subtitle: 'All LRs already have E-Way Bills.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Select a Lorry Receipt',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KTColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...lrs.map((lr) {
                final isSelected = _selectedLrId == lr.id.toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? const BorderSide(
                            color: KTColors.roleAssociate, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedLrId = lr.id.toString());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: lr.id.toString(),
                            groupValue: _selectedLrId,
                            activeColor: KTColors.roleAssociate,
                            onChanged: (v) =>
                                setState(() => _selectedLrId = v),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lr.lrNumber,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: KTColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${lr.fromLocation} → ${lr.toLocation}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: KTColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${lr.consignorName} → ${lr.consigneeName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: KTColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: (_submitting || _selectedLrId == null)
                      ? null
                      : _generate,
                  style: FilledButton.styleFrom(
                    backgroundColor: KTColors.roleAssociate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Generate E-Way Bill',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
