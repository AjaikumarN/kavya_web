import 'package:flutter/material.dart';
import '../../../core/theme/kt_colors.dart';

/// Role health card used on admin dashboard.
class RoleHealthTile extends StatelessWidget {
  final String role;
  final String label;
  final String detailText;
  final String statusLabel;
  final Color statusColor;

  const RoleHealthTile({
    super.key,
    required this.role,
    required this.label,
    required this.detailText,
    required this.statusLabel,
    required this.statusColor,
  });

  String get _initials {
    final words = label.split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}';
    return label.substring(0, label.length.clamp(0, 2)).toUpperCase();
  }

  Color get _avatarColor {
    switch (role) {
      case 'MANAGER':
        return KTColors.info;
      case 'PROJECT_ASSOCIATE':
        return KTColors.amber600;
      case 'FLEET_MANAGER':
        return KTColors.success;
      case 'ACCOUNTANT':
        return const Color(0xFF7C3AED);
      case 'DRIVER':
        return Colors.grey;
      default:
        return KTColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: KTColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _avatarColor.withAlpha(40),
            child: Text(
              _initials,
              style: TextStyle(
                color: _avatarColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: KTColors.darkTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(detailText,
                    style: const TextStyle(
                        color: KTColors.darkTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
