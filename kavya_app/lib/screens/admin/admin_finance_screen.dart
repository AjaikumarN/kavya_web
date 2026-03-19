import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../utils/indian_format.dart';

/// Admin Finance Overview — revenue, expenses, receivables, profit.
class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  static const _navyBg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _cardBorder = Color(0xFF334155);
  static const _textPrimary = Color(0xFFF1F5F9);
  static const _textMuted = Color(0xFF94A3B8);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finAsync = ref.watch(financeStatsProvider);

    return Scaffold(
      backgroundColor: _navyBg,
      body: RefreshIndicator(
        color: _amber,
        onRefresh: () async => ref.invalidate(financeStatsProvider),
        child: finAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _amber)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: _red),
                const SizedBox(height: 12),
                Text('Failed to load finance data', style: TextStyle(color: _textPrimary)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(financeStatsProvider), child: const Text('Retry')),
              ],
            ),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Monthly Summary ───
              Text('Monthly Summary', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _summaryGrid(data),
              const SizedBox(height: 24),

              // ─── Profit Margin ───
              Text('Profit Margin', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _profitCard(data),
              const SizedBox(height: 24),

              // ─── Cash Flow ───
              Text('Cash Position', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _cashFlowCard(data),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryGrid(Map<String, dynamic> data) {
    final revenue = (data['monthly_revenue'] ?? 0).toDouble();
    final collections = (data['collections'] ?? 0).toDouble();
    final receivables = (data['receivables'] ?? 0).toDouble();
    final expenses = (data['expenses'] ?? 0).toDouble();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _metricTile('Revenue', IndianFormat.currency(revenue), Icons.trending_up, _green),
        _metricTile('Collections', IndianFormat.currency(collections), Icons.account_balance, _blue),
        _metricTile('Receivables', IndianFormat.currency(receivables), Icons.pending_actions, _amber),
        _metricTile('Expenses', IndianFormat.currency(expenses), Icons.trending_down, _red),
      ],
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: _textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _profitCard(Map<String, dynamic> data) {
    final revenue = (data['monthly_revenue'] ?? 0).toDouble();
    final expenses = (data['expenses'] ?? 0).toDouble();
    final profit = (data['profit'] ?? (revenue - expenses)).toDouble();
    final margin = revenue > 0 ? (profit / revenue * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Profit', style: TextStyle(color: _textMuted, fontSize: 13)),
              Text(
                IndianFormat.currency(profit),
                style: TextStyle(color: profit >= 0 ? _green : _red, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Margin', style: TextStyle(color: _textMuted, fontSize: 13)),
              Text(IndianFormat.percent(margin), style: TextStyle(color: margin >= 0 ? _green : _red, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (margin.clamp(0, 100)) / 100,
              backgroundColor: _cardBorder,
              color: margin >= 15 ? _green : (margin >= 5 ? _amber : _red),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cashFlowCard(Map<String, dynamic> data) {
    final collections = (data['collections'] ?? 0).toDouble();
    final expenses = (data['expenses'] ?? 0).toDouble();
    final net = collections - expenses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          _cashRow('Inflow (Collections)', IndianFormat.currency(collections), _green),
          const SizedBox(height: 8),
          _cashRow('Outflow (Expenses)', IndianFormat.currency(expenses), _red),
          Divider(color: _cardBorder, height: 24),
          _cashRow('Net Cash Flow', IndianFormat.currency(net), net >= 0 ? _green : _red),
        ],
      ),
    );
  }

  Widget _cashRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _textMuted, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
