import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../core/theme/kt_text_styles.dart';
import '../../../core/widgets/kt_loading_shimmer.dart';
import '../../../core/widgets/kt_error_state.dart';
import '../../../services/api_service.dart';
import '../../../providers/fleet_dashboard_provider.dart';
import '../providers/manager_providers.dart';

class ManagerNotificationsScreen extends ConsumerWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(managerNotificationsProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: KTColors.darkTextPrimary), onPressed: () => context.pop()),
        title: Text('Notifications', style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final api = ref.read(apiServiceProvider);
                await api.patch('/my-notifications/mark-all-read');
                ref.invalidate(managerNotificationsProvider);
              } catch (_) {}
            },
            child: Text('Mark all read', style: TextStyle(color: KTColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: KTColors.primary,
        backgroundColor: KTColors.darkSurface,
        onRefresh: () async => ref.invalidate(managerNotificationsProvider),
        child: notifAsync.when(
          loading: () => const KTLoadingShimmer(type: ShimmerType.list),
          error: (e, _) => KTErrorState(message: e.toString(), onRetry: () => ref.invalidate(managerNotificationsProvider)),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_none, color: KTColors.darkTextSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text('No notifications', style: KTTextStyles.body.copyWith(color: KTColors.darkTextSecondary)),
                  ],
                ),
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (_, i) => _NotificationTile(
                notification: Map<String, dynamic>.from(notifications[i] as Map),
                onTap: () => _handleNotifTap(context, ref, Map<String, dynamic>.from(notifications[i] as Map)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleNotifTap(BuildContext context, WidgetRef ref, Map<String, dynamic> notif) async {
    // Mark as read
    try {
      final id = notif['id'];
      if (id != null && notif['read'] != true) {
        final api = ref.read(apiServiceProvider);
        await api.patch('/my-notifications/$id/read');
        ref.invalidate(managerNotificationsProvider);
      }
    } catch (_) {}

    // Navigate based on type
    final type = (notif['type'] ?? '').toString();
    final refId = notif['reference_id']?.toString();
    if (refId == null) return;
    if (type.contains('job')) {
      context.push('/manager/jobs/$refId');
    } else if (type.contains('vehicle') || type.contains('fleet')) {
      context.push('/manager/fleet/$refId');
    } else if (type.contains('expense') || type.contains('approval')) {
      context.push('/manager/approvals');
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] == true;
    final priority = (notification['priority'] ?? 'normal').toString();
    Color borderColor;
    switch (priority) {
      case 'high':
      case 'urgent':
        borderColor = KTColors.danger;
        break;
      case 'medium':
        borderColor = KTColors.warning;
        break;
      default:
        borderColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? KTColors.darkElevated : KTColors.darkElevated.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: borderColor, width: borderColor == Colors.transparent ? 0 : 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ────────────────────────────
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KTColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(notification['type']?.toString() ?? ''),
                  color: KTColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // ── Content ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'Notification',
                      style: KTTextStyles.body.copyWith(
                        color: KTColors.darkTextPrimary,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    if ((notification['message'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification['message'].toString(),
                        style: KTTextStyles.bodySmall.copyWith(color: KTColors.darkTextSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(notification['created_at']?.toString()),
                      style: TextStyle(color: KTColors.darkTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // ── Unread dot ──────────────────────
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: KTColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    if (type.contains('job')) return Icons.work_outline;
    if (type.contains('trip')) return Icons.route;
    if (type.contains('vehicle') || type.contains('fleet')) return Icons.local_shipping;
    if (type.contains('expense')) return Icons.receipt_long;
    if (type.contains('payment') || type.contains('banking')) return Icons.account_balance;
    return Icons.notifications_outlined;
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
