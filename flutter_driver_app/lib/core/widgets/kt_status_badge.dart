import 'package:flutter/material.dart';
import '../theme/kt_colors.dart';
import '../theme/kt_text_styles.dart';

class KTStatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const KTStatusBadge({super.key, required this.label, this.color});

  const KTStatusBadge.active({super.key}) : label = 'Active', color = KTColors.success;
  const KTStatusBadge.idle({super.key}) : label = 'Idle', color = KTColors.warning;
  const KTStatusBadge.pending({super.key}) : label = 'Pending', color = KTColors.warning;
  const KTStatusBadge.completed({super.key}) : label = 'Completed', color = KTColors.success;
  const KTStatusBadge.overdue({super.key}) : label = 'Overdue', color = KTColors.danger;

  factory KTStatusBadge.fromStatus(String status) {
    final Color c;
    switch (status.toLowerCase()) {
      case 'active':
      case 'moving':
      case 'completed':
      case 'paid':
      case 'approved':
        c = KTColors.success;
        break;
      case 'idle':
      case 'pending':
      case 'partially_paid':
      case 'in_transit':
      case 'in_progress':
        c = KTColors.warning;
        break;
      case 'overdue':
      case 'stopped':
      case 'rejected':
      case 'expired':
        c = KTColors.danger;
        break;
      case 'maintenance':
      case 'under_maintenance':
        c = KTColors.info;
        break;
      default:
        c = Colors.grey;
    }
    return KTStatusBadge(label: status.replaceAll('_', ' '), color: c);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? KTColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: KTTextStyles.bodySmall.copyWith(
          color: c,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
