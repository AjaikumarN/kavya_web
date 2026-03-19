import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../utils/indian_format.dart';

/// Admin Fleet Overview — vehicle status, trip distribution, fleet utilization.
class AdminFleetScreen extends ConsumerWidget {
  const AdminFleetScreen({super.key});

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
    final fleetAsync = ref.watch(fleetStatsProvider);
    final tripAsync = ref.watch(tripStatsProvider);

    return Scaffold(
      backgroundColor: _navyBg,
      body: RefreshIndicator(
        color: _amber,
        onRefresh: () async {
          ref.invalidate(fleetStatsProvider);
          ref.invalidate(tripStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Fleet Status ───
            Text('Fleet Status', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            fleetAsync.when(
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: _amber))),
              error: (e, _) => _errorCard('Failed to load fleet stats', () => ref.invalidate(fleetStatsProvider)),
              data: (fleet) {
                final total = fleet['total_vehicles'] ?? 0;
                final available = fleet['available'] ?? 0;
                final onTrip = fleet['on_trip'] ?? 0;
                final maintenance = fleet['maintenance'] ?? fleet['in_maintenance'] ?? 0;
                return Row(
                  children: [
                    _statCard('Total', '$total', Icons.directions_car, _blue),
                    const SizedBox(width: 8),
                    _statCard('Available', '$available', Icons.check_circle_outline, _green),
                    const SizedBox(width: 8),
                    _statCard('On Trip', '$onTrip', Icons.route, _amber),
                    const SizedBox(width: 8),
                    _statCard('Maint.', '$maintenance', Icons.build, _red),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── Trip Distribution ───
            Text('Trip Distribution', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            tripAsync.when(
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: _amber))),
              error: (e, _) => _errorCard('Failed to load trip stats', () => ref.invalidate(tripStatsProvider)),
              data: (trips) {
                final statuses = <String, int>{};
                for (final entry in trips.entries) {
                  final val = entry.value;
                  if (val is int) {
                    statuses[entry.key.toString()] = val;
                  }
                }
                if (statuses.isEmpty) {
                  return _emptyCard('No trip data available');
                }
                return _tripDistribution(statuses);
              },
            ),
            const SizedBox(height: 24),

            // ─── Fleet Utilization ───
            Text('Fleet Utilization', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            fleetAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (fleet) {
                final total = (fleet['total_vehicles'] ?? 1) as int;
                final onTrip = (fleet['on_trip'] ?? 0) as int;
                final pct = total > 0 ? (onTrip / total * 100) : 0.0;
                return _utilizationBar(pct);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
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
            Text(value, style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: _textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _tripDistribution(Map<String, int> statuses) {
    final total = statuses.values.fold(0, (a, b) => a + b);
    final colorMap = {
      'draft': Colors.grey,
      'pending': _amber,
      'assigned': _blue,
      'in_progress': const Color(0xFF8B5CF6),
      'completed': _green,
      'cancelled': _red,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: statuses.entries.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          final color = colorMap[e.key] ?? _blue;
          final label = e.key.replaceAll('_', ' ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 90, child: Text(label[0].toUpperCase() + label.substring(1), style: TextStyle(color: _textMuted, fontSize: 12))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: _cardBorder,
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 30, child: Text('${e.value}', textAlign: TextAlign.end, style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _utilizationBar(double pct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vehicles on road', style: TextStyle(color: _textMuted, fontSize: 13)),
              Text(IndianFormat.percent(pct), style: TextStyle(color: pct > 70 ? _green : _amber, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: _cardBorder,
              color: pct > 70 ? _green : _amber,
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10), border: Border.all(color: _cardBorder)),
      child: Center(child: Text(message, style: TextStyle(color: _textMuted))),
    );
  }

  Widget _errorCard(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10), border: Border.all(color: _cardBorder)),
      child: Column(
        children: [
          Text(message, style: TextStyle(color: _red)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text('Retry', style: TextStyle(color: _amber))),
        ],
      ),
    );
  }
}
