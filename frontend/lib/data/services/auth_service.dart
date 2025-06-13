// lib/data/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/data/models/auth_response.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/data/services/api_service.dart';
import 'package:frontend/data/services/secure_storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  /// Menyimpan data otentikasi ke secure storage setelah operasi berhasil.
  Future<void> _persistAuthentication(AuthResponse authResponse) async {
    await _storage.persistAuthData(
      // Mengakses token dari objek 'tokens' yang bersarang
      accessToken: authResponse.tokens.accessToken,
      refreshToken: authResponse.tokens.refreshToken,
      // Mengakses ID dari objek 'user' yang bersarang
      userId: authResponse.user.id,
    );
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await http.post(
      _api.getUri('/auth/register'),
      headers: _api.ajsonHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _persistAuthentication(authResponse); // Memanggil helper
      return authResponse;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to register');
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _api.getUri('/auth/login'),
      headers: _api.ajsonHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _persistAuthentication(authResponse); // Memanggil helper
      return authResponse;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to login');
    }
  }

  Future<AuthResponse> googleSignIn({required String idToken}) async {
    final response = await http.post(
      _api.getUri('/auth/google'),
      headers: _api.ajsonHeaders,
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await _persistAuthentication(authResponse); // Memanggil helper
      return authResponse;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to sign in with Google');
    }
  }

    Future<User> getProfile() async {
    final token = await _storage.getAccessToken();
    final userId = await _storage.getUserId(); // Kita butuh ID user dari storage

    if (token == null || userId == null) {
      throw Exception('User tidak terautentikasi');
    }

    final response = await http.get(
      _api.getUri('/users/$userId/profile'), // Sesuai dengan route di main.go
      headers: _api.ajsonHeadersWithToken(token),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      // Backend Anda sepertinya tidak membungkus ini dengan 'data', jadi kita langsung parse
      return User.fromJson(body);
    } else {
      throw Exception('Gagal memuat profil');
    }
  }

  /// FUNGSI BARU: Logout pengguna.
  Future<void> logout() async {
    final token = await _storage.getAccessToken();

    try {
      if (token != null) {
        await http.post(
          _api.getUri('/auth/logout'),
          headers: _api.ajsonHeadersWithToken(token),
        );
      }
    } catch (e) {
      print("Panggilan API logout gagal, tetap lanjutkan proses logout lokal: $e");
    } finally {
      // PERBAIKAN: Menggunakan nama metode `deleteAllTokens` yang benar dari SecureStorageService Anda.
      await _storage.deleteAllTokens();
    }
  }

}