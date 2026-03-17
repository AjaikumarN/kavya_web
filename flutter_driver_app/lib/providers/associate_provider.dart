import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/job.dart';
import '../models/lr.dart';

final _api = ApiService();

// ── Associate Dashboard ──
final associateDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return _api.getDashboardAssociate();
});

// ── Jobs ──
final jobListProvider =
    FutureProvider.autoDispose.family<List<Job>, String?>((ref, status) async {
  final data = await _api.getJobs(status: status);
  return data.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Jobs needing LR ──
final jobsNeedingLRProvider =
    FutureProvider.autoDispose<List<Job>>((ref) async {
  final data = await _api.getJobs(noLr: true);
  return data.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
});

// ── LR list ──
final lrListProvider =
    FutureProvider.autoDispose<List<LR>>((ref) async {
  final data = await _api.getLRs();
  return data.map((e) => LR.fromJson(e as Map<String, dynamic>)).toList();
});

// ── LRs needing EWB ──
final lrsNeedingEwbProvider =
    FutureProvider.autoDispose<List<LR>>((ref) async {
  final data = await _api.getLRs(noEwb: true);
  return data.map((e) => LR.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Active trips (for closing) ──
final activeTripsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await _api.getTrips(status: 'active');
  return data.cast<Map<String, dynamic>>();
});
