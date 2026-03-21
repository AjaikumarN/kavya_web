import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/theme/kt_text_styles.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/fleet_dashboard_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _driverPaymentsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.get('/accountant/driver-payments');
  if (result is Map) return Map<String, dynamic>.from(result['data'] ?? result);
  return {'pending': [], 'history': [], 'total_pending': 0.0, 'total_paid': 0.0};
});

// Keep the old receivables provider for backward compatibility (used elsewhere)
final receivablesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getReceivables();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AccountantPaymentsScreen extends ConsumerStatefulWidget {
  const AccountantPaymentsScreen({super.key});

  @override
  ConsumerState<AccountantPaymentsScreen> createState() => _AccountantPaymentsScreenState();
}

class _AccountantPaymentsScreenState extends ConsumerState<AccountantPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  Razorpay? _razorpay;
  int? _activePaymentId;
  double _activeAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse r) {
    if (_activePaymentId == null) return;
    _confirmPayment(_activePaymentId!, {
      'razorpay_payment_id': r.paymentId,
      'razorpay_order_id': r.orderId,
      'transaction_ref': r.paymentId,
      'payment_method': 'UPI',
    });
  }

  void _handleRazorpayError(PaymentFailureResponse r) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${r.message}'), backgroundColor: KTColors.danger),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _razorpay?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_driverPaymentsProvider);
    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        title: const Text('Driver Payments'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: KTColors.primary,
          labelColor: KTColors.primary,
          unselectedLabelColor: KTColors.textSecondary,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'History')],
        ),
      ),
      body: state.when(
        loading: () => const KTLoadingShimmer(type: ShimmerType.list),
        error: (e, _) => KTErrorState(
            message: e.toString(), onRetry: () => ref.invalidate(_driverPaymentsProvider)),
        data: (data) {
          final pending = List<Map<String, dynamic>>.from(data['pending'] ?? []);
          final history = List<Map<String, dynamic>>.from(data['history'] ?? []);
          return TabBarView(
            controller: _tabs,
            children: [
              _buildPendingList(pending, (data['total_pending'] as num? ?? 0).toDouble()),
              _buildHistoryList(history, (data['total_paid'] as num? ?? 0).toDouble()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingList(List<Map<String, dynamic>> payments, double total) {
    if (payments.isEmpty) {
      return const KTEmptyState(
        title: 'No pending payments',
        subtitle: 'All driver payments are up to date.',
        lottieAsset: 'assets/lottie/empty_box.json',
      );
    }
    return RefreshIndicator(
      color: KTColors.primary,
      onRefresh: () async => ref.invalidate(_driverPaymentsProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryBanner(total, payments.length, KTColors.warning, 'Total Pending'),
          ...payments.map((p) => _PaymentCard(
                payment: p, inr: _inr, isHistory: false, onPay: _openPaySheet)),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> payments, double total) {
    if (payments.isEmpty) {
      return const KTEmptyState(
        title: 'No payment history',
        subtitle: 'Completed payments will appear here.',
        lottieAsset: 'assets/lottie/empty_box.json',
      );
    }
    return RefreshIndicator(
      color: KTColors.primary,
      onRefresh: () async => ref.invalidate(_driverPaymentsProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryBanner(total, payments.length, KTColors.success, 'Total Paid'),
          ...payments.map((p) => _PaymentCard(payment: p, inr: _inr, isHistory: true)),
        ],
      ),
    );
  }

  Widget _summaryBanner(double amount, int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: KTColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_inr.format(amount),
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
        Text('$count payment${count == 1 ? '' : 's'}',
            style: const TextStyle(color: KTColors.textMuted, fontSize: 13)),
      ]),
    );
  }

  void _openPaySheet(Map<String, dynamic> payment) {
    final payId = payment['id'] as int?;
    if (payId == null) return;
    _activePaymentId = payId;
    _activeAmount = (payment['amount'] as num? ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KTColors.darkElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PaySheet(
        payment: payment,
        inr: _inr,
        onManualPay: (txRef, method) {
          Navigator.pop(ctx);
          _confirmPayment(payId, {'transaction_ref': txRef, 'payment_method': method});
        },
        onRazorpay: () {
          Navigator.pop(ctx);
          _launchRazorpay(payment);
        },
      ),
    );
  }

  void _launchRazorpay(Map<String, dynamic> payment) {
    // TODO: replace '' with actual Razorpay API key from config when purchased
    const razorpayKey = '';
    if (razorpayKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Razorpay key not configured yet. Use manual payment.'),
        backgroundColor: KTColors.warning,
      ));
      _openPaySheet(payment); // reopen manual sheet
      return;
    }
    _razorpay?.open({
      'key': razorpayKey,
      'amount': (_activeAmount * 100).toInt(),
      'currency': 'INR',
      'name': 'Kavya Transports',
      'description': payment['remarks'] ?? 'Driver Payment',
    });
  }

  Future<void> _confirmPayment(int paymentId, Map<String, dynamic> extra) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/accountant/driver-payments/$paymentId/mark-paid', data: extra);
      ref.invalidate(_driverPaymentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment marked as completed'),
          backgroundColor: KTColors.success,
        ));
        _tabs.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger));
      }
    }
  }
}

