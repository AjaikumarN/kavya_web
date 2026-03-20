import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/theme/kt_text_styles.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/fleet_dashboard_provider.dart';

// Receivables list (unpaid invoices)
final receivablesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getReceivables();
});

class AccountantPaymentsScreen extends ConsumerStatefulWidget {
  const AccountantPaymentsScreen({super.key});

  @override
  ConsumerState<AccountantPaymentsScreen> createState() => _AccountantPaymentsScreenState();
}

class _AccountantPaymentsScreenState extends ConsumerState<AccountantPaymentsScreen> {
  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  void _showRecordPaymentSheet(Map<String, dynamic> invoice) {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String method = 'bank_transfer';
    final methods = ['bank_transfer', 'cheque', 'cash', 'upi'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Record Payment', style: KTTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Invoice #${invoice['invoice_number'] ?? invoice['id']}',
                style: KTTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: methods.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(m.replaceAll('_', ' ').toUpperCase()),
                )).toList(),
                onChanged: (v) => setSheetState(() => method = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference / UTR'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: KTColors.success),
                onPressed: () async {
                  final amountText = amountCtrl.text.trim();
                  if (amountText.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final amountPaise = int.parse(amountText) * 100;
                    await ref.read(apiServiceProvider).recordPayment(
                      (invoice['id'] ?? '').toString(),
                      {
                        'invoice_id': invoice['id'],
                        'amount_paise': amountPaise,
                        'method': method,
                        'reference': refCtrl.text.trim(),
                      },
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment recorded'), backgroundColor: KTColors.success),
                      );
                      ref.invalidate(receivablesProvider);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: KTColors.danger),
                      );
                    }
                  }
                },
                child: const Text('Record Payment'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receivablesState = ref.watch(receivablesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Receivables')),
      body: receivablesState.when(
        loading: () => const KTLoadingShimmer(type: ShimmerType.card),
        error: (err, _) => KTErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(receivablesProvider),
        ),
        data: (invoices) {
          if (invoices.isEmpty) {
            return const KTEmptyState(
              title: 'No pending receivables',
              subtitle: 'All payments are up to date!',
            );
          }
          return RefreshIndicator(
            color: KTColors.primary,
            onRefresh: () async => ref.invalidate(receivablesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final inv = invoices[index];
                final total = inv['total_amount'] ?? inv['amount'] ?? 0;
                final paid = inv['paid_amount'] ?? 0;
                final balance = total - paid;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv['invoice_number'] ?? 'INV-${inv['id']}',
                              style: KTTextStyles.label,
                            ),
                            Chip(
                              label: Text(
                                (inv['status'] ?? 'unpaid').toString().toUpperCase(),
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: balance > 0
                                  ? KTColors.warning.withOpacity(0.15)
                                  : KTColors.success.withOpacity(0.15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(inv['client_name'] ?? 'Client', style: KTTextStyles.bodySmall),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statCol('Total', _inr.format(total)),
                            _statCol('Paid', _inr.format(paid)),
                            _statCol('Balance', _inr.format(balance)),
                          ],
                        ),
                        if (balance > 0) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: KTColors.primary),
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Record Payment'),
                              onPressed: () => _showRecordPaymentSheet(inv),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: KTTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}