import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Base URL from environment [cite: 31]
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // Request interceptor: adds Authorization header [cite: 32]
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // Response interceptor: on 401 -> calls refresh token endpoint [cite: 32]
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              try {
                // Retry refresh [cite: 32]
                final refreshResponse = await Dio().post(
                  '$baseUrl/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );
                final newAccessToken = refreshResponse.data['access_token'];
                await _storage.write(key: 'access_token', value: newAccessToken);
                
                // Retry original request [cite: 32]
                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final retryResponse = await Dio().fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              } catch (refreshError) {
                // If refresh fails -> clear storage [cite: 32]
                await _storage.deleteAll();
                // Redirection to login handled by router guard
              }
            } else {
              await _storage.deleteAll();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- Auth & Profile ---

  // --- Generic HTTP methods (used by providers) ---
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data;
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    final response = await _dio.patch(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path) async {
    final response = await _dio.delete(path);
    return response.data;
  }

  // --- Named Auth & Profile ---
  Future<Map<String, dynamic>> login(String email, String password) async { // [cite: 32-33]
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async { // [cite: 33]
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken(String token) async { // [cite: 33]
    final response = await _dio.post('/auth/refresh', data: {'refresh_token': token});
    return response.data;
  }

  // --- Dashboards ---
  Future<Map<String, dynamic>> getDashboardAdmin() async {
    final response = await _dio.get('/dashboard');
    return response.data;
  }

  Future<Map<String, dynamic>> getFleetStats() async {
    final response = await _dio.get('/dashboard/fleet-stats');
    return response.data;
  }

  Future<Map<String, dynamic>> getTripStats() async {
    final response = await _dio.get('/dashboard/trip-stats');
    return response.data;
  }

  Future<Map<String, dynamic>> getFinanceStats() async {
    final response = await _dio.get('/dashboard/finance-stats');
    return response.data;
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/dashboard/notifications');
    return response.data is List ? response.data : [];
  }

  Future<Map<String, dynamic>> getRevenueTrend({String period = 'monthly'}) async {
    final response = await _dio.get('/dashboard/charts/revenue-trend', queryParameters: {'period': period});
    return response.data;
  }

  Future<Map<String, dynamic>> getDashboardFleet() async {
    final response = await _dio.get('/dashboard/fleet-manager');
    return response.data;
  }

  Future<Map<String, dynamic>> getDashboardAccountant() async {
    final response = await _dio.get('/dashboard/accountant');
    return response.data;
  }

  Future<Map<String, dynamic>> getDashboardAssociate() async {
    final response = await _dio.get('/dashboard/associate');
    return response.data;
  }

  Future<Map<String, dynamic>> getPAKpis() async {
    final response = await _dio.get('/dashboard/pa/kpis');
    return response.data;
  }

  Future<Map<String, dynamic>> getPAActionCenter() async {
    final response = await _dio.get('/dashboard/pa/action-center');
    return response.data;
  }

  Future<Map<String, dynamic>> getPAJobPipeline() async {
    final response = await _dio.get('/dashboard/pa/job-pipeline');
    return response.data;
  }

  Future<List<dynamic>> getPARecentActivity({int limit = 10}) async {
    final response = await _dio.get('/dashboard/pa/recent-activity', queryParameters: {'limit': limit});
    return response.data is List ? response.data : [];
  }

  // --- Jobs & Documents ---
  Future<List<dynamic>> getJobs({String? status, bool? noLr}) async { // [cite: 33]
    final response = await _dio.get('/jobs', queryParameters: {
      if (status != null) 'status': status,
      if (noLr != null) 'noLr': noLr,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createLR(Map<String, dynamic> data) async { // [cite: 33]
    final response = await _dio.post('/lr', data: data);
    return response.data;
  }

  Future<List<dynamic>> getLRs({bool? noEwb}) async { // [cite: 33]
    final response = await _dio.get('/lr', queryParameters: {
      if (noEwb != null) 'noEwb': noEwb,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> generateEWB(Map<String, dynamic> data) async { // [cite: 33]
    final response = await _dio.post('/eway-bills/generate', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> extendEWB(String ewbId) async { // [cite: 33]
    final response = await _dio.patch('/eway-bills/$ewbId/extend');
    return response.data;
  }

  Future<Map<String, dynamic>> uploadDocument(File file, String type, String linkedId) async { // [cite: 34]
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
      "type": type,
      "linked_id": linkedId,
    });
    final response = await _dio.post('/documents/upload', data: formData);
    return response.data;
  }

  // --- Expenses & Finance ---
  Future<List<dynamic>> getExpensesPending() async { // [cite: 33]
    final response = await _dio.get('/trips', queryParameters: {'status': 'in_progress'});
    return response.data;
  }

  Future<void> approveExpense(String id) async { // [cite: 33]
    await _dio.patch('/expenses/$id/status', data: {'status': 'approved'});
  }

  Future<void> rejectExpense(String id, String reason) async { // [cite: 33]
    await _dio.patch('/expenses/$id/status', data: {'status': 'rejected', 'reason': reason});
  }

  Future<List<dynamic>> getInvoices() async { // [cite: 34]
    final response = await _dio.get('/finance/invoices');
    return response.data;
  }

  Future<Map<String, dynamic>> getInvoiceDetail(String id) async { // [cite: 34]
    final response = await _dio.get('/finance/invoices/$id');
    return response.data;
  }

  Future<void> recordPayment(String invoiceId, Map<String, dynamic> data) async { // [cite: 34]
    await _dio.post('/finance/payments', data: data);
  }

  Future<List<dynamic>> getReceivables() async { // [cite: 34]
    final response = await _dio.get('/finance/receivables');
    return response.data;
  }

  // --- Vehicles & Trips ---
  Future<List<dynamic>> getVehicles() async { // [cite: 33]
    final response = await _dio.get('/vehicles');
    return response.data;
  }

  Future<Map<String, dynamic>> getVehicleDetail(String id) async { // [cite: 33]
    final response = await _dio.get('/vehicles/$id');
    return response.data;
  }

  Future<void> logService(Map<String, dynamic> data) async { // [cite: 33]
    await _dio.post('/services', data: data);
  }

  Future<void> recordTyreEvent(Map<String, dynamic> data) async { // [cite: 33]
    final tyreId = data['tyre_id'];
    await _dio.post('/tyres/$tyreId/events', data: data);
  }

  Future<List<dynamic>> getTrips({String? status}) async { // [cite: 34]
    final response = await _dio.get('/trips', queryParameters: {
      if (status != null) 'status': status,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getTripDetail(String id) async { // [cite: 34]
    final response = await _dio.get('/trips/$id');
    return response.data;
  }

  Future<void> closeTrip(String id) async { // [cite: 34]
    await _dio.patch('/trips/$id/status', data: {'status': 'completed'});
  }

  /// Trigger SOS alert for a trip. Returns response data including emergency contact.
  Future<Map<String, dynamic>> triggerSOS(int tripId, {double? latitude, double? longitude, String? locationName}) async {
    final response = await _dio.post('/trips/$tripId/sos', data: {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationName != null) 'location_name': locationName,
    });
    return response.data;
  }

  // --- Intelligence Layer ---
  Future<Map<String, dynamic>> getDriverScore(int driverId) async {
    final response = await _dio.get('/intelligence/driver-scores/$driverId');
    return response.data['data'] ?? response.data;
  }

  Future<Map<String, dynamic>> getDriverLeaderboard() async {
    final response = await _dio.get('/intelligence/driver-leaderboard');
    return response.data['data'] ?? response.data;
  }

  Future<Map<String, dynamic>> getVehicleRisk(int vehicleId) async {
    final response = await _dio.get('/intelligence/vehicle-risk/$vehicleId');
    return response.data['data'] ?? response.data;
  }

  Future<Map<String, dynamic>> getFleetMaintenanceSummary() async {
    final response = await _dio.get('/intelligence/fleet-maintenance');
    return response.data['data'] ?? response.data;
  }

  Future<List<dynamic>> getTripAlerts(int tripId, {bool unacknowledgedOnly = false}) async {
    final response = await _dio.get('/intelligence/trip-alerts/$tripId', queryParameters: {
      'unacknowledged_only': unacknowledgedOnly,
    });
    final data = response.data['data'];
    return data is List ? data : [];
  }

  Future<List<dynamic>> getDailyInsights({int limit = 7}) async {
    final response = await _dio.get('/intelligence/insights', queryParameters: {'limit': limit});
    final data = response.data['data'];
    return data is List ? data : [];
  }

  Future<List<dynamic>> getRecentEvents({int limit = 20}) async {
    final response = await _dio.get('/intelligence/events', queryParameters: {'limit': limit});
    final data = response.data['data'];
    return data is List ? data : [];
  }

  // --- Event Priority & Grouped Events ---

  Future<List<dynamic>> getGroupedEvents({String? priority, int limit = 50}) async {
    final params = <String, dynamic>{'limit': limit};
    if (priority != null) params['priority'] = priority;
    final response = await _dio.get('/intelligence/events/grouped', queryParameters: params);
    final data = response.data['data'];
    return data is List ? data : [];
  }

  Future<List<dynamic>> getEventHistory(String entityId, {bool includeSuppressed = true, int limit = 100}) async {
    final response = await _dio.get('/intelligence/events/history', queryParameters: {
      'entity_id': entityId,
      'include_suppressed': includeSuppressed,
      'limit': limit,
    });
    final data = response.data['data'];
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> acknowledgeEvent(int eventId, {String? note}) async {
    final params = <String, dynamic>{};
    if (note != null) params['note'] = note;
    final response = await _dio.post('/intelligence/events/$eventId/acknowledge', queryParameters: params);
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> acknowledgeEventsBulk(List<int> eventIds, {String? note}) async {
    final params = <String, dynamic>{'event_ids': eventIds};
    if (note != null) params['note'] = note;
    final response = await _dio.post('/intelligence/events/acknowledge-bulk', queryParameters: params);
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  // --- Offline Batch Sync ---

  /// Sends a batch of queued offline actions to the server.
  /// Returns a map containing 'accepted' count and list of 'results'.
  Future<Map<String, dynamic>> syncBatch({
    required String deviceId,
    required List<Map<String, dynamic>> actions,
  }) async {
    final response = await _dio.post('/sync/batch', data: {
      'device_id': deviceId,
      'actions': actions,
    });
    return response.data;
  }
}