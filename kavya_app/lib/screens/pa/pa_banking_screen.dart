import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/theme/kt_text_styles.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/notification_bell_widget.dart';
import '../../providers/fleet_dashboard_provider.dart'; // apiServiceProvider

final _myBankingEntriesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get('/banking/entries', queryParameters: {'my_entries': true});
  if (response is Map && response['data'] is List) return response['data'] as List<dynamic>;
  if (response is List) return response;
  return [];
});

final _approvedBankingEntriesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response =
      await api.get('/banking/entries', queryParameters: {'status': 'approved'});
  if (response is Map && response['data'] is List) return response['data'] as List<dynamic>;
  if (response is List) return response;
  return [];
});

class PABankingScreen extends ConsumerStatefulWidget {
  const PABankingScreen({super.key});

  @override
  ConsumerState<PABankingScreen> createState() => _PABankingScreenState();
}

class _PABankingScreenState extends ConsumerState<PABankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Text('Banking', style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
        actions: const [NotificationBellWidget()],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: KTColors.primary,
          labelColor: KTColors.primary,
          unselectedLabelColor: KTColors.darkTextSecondary,
          tabs: const [Tab(text: 'My Entries'), Tab(text: 'Approved')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: KTColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        onPressed: () => _showNewEntrySheet(context),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _EntriesTab(provider: _myBankingEntriesProvider),
          _EntriesTab(provider: _approvedBankingEntriesProvider),
        ],
      ),
    );
  }

  void _showNewEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KTColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NewBankingEntrySheet(
        onSaved: () {
          ref.invalidate(_myBankingEntriesProvider);
          ref.invalidate(_approvedBankingEntriesProvider);
        },
      ),
    );
  }
}

class _EntriesTab extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<dynamic>>> provider;
  const _EntriesTab({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);

    return asyncValue.when(
      loading: () => const KTLoadingShimmer(type: ShimmerType.list),
      error: (e, _) =>
          KTErrorState(message: e.toString(), onRetry: () => ref.invalidate(provider)),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text('No entries found',
                style: KTTextStyles.body.copyWith(color: KTColors.darkTextSecondary)),
          );
        }
        return RefreshIndicator(
          color: KTColors.primary,
          backgroundColor: KTColors.darkSurface,
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = Map<String, dynamic>.from(entries[i] as Map);
              return _BankingEntryCard(entry: entry);
            },
          ),
        );
      },
    );
  }
}

class _BankingEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _BankingEntryCard({required this.entry});

  Color _statusColor(String? s) {
    switch (s) {
      case 'approved': return KTColors.success;
      case 'pending': return KTColors.warning;
      case 'rejected': return KTColors.danger;
      default: return KTColors.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = entry['status'] as String?;
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final type = entry['transaction_type'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KTColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KTColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (type == 'credit' ? KTColors.success : KTColors.danger).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'credit' ? Icons.arrow_downward : Icons.arrow_upward,
              color: type == 'credit' ? KTColors.success : KTColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['description'] ?? entry['reference_number'] ?? '—',
                  style: KTTextStyles.body.copyWith(color: KTColors.darkTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry['account_name'] ?? '',
                  style: KTTextStyles.bodySmall.copyWith(color: KTColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: KTTextStyles.body.copyWith(
                  color: type == 'credit' ? KTColors.success : KTColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status ?? '',
                  style: TextStyle(color: _statusColor(status), fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── New Banking Entry Bottom Sheet ───────────────────────────────────────────

class _NewBankingEntrySheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _NewBankingEntrySheet({required this.onSaved});

  @override
  ConsumerState<_NewBankingEntrySheet> createState() => _NewBankingEntrySheetState();
}

class _NewBankingEntrySheetState extends ConsumerState<_NewBankingEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  String _txType = 'debit';
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/banking/entries', data: {
        'description': _descCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text.trim()),
        'transaction_type': _txType,
        'reference_number': _referenceCtrl.text.trim(),
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Entry submitted for approval'), backgroundColor: KTColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KTColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('New Banking Entry',
                style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
            const SizedBox(height: 16),

            // Transaction type selector
            Row(
              children: ['debit', 'credit'].map((t) {
                final selected = _txType == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _txType = t),
                    child: Container(
                      margin: EdgeInsets.only(right: t == 'debit' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? (t == 'debit' ? KTColors.danger : KTColors.success).withOpacity(0.2)
                            : KTColors.darkBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? (t == 'debit' ? KTColors.danger : KTColors.success)
                              : KTColors.darkBorder,
                        ),
                      ),
                      child: Text(
                        t == 'debit' ? 'Debit (Payment)' : 'Credit (Receipt)',
                        textAlign: TextAlign.center,
                        style: KTTextStyles.bodySmall.copyWith(
                          color: selected
                              ? (t == 'debit' ? KTColors.danger : KTColors.success)
                              : KTColors.darkTextSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            _f('Description', _descCtrl),
            _f('Amount (₹)', _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                }),
            _f('Reference / UTR Number', _referenceCtrl, required: false),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KTColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit for Approval',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _f(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: KTColors.darkTextPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: KTColors.darkTextSecondary),
            filled: true,
            fillColor: KTColors.darkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: KTColors.darkBorder),
            ),
          ),
          validator: validator ??
              (required
                  ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
                  : null),
        ),
      );
}
