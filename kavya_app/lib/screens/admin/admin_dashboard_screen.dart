import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/intelligence_provider.dart';
import '../../utils/indian_format.dart';

/// Admin Command Center — Pulse Bar KPIs + Live Alert Feed + Trip Summary.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  // Deep navy palette per spec
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
    final dashAsync = ref.watch(adminDashboardProvider);
    final alertsAsync = ref.watch(notificationsProvider);
    final fleetHealthAsync = ref.watch(fleetMaintenanceProvider);
    final leaderboardAsync = ref.watch(driverLeaderboardProvider);
    final eventsAsync = ref.watch(groupedEventsProvider);

    return Scaffold(
      backgroundColor: _navyBg,
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _amber)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _red),
              const SizedBox(height: 12),
              Text('Failed to load dashboard', style: TextStyle(color: _textPrimary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminDashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final alerts = alertsAsync.valueOrNull ?? [];
          return RefreshIndicator(
            color: _amber,
            onRefresh: () async {
              ref.invalidate(adminDashboardProvider);
              ref.invalidate(notificationsProvider);
              ref.invalidate(fleetMaintenanceProvider);
              ref.invalidate(driverLeaderboardProvider);
              ref.invalidate(groupedEventsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Pulse Bar: 4 KPI Cards ───
                _buildPulseBar(data),
                const SizedBox(height: 24),

                // ─── Live Alert Feed ───
                _sectionHeader('Live Alert Feed'),
                const SizedBox(height: 10),
                if (alerts.isEmpty)
                  _emptyCard('No active alerts')
                else
                  ...alerts.take(5).map((a) => _alertTile(a as Map<String, dynamic>)),
                const SizedBox(height: 24),

                // ─── Revenue Snapshot ───
                _sectionHeader('Revenue Snapshot'),
                const SizedBox(height: 10),
                _revenueCard(data),
                const SizedBox(height: 24),

                // ─── Fleet Health (Intelligence) ───
                _sectionHeader('Fleet Health'),
                const SizedBox(height: 10),
                _buildFleetHealth(fleetHealthAsync),
                const SizedBox(height: 24),

                // ─── Driver Leaderboard (Intelligence) ───
                _sectionHeader('Driver Leaderboard'),
                const SizedBox(height: 10),
                _buildLeaderboard(leaderboardAsync),
                const SizedBox(height: 24),

                // ─── Intelligence Events ───
                _sectionHeader('Intelligence Events'),
                const SizedBox(height: 10),
                _buildRecentEvents(eventsAsync),
                const SizedBox(height: 24),

                // ─── Quick Actions ───
                _sectionHeader('Quick Actions'),
                const SizedBox(height: 10),
                _quickActions(context),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Pulse Bar ───
  Widget _buildPulseBar(Map<String, dynamic> data) {
    final activeTrips = data['active_trips'] ?? data['trip_stats']?['active'] ?? 0;
    final fleetOnRoad = data['fleet_on_road'] ?? data['fleet_stats']?['on_trip'] ?? 0;
    final revenueToday = (data['revenue_today'] ?? data['monthly_revenue'] ?? 0).toDouble();
    final pendingApprovals = data['pending_approvals'] ?? 0;

    return Row(
      children: [
        _kpiCard('Active Trips', '$activeTrips', Icons.route, _blue),
        const SizedBox(width: 8),
        _kpiCard('Fleet on Road', '$fleetOnRoad', Icons.local_shipping, _green),
        const SizedBox(width: 8),
        _kpiCard('Revenue', IndianFormat.currencyCompact(revenueToday), Icons.currency_rupee, _amber),
        const SizedBox(width: 8),
        _kpiCard('Approvals', '$pendingApprovals', Icons.pending_actions, pendingApprovals > 0 ? _red : _green),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: _textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─── Alert Feed ───
  Widget _alertTile(Map<String, dynamic> alert) {
    final severity = (alert['severity'] ?? alert['type'] ?? 'info').toString().toLowerCase();
    final Color dot;
    if (severity.contains('critical') || severity.contains('high') || severity.contains('error')) {
      dot = _red;
    } else if (severity.contains('warn') || severity.contains('medium')) {
      dot = _amber;
    } else {
      dot = _blue;
    }

    final message = alert['message'] ?? alert['title'] ?? 'Alert';
    final time = alert['created_at'] != null
        ? IndianFormat.relativeTime(DateTime.tryParse(alert['created_at'].toString()) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(message.toString(), style: TextStyle(color: _textPrimary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
          if (time.isNotEmpty)
            Text(time, style: TextStyle(color: _textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Revenue Card ───
  Widget _revenueCard(Map<String, dynamic> data) {
    final revenue = (data['monthly_revenue'] ?? 0).toDouble();
    final collections = (data['collections'] ?? 0).toDouble();
    final receivables = (data['receivables'] ?? 0).toDouble();
    final expenses = (data['expenses'] ?? 0).toDouble();
    final profit = (data['profit'] ?? (revenue - expenses)).toDouble();

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
              _revenueItem('Revenue', IndianFormat.currencyCompact(revenue), _green),
              _revenueItem('Collections', IndianFormat.currencyCompact(collections), _blue),
              _revenueItem('Receivables', IndianFormat.currencyCompact(receivables), _amber),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _cardBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _revenueItem('Expenses', IndianFormat.currencyCompact(expenses), _red),
              _revenueItem('Profit', IndianFormat.currencyCompact(profit), profit >= 0 ? _green : _red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revenueItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: _textMuted, fontSize: 11)),
      ],
    );
  }

  // ─── Quick Actions ───
  Widget _quickActions(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionChip(context, 'Trips', Icons.route, '/admin/fleet'),
        _actionChip(context, 'Vehicles', Icons.local_shipping, '/admin/fleet'),
        _actionChip(context, 'Finance', Icons.account_balance_wallet, '/admin/finance'),
        _actionChip(context, 'Team', Icons.people, '/admin/team'),
      ],
    );
  }

  Widget _actionChip(BuildContext context, String label, IconData icon, String route) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: _amber),
      label: Text(label, style: TextStyle(color: _textPrimary, fontSize: 13)),
      backgroundColor: _card,
      side: BorderSide(color: _cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => context.go(route),
    );
  }

  // ─── Helpers ───
  Widget _sectionHeader(String title) {
    return Text(title, style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600));
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Center(child: Text(message, style: TextStyle(color: _textMuted))),
    );
  }

  // ─── Fleet Health Widget ───
  Widget _buildFleetHealth(AsyncValue<Map<String, dynamic>> asyncData) {
    return asyncData.when(
      loading: () => _emptyCard('Loading fleet health...'),
      error: (_, __) => _emptyCard('Fleet health unavailable'),
      data: (data) {
        final healthy = data['healthy_count'] ?? 0;
        final monitor = data['monitor_count'] ?? 0;
        final highRisk = data['high_risk_count'] ?? 0;
        final total = data['total_vehicles'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _healthBadge('Healthy', healthy, _green),
                  _healthBadge('Monitor', monitor, _amber),
                  _healthBadge('High Risk', highRisk, _red),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? healthy / total : 0,
                    backgroundColor: _red.withAlpha(60),
                    color: _green,
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _healthBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Text('$count', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: _textMuted, fontSize: 11)),
      ],
    );
  }

  // ─── Driver Leaderboard Widget ───
  Widget _buildLeaderboard(AsyncValue<Map<String, dynamic>> asyncData) {
    return asyncData.when(
      loading: () => _emptyCard('Loading leaderboard...'),
      error: (_, __) => _emptyCard('Leaderboard unavailable'),
      data: (data) {
        final top5 = (data['top_5'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (top5.isEmpty) return _emptyCard('No driver scores available');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < top5.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == 0 ? _amber : (i == 1 ? _blue : _card),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}', style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Driver #${top5[i]['driver_id']}', style: TextStyle(color: _textPrimary, fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _tierColor(top5[i]['tier']).withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (top5[i]['avg_score'] as num?)?.toStringAsFixed(0) ?? '-',
                          style: TextStyle(color: _tierColor(top5[i]['tier']), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _tierColor(String? tier) {
    switch (tier) {
      case 'elite': return _green;
      case 'good': return _blue;
      case 'needs_attention': return _amber;
      case 'high_risk': return _red;
      default: return _textMuted;
    }
  }

  // ─── Recent Events Widget (Priority-Colored, Grouped) ───
  Widget _buildRecentEvents(AsyncValue<List<dynamic>> asyncData) {
    return asyncData.when(
      loading: () => _emptyCard('Loading events...'),
      error: (_, __) => _emptyCard('Events unavailable'),
      data: (events) {
        if (events.isEmpty) return _emptyCard('No recent intelligence events');
        return Column(
          children: events.take(8).map((e) {
            final ev = e as Map<String, dynamic>;
            final priority = (ev['priority'] ?? 'P2').toString();
            final type = (ev['event_type'] ?? '').toString();
            final count = ev['total_occurrences'] ?? ev['occurrence_count'] ?? 1;
            final label = type.replaceAll('.', ' → ').replaceAll('_', ' ');
            final acked = ev['is_acknowledged'] == true;
            final lastSeen = ev['last_seen_at'] ?? ev['triggered_at'];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: _priorityColor(priority), width: 4),
                  top: BorderSide(color: _cardBorder),
                  right: BorderSide(color: _cardBorder),
                  bottom: BorderSide(color: _cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _priorityColor(priority).withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(priority, style: TextStyle(color: _priorityColor(priority), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count > 1 ? '$label (×$count)' : label,
                          style: TextStyle(color: acked ? _textMuted : _textPrimary, fontSize: 13,
                            decoration: acked ? TextDecoration.lineThrough : null),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (lastSeen != null)
                          Text(
                            _relativeTime(lastSeen.toString()),
                            style: TextStyle(color: _textMuted, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  if (ev['escalation_level'] != null && (ev['escalation_level'] as num) > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.trending_up, size: 14, color: _red),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'P0': return _red;
      case 'P1': return _amber;
      case 'P2': return const Color(0xFFEAB308); // yellow-500
      case 'P3': return _textMuted;
      default: return _textMuted;
    }
  }

  String _relativeTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
