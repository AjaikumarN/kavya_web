import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_dashboard_provider.dart';

/// Admin Team Overview — driver statuses, role distribution.
class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

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

    return Scaffold(
      backgroundColor: _navyBg,
      body: RefreshIndicator(
        color: _amber,
        onRefresh: () async => ref.invalidate(adminDashboardProvider),
        child: dashAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _amber)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: _red),
                const SizedBox(height: 12),
                Text('Failed to load team data', style: TextStyle(color: _textPrimary)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(adminDashboardProvider), child: const Text('Retry')),
              ],
            ),
          ),
          data: (data) {
            final totalDrivers = data['total_drivers'] ?? data['driver_count'] ?? 0;
            final activeDrivers = data['active_drivers'] ?? 0;
            final totalUsers = data['total_users'] ?? data['user_count'] ?? 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Team Summary ───
                Text('Team Overview', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statCard('Total Users', '$totalUsers', Icons.people, _blue),
                    const SizedBox(width: 8),
                    _statCard('Drivers', '$totalDrivers', Icons.person, _amber),
                    const SizedBox(width: 8),
                    _statCard('On Duty', '$activeDrivers', Icons.verified_user, _green),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Role Distribution ───
                Text('Role Distribution', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _roleDistribution(data),
                const SizedBox(height: 24),

                // ─── Driver Status ───
                Text('Driver Status', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _driverStatusCard(totalDrivers, activeDrivers),
                const SizedBox(height: 32),
              ],
            );
          },
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

  Widget _roleDistribution(Map<String, dynamic> data) {
    final roles = <String, int>{
      'Admin': 1,
      'Fleet Manager': data['fleet_manager_count'] as int? ?? 1,
      'Accountant': data['accountant_count'] as int? ?? 1,
      'Associate': data['associate_count'] as int? ?? 2,
      'Driver': data['driver_count'] as int? ?? (data['total_drivers'] as int? ?? 0),
      'Pump Operator': data['pump_operator_count'] as int? ?? 1,
    };

    final colors = [_blue, const Color(0xFF475569), _green, _amber, const Color(0xFF8B5CF6), const Color(0xFFF59E0B)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < roles.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(roles.keys.elementAt(i), style: TextStyle(color: _textMuted, fontSize: 13))),
                  Text('${roles.values.elementAt(i)}', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _driverStatusCard(int total, int active) {
    final idle = total - active;
    final pct = total > 0 ? (active / total * 100) : 0.0;

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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusDot('On Duty', active, _green),
              _statusDot('Off Duty', idle, _red),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: _red.withAlpha(50),
              color: _green,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text('${pct.toStringAsFixed(0)}% utilization', style: TextStyle(color: _textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusDot(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: _textMuted, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
