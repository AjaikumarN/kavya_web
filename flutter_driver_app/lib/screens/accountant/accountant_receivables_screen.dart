import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/accountant_provider.dart';

class AccountantReceivablesScreen extends ConsumerWidget {
  const AccountantReceivablesScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final receivables = ref.watch(receivablesProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Receivables', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAccountant,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: KTColors.roleAccountant,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(receivablesProvider);
        },
        child: receivables.when(
          loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
          error: (e, _) => KTErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(receivablesProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const KTEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No Receivables',
                subtitle: 'All payments are up to date.',
              );
            }

            // Summary
            final totalAmount = list.fold<num>(
                0, (sum, r) => sum + ((r['outstanding'] as num?) ?? 0));

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: KTColors.roleAccountant.withValues(alpha: 0.08),
                  child: Column(
                    children: [
                      Text(
                        'Total Outstanding',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: KTColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(totalAmount),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: KTColors.roleAccountant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final client = r['client_name']?.toString() ?? '';
                      final outstanding = (r['outstanding'] as num?) ?? 0;
                      final invoiceCount = r['invoice_count'] ?? 0;
                      final overdueCount = r['overdue_count'] ?? 0;

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
                                  color: KTColors.roleAccountant
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    client.isNotEmpty
                                        ? client[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: KTColors.roleAccountant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      client,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: KTColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '$invoiceCount invoices${overdueCount > 0 ? ' · $overdueCount overdue' : ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: overdueCount > 0
                                            ? KTColors.danger
                                            : KTColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatCurrency(outstanding),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: KTColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
