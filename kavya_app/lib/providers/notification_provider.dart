import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fleet_dashboard_provider.dart'; // for apiServiceProvider

final notificationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getNotifications();
});