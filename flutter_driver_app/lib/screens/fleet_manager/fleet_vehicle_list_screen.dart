import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_status_badge.dart';
import '../../core/widgets/kt_empty_state.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../models/vehicle.dart';
import '../../providers/fleet_provider.dart';

class FleetVehicleListScreen extends ConsumerWidget {
  const FleetVehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleListProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Vehicles', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleFleet,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: KTColors.roleFleet,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(vehicleListProvider);
        },
        child: vehicles.when(
          loading: () => const KTLoadingShimmer(variant: ShimmerVariant.list),
          error: (e, _) => KTErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(vehicleListProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const KTEmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'No Vehicles',
                subtitle: 'No vehicles found in the fleet.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _VehicleCard(vehicle: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/fleet/vehicle/${vehicle.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: KTColors.roleFleet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  vehicle.type.toLowerCase().contains('truck')
                      ? Icons.local_shipping
                      : Icons.directions_car,
                  color: KTColors.roleFleet,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.registrationNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KTColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.type}${vehicle.model != null ? ' · ${vehicle.model}' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: KTColors.textSecondary,
                      ),
                    ),
                    if (vehicle.currentDriverName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Driver: ${vehicle.currentDriverName}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: KTColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              KTStatusBadge.fromStatus(vehicle.status),
            ],
          ),
        ),
      ),
    );
  }
}
