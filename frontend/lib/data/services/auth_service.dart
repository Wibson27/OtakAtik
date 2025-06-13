// lib/data/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/data/models/auth_response.dart';
import 'package:frontend/data/services/api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

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
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      // Melempar error dengan pesan dari backend
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
      return AuthResponse.fromJson(jsonDecode(response.body));
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
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to sign in with Google');
    }
  }
}