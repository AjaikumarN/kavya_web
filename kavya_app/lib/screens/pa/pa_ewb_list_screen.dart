import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/kt_colors.dart';
import '../../core/theme/kt_text_styles.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/notification_bell_widget.dart';
import 'pa_providers.dart';

class PAEWBListScreen extends ConsumerStatefulWidget {
  const PAEWBListScreen({super.key});

  @override
  ConsumerState<PAEWBListScreen> createState() => _PAEWBListScreenState();
}

class _PAEWBListScreenState extends ConsumerState<PAEWBListScreen> {
  Timer? _timer;

  static const _filters = [
    ('All', null),
    ('Active', 'active'),
    ('Expiring', 'expiring'),
    ('Expired', 'expired'),
  ];

  @override
  void initState() {
    super.initState();
    // Refresh countdown text every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _countdown(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'EXPIRED';
    if (diff.inHours < 1) return '${diff.inMinutes}m left';
    return '${diff.inHours}h ${diff.inMinutes % 60}m left';
  }

  double _progressFraction(String? validFrom, String? validUntil) {
    if (validFrom == null || validUntil == null) return 1.0;
    final from = DateTime.tryParse(validFrom);
    final until = DateTime.tryParse(validUntil);
    if (from == null || until == null) return 1.0;
    final total = until.difference(from).inMinutes;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(from).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(paEWBFilterProvider);
    final ewbAsync = ref.watch(paEWBListProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Text('E-Way Bills', style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
        actions: const [NotificationBellWidget()],
      ),
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _filters.map((f) {
                final isActive = filter == f.$2;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$1),
                    selected: isActive,
                    onSelected: (_) =>
                        ref.read(paEWBFilterProvider.notifier).state = f.$2,
                    backgroundColor: KTColors.darkSurface,
                    selectedColor: KTColors.primary,
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : KTColors.darkTextSecondary,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isActive ? KTColors.primary : KTColors.darkBorder),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── EWB list ──────────────────────────────────────────────────
          Expanded(
            child: ewbAsync.when(
              loading: () => const KTLoadingShimmer(type: ShimmerType.list),
              error: (e, _) => KTErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(paEWBListProvider),
              ),
              data: (ewbs) {
                if (ewbs.isEmpty) {
                  return Center(
                    child: Text(
                      'No e-Way Bills found',
                      style: KTTextStyles.body.copyWith(color: KTColors.darkTextSecondary),
                    ),
                  );
                }

                // Sort: expiring soonest first
                final sorted = List<dynamic>.from(ewbs)
                  ..sort((a, b) {
                    final dtA = DateTime.tryParse((a as Map)['valid_until'] ?? '') ?? DateTime(9999);
                    final dtB = DateTime.tryParse((b as Map)['valid_until'] ?? '') ?? DateTime(9999);
                    return dtA.compareTo(dtB);
                  });

                return RefreshIndicator(
                  color: KTColors.primary,
                  backgroundColor: KTColors.darkSurface,
                  onRefresh: () async => ref.invalidate(paEWBListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final ewb = Map<String, dynamic>.from(sorted[i] as Map);
                      final progress = _progressFraction(
                        ewb['valid_from'] as String?,
                        ewb['valid_until'] as String?,
                      );
                      final countdown = _countdown(ewb['valid_until'] as String?);
                      final isUrgent = ewb['status'] == 'expiring' || ewb['status'] == 'expired';

                      return _EWBCard(
                        ewb: ewb,
                        progress: progress,
                        countdown: countdown,
                        isUrgent: isUrgent,
                        onTap: () => context.push('/pa/ewb/${ewb['id']}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EWBCard extends StatelessWidget {
  final Map<String, dynamic> ewb;
  final double progress;
  final String countdown;
  final bool isUrgent;
  final VoidCallback onTap;

  const _EWBCard({
    required this.ewb,
    required this.progress,
    required this.countdown,
    required this.isUrgent,
    required this.onTap,
  });

  Color get _progressColor {
    if (progress >= 0.85) return KTColors.danger;
    if (progress >= 0.65) return KTColors.warning;
    return KTColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent ? KTColors.danger : KTColors.darkBorder,
            width: isUrgent ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ewb['ewb_number'] ?? ewb['id']?.toString() ?? '—',
                  style: KTTextStyles.body.copyWith(
                    color: KTColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (countdown.isNotEmpty)
                  Text(
                    countdown,
                    style: KTTextStyles.bodySmall.copyWith(
                      color: countdown == 'EXPIRED' ? KTColors.danger : _progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ewb['lr_number'] ?? '',
              style: KTTextStyles.bodySmall.copyWith(color: KTColors.darkTextSecondary),
            ),
            const SizedBox(height: 8),
            // Validity progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: KTColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
