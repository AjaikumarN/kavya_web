import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../exceptions/app_exception.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final token = await _storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
          // Refresh failed — clear storage
          await _storage.deleteAll();
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
          .post('/auth/refresh', data: {'refresh_token': refreshToken});

      if (response.statusCode == 200) {
        await _storage.write(
            key: 'access_token', value: response.data['access_token']);
        if (response.data['refresh_token'] != null) {
          await _storage.write(
              key: 'refresh_token', value: response.data['refresh_token']);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  AppException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 500;
        final data = e.response?.data;
        final detail = data is Map ? data['detail']?.toString() : null;
        if (status == 401) return const UnauthorizedException();
        return AppException(
          'Request failed',
          detail: detail ?? 'Server returned status $status',
          statusCode: status,
        );
      default:
        return AppException(e.message ?? 'Unknown error');
    }
  }

  // ── Generic HTTP methods ──

  Future<T> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      T Function(dynamic)? fromJson}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (fromJson != null) return fromJson(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(String path,
      {dynamic data, T Function(dynamic)? fromJson}) async {
    try {
      final response = await _dio.post(path, data: data);
      if (fromJson != null) return fromJson(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(String path,
      {dynamic data, T Function(dynamic)? fromJson}) async {
    try {
      final response = await _dio.put(path, data: data);
      if (fromJson != null) return fromJson(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> patch<T>(String path,
      {dynamic data, T Function(dynamic)? fromJson}) async {
    try {
      final response = await _dio.patch(path, data: data);
      if (fromJson != null) return fromJson(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> delete<T>(String path, {T Function(dynamic)? fromJson}) async {
    try {
      final response = await _dio.delete(path);
      if (fromJson != null) return fromJson(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> uploadFile<T>(String path,
      {required String filePath,
      String fieldName = 'file',
      Map<String, dynamic>? fields,
      T Function(dynamic)? fromJson}) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (fields != null) ...fields,
      });
      final response = await _dio.post(path, data: formData);
      if (fromJson != null) return fromJson(response.data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Auth ──

  Future<Map<String, dynamic>> login(String email, String password) async {
    return post('/auth/login', data: {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> getMe() async {
    return get('/auth/me');
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    return post('/auth/refresh', data: {'refresh_token': token});
  }

  // ── Dashboard ──

  Future<Map<String, dynamic>> getDashboardFleet() async {
    return get('/dashboard/fleet-manager');
  }

  Future<Map<String, dynamic>> getDashboardAccountant() async {
    return get('/dashboard/accountant');
  }

  Future<Map<String, dynamic>> getDashboardAssociate() async {
    return get('/dashboard/associate');
  }

  // ── Jobs ──

  Future<List<dynamic>> getJobs({String? status, bool? noLr}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (noLr != null) params['no_lr'] = noLr;
    final resp = await get<dynamic>('/jobs', queryParameters: params);
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  // ── LR ──

  Future<Map<String, dynamic>> createLR(Map<String, dynamic> data) async {
    return post('/lr', data: data);
  }

  Future<List<dynamic>> getLRs({bool? noEwb}) async {
    final params = <String, dynamic>{};
    if (noEwb != null) params['no_ewb'] = noEwb;
    final resp = await get<dynamic>('/lr', queryParameters: params);
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  // ── E-way Bills ──

  Future<Map<String, dynamic>> generateEWB(Map<String, dynamic> data) async {
    return post('/eway-bills/generate', data: data);
  }

  Future<Map<String, dynamic>> extendEWB(String ewbId) async {
    return patch('/eway-bills/$ewbId/extend');
  }

  // ── Expenses ──

  Future<List<dynamic>> getExpensesPending() async {
    final resp = await get<dynamic>('/expenses', queryParameters: {'status': 'pending'});
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  Future<void> approveExpense(String id) async {
    await patch('/expenses/$id/status', data: {'status': 'approved'});
  }

  Future<void> rejectExpense(String id, String reason) async {
    await patch('/expenses/$id/status', data: {'status': 'rejected', 'reason': reason});
  }

  // ── Vehicles ──

  Future<List<dynamic>> getVehicles() async {
    final resp = await get<dynamic>('/vehicles');
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  Future<Map<String, dynamic>> getVehicleDetail(String id) async {
    return get('/vehicles/$id');
  }

  Future<void> logService(Map<String, dynamic> data) async {
    await post('/services', data: data);
  }

  Future<void> recordTyreEvent(Map<String, dynamic> data) async {
    await post('/tyres/events', data: data);
  }

  // ── Trips ──

  Future<List<dynamic>> getTrips({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final resp = await get<dynamic>('/trips', queryParameters: params);
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  Future<Map<String, dynamic>> getTripDetail(String id) async {
    return get('/trips/$id');
  }

  Future<void> closeTrip(String id) async {
    await patch('/trips/$id/status', data: {'status': 'completed'});
  }

  // ── Documents ──

  Future<Map<String, dynamic>> uploadDocument(String filePath, String type, String linkedId) async {
    return uploadFile('/documents/upload',
        filePath: filePath, fields: {'type': type, 'linked_id': linkedId});
  }

  // ── Finance ──

  Future<List<dynamic>> getInvoices({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final resp = await get<dynamic>('/finance/invoices', queryParameters: params);
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  Future<Map<String, dynamic>> getInvoiceDetail(String id) async {
    return get('/finance/invoices/$id');
  }

  Future<void> recordPayment(String invoiceId, Map<String, dynamic> data) async {
    await post('/finance/payments', data: {'invoice_id': invoiceId, ...data});
  }

  Future<List<dynamic>> getReceivables() async {
    final resp = await get<dynamic>('/finance/receivables');
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  Future<List<dynamic>> getPayments({String? mode, String? fromDate, String? toDate}) async {
    final params = <String, dynamic>{};
    if (mode != null) params['mode'] = mode;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final resp = await get<dynamic>('/finance/payments', queryParameters: params);
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  // ── Tracking ──

  Future<List<dynamic>> getGpsPositions() async {
    final resp = await get<dynamic>('/tracking/gps');
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  // ── Notifications ──

  Future<List<dynamic>> getNotifications({bool? unread}) async {
    final params = <String, dynamic>{};
    if (unread != null) params['unread'] = unread;
    final resp = await get<dynamic>('/notifications', queryParameters: params);
    return resp is List ? resp : (resp as Map)['data'] ?? [];
  }

  Future<void> markNotificationRead(String id) async {
    await patch('/notifications/$id/read');
  }
}
