import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/associate_provider.dart';
import '../../services/api_service.dart';

class AssociateTripCloseScreen extends ConsumerStatefulWidget {
  const AssociateTripCloseScreen({super.key});

  @override
  ConsumerState<AssociateTripCloseScreen> createState() =>
      _AssociateTripCloseScreenState();
}

class _AssociateTripCloseScreenState
    extends ConsumerState<AssociateTripCloseScreen> {
  final _api = ApiService();
  final _closingIds = <String>{};

  Future<void> _closeTrip(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Trip'),
        content: const Text('Are you sure you want to close this trip?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: KTColors.success),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (_closingIds.contains(id)) return;
    setState(() => _closingIds.add(id));
    try {
      await _api.closeTrip(id);
      HapticFeedback.mediumImpact();
      ref.invalidate(activeTripsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Trip closed'),
              backgroundColor: KTColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: KTColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _closingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(activeTripsProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Close Trip',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleAssociate,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: KTColors.roleAssociate,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(activeTripsProvider);
        },
        child: trips.when(
          loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
          error: (e, _) => KTErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(activeTripsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const KTEmptyState(
                icon: Icons.check_circle_outline,
                title: 'No Active Trips',
                subtitle: 'All trips have been completed.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final trip = list[i];
                final id = trip['id']?.toString() ?? '';
                final origin = trip['origin']?.toString() ?? '';
                final destination = trip['destination']?.toString() ?? '';
                final vehicle = trip['vehicle_number']?.toString() ?? '';
                final driver = trip['driver_name']?.toString() ?? '';
                final isClosing = _closingIds.contains(id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: KTColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.directions,
                                  color: KTColors.success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$origin → $destination',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: KTColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$vehicle · $driver',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: KTColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isClosing ? null : () => _closeTrip(id),
                            icon: isClosing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: const Text('Close Trip'),
                            style: FilledButton.styleFrom(
                              backgroundColor: KTColors.success,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
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
