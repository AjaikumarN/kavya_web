import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../services/api_service.dart';

final _notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ApiService();
  final data = await api.getNotifications();
  return data.cast<Map<String, dynamic>>();
});

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(_notificationsProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Notifications',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(_notificationsProvider);
        },
        child: notifications.when(
          loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
          error: (e, _) => KTErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_notificationsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const KTEmptyState(
                icon: Icons.notifications_none,
                title: 'No Notifications',
                subtitle: 'You\'re all caught up!',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                final title = n['title']?.toString() ?? '';
                final body = n['body']?.toString() ?? '';
                final time = n['created_at']?.toString() ?? '';
                final isRead = n['is_read'] as bool? ?? false;
                final id = n['id']?.toString() ?? '';
                final type = n['type']?.toString() ?? '';

                IconData icon;
                Color iconColor;
                switch (type) {
                  case 'alert':
                    icon = Icons.warning_amber;
                    iconColor = KTColors.danger;
                    break;
                  case 'info':
                    icon = Icons.info_outline;
                    iconColor = KTColors.info;
                    break;
                  case 'success':
                    icon = Icons.check_circle_outline;
                    iconColor = KTColors.success;
                    break;
                  default:
                    icon = Icons.notifications_outlined;
                    iconColor = KTColors.textSecondary;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isRead ? null : KTColors.primary.withValues(alpha: 0.04),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      if (!isRead) {
                        try {
                          await ApiService().markNotificationRead(id);
                          ref.invalidate(_notificationsProvider);
                        } catch (_) {}
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight:
                                        isRead ? FontWeight.w500 : FontWeight.w600,
                                    color: KTColors.textPrimary,
                                  ),
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    body,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: KTColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: KTColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: const BoxDecoration(
                                color: KTColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
