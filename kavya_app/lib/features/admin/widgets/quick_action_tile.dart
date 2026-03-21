import 'package:flutter/material.dart';
import '../../../core/theme/kt_colors.dart';

/// Small icon + label tile for the Quick Actions grid.
class QuickActionTile extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KTColors.darkBorder, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KTColors.darkTextPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
