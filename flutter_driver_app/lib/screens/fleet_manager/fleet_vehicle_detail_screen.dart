import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_stat_card.dart';
import '../../core/widgets/kt_status_badge.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/fleet_provider.dart';

class FleetVehicleDetailScreen extends ConsumerWidget {
  final String vehicleId;
  const FleetVehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(vehicleDetailProvider(vehicleId));

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Vehicle Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleFleet,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: KTColors.roleFleet,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(vehicleDetailProvider(vehicleId));
        },
        child: detail.when(
          loading: () => const KTLoadingShimmer(variant: ShimmerVariant.card),
          error: (e, _) => KTErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(vehicleDetailProvider(vehicleId)),
          ),
          data: (vehicle) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Header ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: KTColors.roleFleet.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: KTColors.roleFleet,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.registrationNumber,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: KTColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${vehicle.type}${vehicle.model != null ? ' · ${vehicle.model}' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: KTColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          KTStatusBadge.fromStatus(vehicle.status),
                        ],
                      ),
                      if (vehicle.currentDriverName != null) ...[
                        const SizedBox(height: 16),
                        _InfoRow(Icons.person, 'Driver', vehicle.currentDriverName!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats ──
              Row(
                children: [
                  Expanded(
                    child: KTStatCard(
                      title: 'Odometer',
                      value: '${vehicle.odometerKm?.toStringAsFixed(0) ?? '—'} km',
                      icon: Icons.speed,
                      color: KTColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KTStatCard(
                      title: 'Speed',
                      value: '${vehicle.speed?.toStringAsFixed(0) ?? '0'} km/h',
                      icon: Icons.speed,
                      color: KTColors.roleFleet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Service Info ──
              if (vehicle.nextServiceDue != null || vehicle.nextServiceKm != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Info',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: KTColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (vehicle.nextServiceDue != null)
                          _InfoRow(Icons.calendar_today, 'Next Service', vehicle.nextServiceDue!),
                        if (vehicle.nextServiceKm != null)
                          _InfoRow(Icons.route, 'Service at', '${vehicle.nextServiceKm!.toStringAsFixed(0)} km'),
                      ],
                    ),
                  ),
                ),

              // ── Current Trip ──
              if (vehicle.currentTrip != null) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Trip',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: KTColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(Icons.location_on, 'From', vehicle.currentTrip!['origin']?.toString() ?? ''),
                        _InfoRow(Icons.flag, 'To', vehicle.currentTrip!['destination']?.toString() ?? ''),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Documents ──
              if (vehicle.documents != null && vehicle.documents!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: KTColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...vehicle.documents!.map((doc) => _InfoRow(
                              Icons.description,
                              doc['type']?.toString() ?? 'Document',
                              doc['expiry']?.toString() ?? '',
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KTColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: KTColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KTColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