// ── Payment Card ──────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final NumberFormat inr;
  final bool isHistory;
  final void Function(Map<String, dynamic>)? onPay;

  const _PaymentCard(
      {required this.payment,
      required this.inr,
      this.isHistory = false,
      this.onPay});

  @override
  Widget build(BuildContext context) {
    final isTripPay = (payment['kind'] as String? ?? '') == 'trip_pay';
    final amount = (payment['amount'] as num? ?? 0).toDouble();
    final kindColor = isTripPay ? KTColors.primary : KTColors.info;
    final kindIcon = isTripPay ? Icons.local_shipping_outlined : Icons.receipt_long_outlined;
    final kindLabel = payment['kind_label']?.toString() ??
        (isTripPay ? 'Trip Payment' : 'Expense Reimbursement');
    final sourceRef = payment['source_ref']?.toString() ?? '';
    final payNum = payment['payment_number']?.toString() ?? '';
    final txRef = payment['transaction_ref']?.toString();
    final rzpRef = payment['razorpay_payment_id']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KTColors.darkElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isHistory ? KTColors.darkBorder : kindColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kindColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(kindIcon, size: 18, color: kindColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kindLabel,
                  style: const TextStyle(
                      color: KTColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Text(sourceRef,
                  style: TextStyle(
                      color: kindColor, fontSize: 11, fontFamily: 'monospace')),
            ]),
          ),
          Text(inr.format(amount),
              style: TextStyle(
                  color: isHistory ? KTColors.success : KTColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ]),
        const SizedBox(height: 10),
        // Details
        _row(Icons.tag, payNum),
        if ((payment['remarks']?.toString() ?? '').isNotEmpty)
          _row(Icons.notes_outlined, payment['remarks']!.toString()),
        if ((payment['payment_date']?.toString() ?? '').isNotEmpty)
          _row(Icons.calendar_today_outlined, payment['payment_date']!.toString()),
        if (txRef != null && txRef.isNotEmpty) _row(Icons.numbers, 'UTR: $txRef'),
        if (rzpRef != null && rzpRef.isNotEmpty)
          _row(Icons.verified_outlined, 'Razorpay: $rzpRef'),
        // Pay button
        if (!isHistory && onPay != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Pay Now'),
              style: FilledButton.styleFrom(
                  backgroundColor: KTColors.primary,
                  foregroundColor: KTColors.darkBg,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              onPressed: () => onPay!(payment),
            ),
          ),
        ],
        if (isHistory)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Icon(Icons.check_circle, size: 13, color: KTColors.success),
              const SizedBox(width: 4),
              const Text('Paid', style: TextStyle(color: KTColors.success, fontSize: 12)),
            ]),
          ),
      ]),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Icon(icon, size: 12, color: KTColors.textMuted),
          const SizedBox(width: 5),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: KTColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
        ]),
      );
}

// ── Payment Sheet ─────────────────────────────────────────────────────────────

class _PaySheet extends StatefulWidget {
  final Map<String, dynamic> payment;
  final NumberFormat inr;
  final void Function(String ref, String method) onManualPay;
  final VoidCallback onRazorpay;

  const _PaySheet(
      {required this.payment,
      required this.inr,
      required this.onManualPay,
      required this.onRazorpay});

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String _method = 'BANK_TRANSFER';
  final _refCtrl = TextEditingController();

  static const _methods = [
    ('BANK_TRANSFER', 'Bank Transfer / NEFT'),
    ('UPI', 'UPI'),
    ('CASH', 'Cash'),
    ('CHEQUE', 'Cheque'),
  ];

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.payment['amount'] as num? ?? 0).toDouble();
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Center(
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: KTColors.darkBorder,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Record Payment', style: KTTextStyles.h3.copyWith(color: KTColors.textPrimary)),
        const SizedBox(height: 4),
        Text(
            '${widget.payment['kind_label'] ?? 'Payment'}  ·  ${widget.inr.format(amount)}',
            style: const TextStyle(color: KTColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        // Razorpay CTA
        OutlinedButton.icon(
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Pay via Razorpay'),
          style: OutlinedButton.styleFrom(
              foregroundColor: KTColors.primary,
              side: const BorderSide(color: KTColors.primary),
              minimumSize: const Size(double.infinity, 44)),
          onPressed: widget.onRazorpay,
        ),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: Divider(color: KTColors.darkBorder)),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('or manually',
                  style: TextStyle(color: KTColors.textMuted, fontSize: 12))),
          Expanded(child: Divider(color: KTColors.darkBorder)),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _method,
          dropdownColor: KTColors.darkElevated,
          style: const TextStyle(color: KTColors.textPrimary),
          decoration: const InputDecoration(
              labelText: 'Payment Method',
              labelStyle: TextStyle(color: KTColors.textSecondary)),
          items: _methods
              .map((m) => DropdownMenuItem(
                  value: m.$1,
                  child: Text(m.$2,
                      style: const TextStyle(color: KTColors.textPrimary))))
              .toList(),
          onChanged: (v) => setState(() => _method = v ?? _method),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _refCtrl,
          style: const TextStyle(color: KTColors.textPrimary),
          decoration: const InputDecoration(
              labelText: 'UTR / Transaction Reference',
              labelStyle: TextStyle(color: KTColors.textSecondary)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: KTColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => widget.onManualPay(_refCtrl.text.trim(), _method),
            child: const Text('Confirm Payment',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

