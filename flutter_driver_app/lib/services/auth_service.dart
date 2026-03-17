import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    final response = await _api.post<Map<String, dynamic>>('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response['data'] as Map<String, dynamic>? ?? response;

    await _storage.write(key: 'access_token', value: data['access_token']);
    if (data['refresh_token'] != null) {
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
    }

    final user = User.fromJson(data['user'] ?? data);
    await _storage.write(key: 'primary_role', value: user.primaryRole);
    await _storage.write(key: 'user_name', value: user.fullName);
    await _storage.write(key: 'user_id', value: user.id.toString());

    return user;
  }

  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    final response = await _api.get<Map<String, dynamic>>('/auth/me');
    final userData = response['data'] as Map<String, dynamic>? ?? response;
    final user = User.fromJson(userData);
    await _storage.write(key: 'primary_role', value: user.primaryRole);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', data: {});
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<String?> getPrimaryRole() async {
    return _storage.read(key: 'primary_role');
  }

  Future<String?> getUserName() async {
    return _storage.read(key: 'user_name');
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await _api.post('/auth/fcm-token', data: {'fcm_token': fcmToken});
  }

  static String homeRouteForRole(String? role) {
    switch (role) {
      case 'driver':
        return '/today';
      case 'fleet_manager':
        return '/fleet/home';
      case 'accountant':
        return '/accountant/home';
      case 'project_associate':
        return '/associate/home';
      default:
        return '/web-only';
    }
  }
}
