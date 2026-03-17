import 'package:flutter/material.dart';
import '../theme/kt_colors.dart';
import '../theme/kt_text_styles.dart';

class KTErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const KTErrorState({
    super.key,
    this.message = 'Something went wrong',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KTColors.danger.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: KTColors.danger),
            ),
            const SizedBox(height: 20),
            Text(message, style: KTTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
