import 'package:flutter/material.dart';
import '../theme/kt_colors.dart';
import '../theme/kt_text_styles.dart';

class KTStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final double? trend;
  final VoidCallback? onTap;

  const KTStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    required this.icon,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: KTTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: KTTextStyles.h2.copyWith(color: color)),
            if (subtitle != null || trend != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (subtitle != null)
                    Expanded(child: Text(subtitle!, style: KTTextStyles.bodySmall)),
                  if (trend != null) ...[
                    Icon(
                      trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: trend! >= 0 ? KTColors.success : KTColors.danger,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(1)}%',
                      style: KTTextStyles.bodySmall.copyWith(
                        color: trend! >= 0 ? KTColors.success : KTColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
