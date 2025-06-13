import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/data/models/chat_session.dart';
import 'package:frontend/data/models/chat_message.dart';
import 'package:frontend/data/services/api_service.dart';
import 'package:frontend/data/services/secure_storage_service.dart';

class ChatService {
  final ApiService _api = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  // Membuat sesi chat baru
  Future<ChatSession> createChatSession() async {
    final token = await _storage.getAccessToken();
    final response = await http.post(
      _api.getUri('/chat/sessions'),
      headers: _api.ajsonHeadersWithToken(token!),
      body: jsonEncode({
        'session_title': 'Percakapan Baru', // Judul bisa dibuat dinamis
        'trigger_type': 'user_initiated',
      }),
    );

    if (response.statusCode == 201) {
      return ChatSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal membuat sesi chat');
    }
  }

  // Mengambil daftar semua sesi chat (history)
  Future<List<ChatSession>> getChatSessions() async {
    final token = await _storage.getAccessToken();
    final response = await http.get(
      _api.getUri('/chat/sessions'),
      headers: _api.ajsonHeadersWithToken(token!),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((sessionJson) => ChatSession.fromJson(sessionJson)).toList();
    } else {
      throw Exception('Gagal mengambil history chat');
    }
  }

  // Mengambil semua pesan dalam satu sesi
  Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    final token = await _storage.getAccessToken();
    final response = await http.get(
      _api.getUri('/chat/sessions/$sessionId'),
      headers: _api.ajsonHeadersWithToken(token!),
    );

    if (response.statusCode == 200) {
      // Backend Anda sepertinya mengembalikan langsung list pesan di GetSession
      // Kita sesuaikan dengan itu
      final data = jsonDecode(response.body) as List;
      return data.map((messageJson) => ChatMessage.fromJson(messageJson)).toList();
    } else {
      throw Exception('Gagal mengambil pesan');
    }
  }

  // Mengirim pesan baru
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    final token = await _storage.getAccessToken();
    final response = await http.post(
      _api.getUri('/chat/messages'),
      headers: _api.ajsonHeadersWithToken(token!),
      body: jsonEncode({
        'session_id': sessionId,
        'message_content': content,
      }),
    );

    if (response.statusCode == 201) {
      return ChatMessage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal mengirim pesan');
    }
  }
}