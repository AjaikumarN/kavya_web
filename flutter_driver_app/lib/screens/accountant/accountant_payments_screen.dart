import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/accountant_provider.dart';

class AccountantPaymentsScreen extends ConsumerStatefulWidget {
  const AccountantPaymentsScreen({super.key});

  @override
  ConsumerState<AccountantPaymentsScreen> createState() =>
      _AccountantPaymentsScreenState();
}

class _AccountantPaymentsScreenState
    extends ConsumerState<AccountantPaymentsScreen> {
  String? _modeFilter;

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
    final filters = <String, String?>{
      'mode': _modeFilter,
      'from_date': null,
      'to_date': null,
    };
    final payments = ref.watch(paymentsProvider(filters));

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Payments',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAccountant,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Filter ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _chip('All', null),
                _chip('Bank Transfer', 'bank_transfer'),
                _chip('Cheque', 'cheque'),
                _chip('Cash', 'cash'),
                _chip('UPI', 'upi'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: KTColors.roleAccountant,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                ref.invalidate(paymentsProvider(filters));
              },
              child: payments.when(
                loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
                error: (e, _) => KTErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(paymentsProvider(filters)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const KTEmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No Payments',
                      subtitle: 'No payment records found.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final amount = (p['amount'] as num?) ?? 0;
                      final mode = p['mode']?.toString() ?? '';
                      final date = p['date']?.toString() ?? '';
                      final invoice = p['invoice_number']?.toString() ?? '';
                      final client = p['client_name']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: KTColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.check_circle,
                                    color: KTColors.success, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: KTColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '$client · $mode',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: KTColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      date,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: KTColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatCurrency(amount),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: KTColors.success,
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? mode) {
    final selected = _modeFilter == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        selectedColor: KTColors.roleAccountant.withValues(alpha: 0.2),
        checkmarkColor: KTColors.roleAccountant,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _modeFilter = mode);
        },
      ),
    );
  }
}
