import 'package:flutter/material.dart';
import '../theme/kt_colors.dart';
import '../theme/kt_text_styles.dart';

class KTRoleBadge extends StatelessWidget {
  final String role;

  const KTRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = KTColors.roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        KTColors.roleLabel(role),
        style: KTTextStyles.label.copyWith(color: color, fontSize: 12),
      ),
    );
  }
}
