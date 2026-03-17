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
import '../../providers/accountant_provider.dart';

class AccountantInvoicesScreen extends ConsumerStatefulWidget {
  const AccountantInvoicesScreen({super.key});

  @override
  ConsumerState<AccountantInvoicesScreen> createState() =>
      _AccountantInvoicesScreenState();
}

class _AccountantInvoicesScreenState
    extends ConsumerState<AccountantInvoicesScreen> {
  String? _statusFilter;

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

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceListProvider(_statusFilter));

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title:
            Text('Invoices', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAccountant,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _chip('All', null),
                _chip('Pending', 'pending'),
                _chip('Paid', 'paid'),
                _chip('Overdue', 'overdue'),
                _chip('Partial', 'partial'),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: RefreshIndicator(
              color: KTColors.roleAccountant,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                ref.invalidate(invoiceListProvider(_statusFilter));
              },
              child: invoices.when(
                loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
                error: (e, _) => KTErrorState(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(invoiceListProvider(_statusFilter)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const KTEmptyState(
                      icon: Icons.description_outlined,
                      title: 'No Invoices',
                      subtitle: 'No invoices match the current filter.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final inv = list[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push(
                                '/accountant/invoice/${inv.id}');
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
                                        inv.invoiceNumber,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: KTColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    KTStatusBadge.fromStatus(inv.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  inv.clientName ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: KTColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total: ${_formatCurrency(inv.totalAmount)}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: KTColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Due: ${_formatCurrency(inv.balanceDue)}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: inv.isOverdue
                                            ? KTColors.danger
                                            : KTColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
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
        selectedColor: KTColors.roleAccountant.withValues(alpha: 0.2),
        checkmarkColor: KTColors.roleAccountant,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _statusFilter = status);
        },
      ),
    );
  }
}
