import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../utils/indian_format.dart';

/// Admin Alerts/Notifications screen — full list of system alerts.
class AdminAlertsScreen extends ConsumerWidget {
  const AdminAlertsScreen({super.key});

  static const _navyBg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);
  static const _textPrimary = Color(0xFFF1F5F9);
  static const _textMuted = Color(0xFF94A3B8);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _blue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(adminNotificationsProvider);

    return Scaffold(
      backgroundColor: _navyBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Alerts & Notifications'),
      ),
      body: RefreshIndicator(
        color: _amber,
        onRefresh: () async => ref.invalidate(adminNotificationsProvider),
        child: alertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _amber)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: _red),
                const SizedBox(height: 12),
                Text('Failed to load alerts', style: TextStyle(color: _textPrimary)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => ref.invalidate(adminNotificationsProvider), child: const Text('Retry')),
              ],
            ),
          ),
          data: (alerts) {
            if (alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: _textMuted),
                    const SizedBox(height: 12),
                    Text('No alerts', style: TextStyle(color: _textMuted, fontSize: 16)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, i) {
                final alert = alerts[i] is Map<String, dynamic> ? alerts[i] as Map<String, dynamic> : <String, dynamic>{};
                return _alertCard(alert);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _alertCard(Map<String, dynamic> alert) {
    final severity = (alert['severity'] ?? alert['type'] ?? 'info').toString().toLowerCase();
    final Color accent;
    final IconData icon;
    if (severity.contains('critical') || severity.contains('high') || severity.contains('error')) {
      accent = _red;
      icon = Icons.error;
    } else if (severity.contains('warn') || severity.contains('medium')) {
      accent = _amber;
      icon = Icons.warning_amber;
    } else {
      accent = _blue;
      icon = Icons.info_outline;
    }

    final message = alert['message'] ?? alert['title'] ?? 'Alert';
    final time = alert['created_at'] != null
        ? IndianFormat.relativeTime(DateTime.tryParse(alert['created_at'].toString()) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.toString(), style: TextStyle(color: _textPrimary, fontSize: 14)),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(color: _textMuted, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
