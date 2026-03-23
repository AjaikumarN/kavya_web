import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../providers/admin_providers.dart';

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminFinanceSummaryProvider);
    final invoices = ref.watch(adminRecentInvoicesProvider);
    final payables = ref.watch(adminPayablesSummaryProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: const Text('Finance',
            style: TextStyle(color: KTColors.darkTextPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminFinanceSummaryProvider);
          ref.invalidate(adminRecentInvoicesProvider);
          ref.invalidate(adminPayablesSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── KPI Grid ──
            summary.when(
              data: (d) => _buildKpiGrid(d),
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: KTColors.amber600))),
              error: (e, _) => GestureDetector(
                onTap: () => ref.invalidate(adminFinanceSummaryProvider),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KTColors.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(children: [
                    Text('Finance data unavailable', style: TextStyle(color: KTColors.darkTextSecondary, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Tap to retry', style: TextStyle(color: KTColors.amber600, fontSize: 11)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Receivables Aging ──
            _sectionHead('RECEIVABLES AGING'),
            summary.when(
              data: (d) {
                final aging = d['receivables_aging'] as Map<String, dynamic>? ?? {};
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KTColors.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _agingRow('Current (0-30d)', aging['current'], KTColors.success),
                      const Divider(color: KTColors.darkBorder, height: 16),
                      _agingRow('31-60 days', aging['days_31_60'], KTColors.amber600),
                      const Divider(color: KTColors.darkBorder, height: 16),
                      _agingRow('61-90 days', aging['days_61_90'], KTColors.danger),
                      const Divider(color: KTColors.darkBorder, height: 16),
                      _agingRow('90+ days', aging['days_90_plus'], KTColors.danger),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // ── Recent Invoices ──
            _sectionHead('RECENT INVOICES'),
            invoices.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Text('No invoices yet', style: TextStyle(color: KTColors.darkTextSecondary));
                }
                return Column(
                  children: list.take(5).map<Widget>((inv) {
                    final m = inv as Map<String, dynamic>;
                    return _invoiceTile(context, m);
                  }).toList(),
                );
              },
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: KTColors.amber600))),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // ── Payables ──
            _sectionHead('PAYABLES'),
            payables.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KTColors.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: list.map<Widget>((p) {
                      final m = p as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(m['category'] as String? ?? '—',
                                style: const TextStyle(color: KTColors.darkTextSecondary, fontSize: 13)),
                            Text(_fmtAmt(m['amount']),
                                style: const TextStyle(color: KTColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> d) {
    return Column(
      children: [
        Row(
          children: [
            _kpi(_fmtAmt(d['month_revenue']), 'Month revenue', KTColors.success),
            const SizedBox(width: 10),
            _kpi(_fmtAmt(d['total_receivables']), 'Receivables', KTColors.danger),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _kpi(_fmtAmt(d['total_payables']), 'Payables', KTColors.info),
            const SizedBox(width: 10),
            _kpi(_fmtAmt(d['overdue_amount']), 'Overdue', const Color(0xFF7C3AED)),
          ],
        ),
      ],
    );
  }

  Widget _kpi(String value, String label, Color color) {
    return Expanded(
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
            Text(value, style: const TextStyle(color: KTColors.darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: KTColors.darkTextSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _agingRow(String label, dynamic amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: KTColors.darkTextSecondary, fontSize: 13)),
        Text(_fmtAmt(amount), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _invoiceTile(BuildContext context, Map<String, dynamic> m) {
    final number = m['invoice_number'] as String? ?? '—';
    final status = (m['status'] as String? ?? 'DRAFT').toUpperCase();
    final client = m['client_name'] as String? ?? m['billing_name'] as String? ?? '—';
    final amount = _fmtAmt(m['total_amount']);
    final isPaid = status == 'PAID';
    final isOverdue = status == 'OVERDUE';

    return GestureDetector(
      onTap: () {
        final invId = m['id']?.toString();
        if (invId != null) context.push('/admin/invoices/$invId');
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KTColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(
          color: isPaid ? KTColors.success : isOverdue ? KTColors.danger : KTColors.info,
          width: 3,
        )),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(number, style: const TextStyle(color: KTColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPaid ? KTColors.success : isOverdue ? KTColors.danger : KTColors.info).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: TextStyle(
                  color: isPaid ? KTColors.success : isOverdue ? KTColors.danger : KTColors.info,
                  fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$client · $amount', style: const TextStyle(color: KTColors.darkTextSecondary, fontSize: 12)),
          if (isOverdue)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: KTColors.darkElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Send reminder', style: TextStyle(color: KTColors.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _sectionHead(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: KTColors.darkTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

  String _fmtAmt(dynamic val) {
    final v = (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '') ?? 0.0;
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}
