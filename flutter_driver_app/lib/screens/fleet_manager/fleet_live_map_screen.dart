import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/kt_colors.dart';
import '../../core/widgets/kt_error_state.dart';
import '../../core/widgets/kt_loading_shimmer.dart';
import '../../providers/fleet_provider.dart';

class FleetLiveMapScreen extends ConsumerStatefulWidget {
  const FleetLiveMapScreen({super.key});

  @override
  ConsumerState<FleetLiveMapScreen> createState() => _FleetLiveMapScreenState();
}

class _FleetLiveMapScreenState extends ConsumerState<FleetLiveMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  static const _defaultCamera = CameraPosition(
    target: LatLng(13.0827, 80.2707), // Chennai default
    zoom: 10,
  );

  void _buildMarkers(List<Map<String, dynamic>> positions) {
    _markers.clear();
    for (final pos in positions) {
      final lat = (pos['lat'] as num?)?.toDouble();
      final lng = (pos['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final regNo = pos['registration_number']?.toString() ?? '';
      final speed = (pos['speed'] as num?)?.toDouble() ?? 0;
      final isMoving = speed > 2;

      _markers.add(
        Marker(
          markerId: MarkerId(regNo),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isMoving ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: regNo,
            snippet: isMoving ? '${speed.toStringAsFixed(0)} km/h' : 'Idle',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsData = ref.watch(gpsPositionsProvider);

    return Scaffold(
      backgroundColor: KTColors.background,
      appBar: AppBar(
        title: Text('Live Map', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: KTColors.roleFleet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(gpsPositionsProvider),
          ),
        ],
      ),
      body: gpsData.when(
        loading: () => const KTLoadingShimmer(variant: ShimmerVariant.card),
        error: (e, _) => KTErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(gpsPositionsProvider),
        ),
        data: (positions) {
          _buildMarkers(positions);
          return GoogleMap(
            initialCameraPosition: _defaultCamera,
            markers: _markers,
            myLocationEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_markers.isNotEmpty) {
                final bounds = _calculateBounds();
                if (bounds != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 60),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  LatLngBounds? _calculateBounds() {
    if (_markers.isEmpty) return null;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final m in _markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
