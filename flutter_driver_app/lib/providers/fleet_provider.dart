import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/vehicle.dart';

final _api = ApiService();

// ── Fleet Dashboard ──
final fleetDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return _api.getDashboardFleet();
});

// ── Vehicle List ──
final vehicleListProvider =
    FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final data = await _api.getVehicles();
  return data
      .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Vehicle Detail ──
final vehicleDetailProvider =
    FutureProvider.autoDispose.family<Vehicle, String>((ref, id) async {
  final data = await _api.getVehicleDetail(id);
  return Vehicle.fromJson(data);
});

// ── Pending Expenses (fleet approval) ──
final fleetPendingExpensesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await _api.getExpensesPending();
  return data.cast<Map<String, dynamic>>();
});

// ── GPS positions (live map) ──
final gpsPositionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await _api.getGpsPositions();
  return data.cast<Map<String, dynamic>>();
});
