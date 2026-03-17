import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_stat_card.dart';
import '../../core/widgets/kt_status_badge.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/accountant_provider.dart';
import '../../services/api_service.dart';

class AccountantInvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const AccountantInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<AccountantInvoiceDetailScreen> createState() =>
      _AccountantInvoiceDetailScreenState();
}

class _AccountantInvoiceDetailScreenState
    extends ConsumerState<AccountantInvoiceDetailScreen> {
  final _api = ApiService();
  bool _recordingPayment = false;

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

  Future<void> _recordPayment() async {
    final amountCtrl = TextEditingController();
    String mode = 'bank_transfer';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => mode = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (amt == null || amt <= 0) return;
                Navigator.pop(ctx, {'amount': amt, 'mode': mode});
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    setState(() => _recordingPayment = true);
    try {
      await _api.recordPayment(widget.invoiceId, result);
      HapticFeedback.mediumImpact();
      ref.invalidate(invoiceDetailProvider(widget.invoiceId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded'),
            backgroundColor: KTColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _recordingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(invoiceDetailProvider(widget.invoiceId));

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Invoice Detail',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAccountant,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordingPayment ? null : _recordPayment,
        backgroundColor: KTColors.success,
        icon: _recordingPayment
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.payment),
        label: const Text('Record Payment'),
      ),
      body: RefreshIndicator(
        color: KTColors.roleAccountant,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(invoiceDetailProvider(widget.invoiceId));
        },
        child: detail.when(
          loading: () => const KTLoadingShimmer(variant: ShimmerVariant.card),
          error: (e, _) => KTErrorState(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(invoiceDetailProvider(widget.invoiceId)),
          ),
          data: (invoice) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Header ──
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.invoiceNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: KTColors.textPrimary,
                              ),
                            ),
                          ),
                          KTStatusBadge.fromStatus(invoice.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        invoice.clientName ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: KTColors.textSecondary,
                        ),
                      ),
                      if (invoice.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${invoice.dueDate}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: invoice.isOverdue
                                ? KTColors.danger
                                : KTColors.textSecondary,
                            fontWeight: invoice.isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Amounts ──
              Row(
                children: [
                  Expanded(
                    child: KTStatCard(
                      title: 'Total',
                      value: _formatCurrency(invoice.totalAmount),
                      icon: Icons.receipt,
                      color: KTColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KTStatCard(
                      title: 'Balance Due',
                      value: _formatCurrency(invoice.balanceDue),
                      icon: Icons.account_balance_wallet,
                      color: invoice.balanceDue > 0
                          ? KTColors.danger
                          : KTColors.success,
                    ),
                  ),
                ],
              ),

              // ── GST ──
              if (invoice.cgst > 0 || invoice.sgst > 0 || invoice.igst > 0) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GST Breakdown',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        if (invoice.cgst > 0)
                          _gstRow('CGST', invoice.cgst),
                        if (invoice.sgst > 0)
                          _gstRow('SGST', invoice.sgst),
                        if (invoice.igst > 0)
                          _gstRow('IGST', invoice.igst),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Line Items ──
              if (invoice.lineItems != null && invoice.lineItems!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Line Items',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ...invoice.lineItems!.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['description']?.toString() ?? '',
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(
                                        (item['amount'] as num?) ?? 0),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Payments ──
              if (invoice.payments != null && invoice.payments!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment History',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ...invoice.payments!.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      size: 16, color: KTColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${p['mode']?.toString() ?? ''} · ${p['date']?.toString() ?? ''}',
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(
                                        (p['amount'] as num?) ?? 0),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: KTColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _gstRow(String label, num amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: KTColors.textSecondary)),
          Text(_formatCurrency(amount),
              style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
