import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/fleet_provider.dart';
import '../../services/api_service.dart';

class FleetExpenseApprovalScreen extends ConsumerStatefulWidget {
  const FleetExpenseApprovalScreen({super.key});

  @override
  ConsumerState<FleetExpenseApprovalScreen> createState() =>
      _FleetExpenseApprovalScreenState();
}

class _FleetExpenseApprovalScreenState
    extends ConsumerState<FleetExpenseApprovalScreen> {
  final _api = ApiService();
  final _processingIds = <String>{};

  String _formatCurrency(num amount) {
    final str = amount.toInt().toString();
    if (str.length <= 3) return '₹$str';
    final last3 = str.substring(str.length - 3);
    var remaining = str.substring(0, str.length - 3);
    final parts = <String>[];
    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) parts.insert(0, remaining);
    return '₹${parts.join(',')},$last3';
  }

  Future<void> _approve(String id) async {
    if (_processingIds.contains(id)) return;
    setState(() => _processingIds.add(id));
    try {
      await _api.approveExpense(id);
      HapticFeedback.mediumImpact();
      ref.invalidate(fleetPendingExpensesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense approved'), backgroundColor: KTColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _reject(String id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Expense'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Enter rejection reason',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    if (_processingIds.contains(id)) return;
    setState(() => _processingIds.add(id));
    try {
      await _api.rejectExpense(id, reason);
      HapticFeedback.mediumImpact();
      ref.invalidate(fleetPendingExpensesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense rejected'), backgroundColor: KTColors.warning),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(fleetPendingExpensesProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Expense Approvals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleFleet,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: KTColors.roleFleet,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(fleetPendingExpensesProvider);
        },
        child: expenses.when(
          loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
          error: (e, _) => KTErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(fleetPendingExpensesProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const KTEmptyState(
                icon: Icons.check_circle_outline,
                title: 'All Caught Up',
                subtitle: 'No pending expenses to approve.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final exp = list[i];
                final id = exp['id']?.toString() ?? '';
                final amount = (exp['amount'] as num?) ?? 0;
                final category = exp['category']?.toString() ?? 'Other';
                final driver = exp['driver_name']?.toString() ?? '';
                final vehicle = exp['vehicle_number']?.toString() ?? '';
                final isProcessing = _processingIds.contains(id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: KTColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency(amount),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: KTColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$driver · $vehicle',
                          style: GoogleFonts.inter(fontSize: 13, color: KTColors.textSecondary),
                        ),
                        if (exp['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            exp['description'].toString(),
                            style: GoogleFonts.inter(fontSize: 12, color: KTColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: isProcessing ? null : () => _reject(id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: KTColors.danger,
                                side: const BorderSide(color: KTColors.danger),
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: isProcessing ? null : () => _approve(id),
                              style: FilledButton.styleFrom(
                                backgroundColor: KTColors.success,
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
