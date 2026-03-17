import 'package:flutter/material.dart';
import '../theme/kt_colors.dart';
import '../theme/kt_text_styles.dart';

enum AlertSeverity { high, medium, low }

class KTAlertCard extends StatelessWidget {
  final String title;
  final int count;
  final List<String> items;
  final AlertSeverity severity;
  final VoidCallback? onTap;
  final Widget? trailing;

  const KTAlertCard({
    super.key,
    required this.title,
    required this.count,
    required this.items,
    this.severity = AlertSeverity.low,
    this.onTap,
    this.trailing,
  });

  Color get _headerColor {
    switch (severity) {
      case AlertSeverity.high:
        return KTColors.danger;
      case AlertSeverity.medium:
        return KTColors.warning;
      case AlertSeverity.low:
        return KTColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _headerColor,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: KTTextStyles.label.copyWith(color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: KTTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: items.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _headerColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item, style: KTTextStyles.bodySmall),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}
