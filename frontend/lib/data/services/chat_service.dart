// PERBAIKAN UTAMA untuk ChatService
// File: data/services/chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/data/models/chat_session.dart';
import 'package:frontend/data/models/chat_message.dart';
import 'package:frontend/data/services/api_service.dart';
import 'package:frontend/data/services/secure_storage_service.dart';

/// ChatService menangani semua komunikasi jaringan terkait fitur chat.
/// Ini adalah satu-satunya tempat di mana logika API untuk chat berada,
/// menjaga agar kode di UI (screens) tetap bersih.
class ChatService {
  final ApiService _api = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  /// Metode internal untuk mengambil token autentikasi dari penyimpanan aman.
  /// Melempar Exception jika token tidak ditemukan.
  Future<String> _getAuthToken() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      throw Exception('Sesi tidak valid. Harap login ulang.');
    }
    return token;
  }

  /// Membuat sesi chat baru untuk pengguna yang sedang login.
  /// Terhubung ke endpoint: `POST /api/v1/sessions`
  /// Dipanggil dari `DashboardScreen` saat tombol "Health Chatbot" ditekan.
  Future<ChatSession> createChatSession({String triggerType = 'user_initiated'}) async {
    final token = await _getAuthToken();

    print("📤 Creating chat session...");

    final response = await http.post(
      _api.getUri('/chat/sessions'),
      headers: _api.ajsonHeadersWithToken(token),
      body: jsonEncode({'trigger_type': triggerType}),
    );

    print("📨 Create session response: ${response.statusCode}");
    print("📨 Response body: ${response.body}");

    if (response.statusCode == 201) {
      try {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // 🔧 PERBAIKAN: Validasi struktur response
        if (!responseBody.containsKey('data')) {
          throw Exception("Response tidak memiliki key 'data'");
        }

        final sessionData = responseBody['data'];
        if (sessionData == null) {
          throw Exception("Data session null dalam response");
        }

        // 🔧 PERBAIKAN: Validasi field wajib
        if (!sessionData.containsKey('id')) {
          throw Exception("Session data tidak memiliki ID");
        }

        print("✅ Session created successfully: ${sessionData['id']}");
        return ChatSession.fromJson(sessionData);

      } catch (e) {
        print("❌ Error parsing create session response: $e");
        throw Exception("Gagal parse response session: $e");
      }
    } else {
      final body = jsonDecode(response.body);
      final errorMsg = body['error'] ?? 'Gagal memulai sesi baru';
      print("❌ Create session failed: $errorMsg");
      throw Exception(errorMsg);
    }
  }

  /// Mengambil daftar riwayat sesi chat milik pengguna.
  /// Terhubung ke endpoint: `GET /api/v1/sessions`
  /// Digunakan untuk menampilkan riwayat percakapan di `ChatbotScreen`.
  Future<List<ChatSession>> getChatSessions() async {
    final token = await _getAuthToken();

    print("📤 Getting chat sessions...");

    final response = await http.get(
      _api.getUri('/chat/sessions?limit=50'),
      headers: _api.ajsonHeadersWithToken(token),
    );

    print("📨 Get sessions response: ${response.statusCode}");

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final List<dynamic> data = responseBody['data'] ?? [];

        print("✅ Retrieved ${data.length} sessions");
        return data.map((json) => ChatSession.fromJson(json)).toList();

      } catch (e) {
        print("❌ Error parsing sessions: $e");
        throw Exception("Gagal parse riwayat percakapan: $e");
      }
    } else {
      print("❌ Get sessions failed: ${response.statusCode}");
      throw Exception('Gagal memuat riwayat percakapan');
    }
  }

  /// Mengambil semua pesan untuk sebuah sesi chat spesifik.
  /// Terhubung ke endpoint: `GET /api/v1/sessions/:sessionId`
  /// Digunakan di `ChatbotScreen` saat membuka percakapan atau polling.
  Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    final token = await _getAuthToken();

    print("📤 Getting messages for session: $sessionId");

    final response = await http.get(
      _api.getUri('/chat/sessions/$sessionId'),
      headers: _api.ajsonHeadersWithToken(token),
    );

    print("📨 Get messages response: ${response.statusCode}");

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final messagesJson = responseBody['data'];

        // 🔧 PERBAIKAN: Handle berbagai format response
        List<dynamic> messagesList = [];

        if (messagesJson == null) {
          print("ℹ️ No messages data in response");
          return [];
        }

        if (messagesJson is List) {
          messagesList = messagesJson;
        } else if (messagesJson is Map && messagesJson.containsKey('messages')) {
          messagesList = messagesJson['messages'] ?? [];
        } else {
          print("⚠️ Unexpected messages format: ${messagesJson.runtimeType}");
          return [];
        }

        if (messagesList.isEmpty) {
          print("ℹ️ No messages found for session");
          return [];
        }

        // 🔧 PERBAIKAN: Filter dan validate setiap pesan
        final validMessages = <ChatMessage>[];

        for (var messageJson in messagesList) {
          try {
            if (messageJson is Map<String, dynamic>) {
              // Validasi field wajib
              if (messageJson['message_content'] != null &&
                  messageJson['message_content'].toString().trim().isNotEmpty) {
                final message = ChatMessage.fromJson(messageJson);
                validMessages.add(message);
              } else {
                print("⚠️ Skipping message with empty content");
              }
            }
          } catch (e) {
            print("⚠️ Error parsing individual message: $e");
            // Skip pesan yang bermasalah, lanjutkan yang lain
          }
        }

        print("✅ Retrieved ${validMessages.length} valid messages");
        return validMessages;

      } catch (e) {
        print("❌ Error parsing messages: $e");
        throw Exception("Gagal parse pesan: $e");
      }
    } else if (response.statusCode == 404) {
      print("ℹ️ Session not found or has no messages");
      return []; // Return empty list untuk session baru
    } else {
      final body = jsonDecode(response.body);
      final errorMsg = body['error'] ?? 'Gagal memuat pesan';
      print("❌ Get messages failed: $errorMsg");
      throw Exception(errorMsg);
    }
  }

  /// Mengirim sebuah pesan ke dalam sesi chat yang aktif.
  /// Terhubung ke endpoint: `POST /api/v1/messages`
  /// Digunakan di `ChatbotScreen` saat pengguna menekan tombol kirim.
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String content
  }) async {
    final token = await _getAuthToken();

    print("📤 Sending message to session: $sessionId");
    print("📤 Message content: $content");

    final requestBody = {
      'session_id': sessionId,
      'message_content': content,
    };

    final response = await http.post(
      _api.getUri('/chat/messages'),
      headers: _api.ajsonHeadersWithToken(token),
      body: jsonEncode(requestBody),
    );

    print("📨 Send message response: ${response.statusCode}");
    print("📨 Response body: ${response.body}");

    if (response.statusCode == 201) {
      try {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // 🔧 PERBAIKAN: Validate response structure
        if (!responseBody.containsKey('data')) {
          throw Exception("Response tidak memiliki key 'data'");
        }

        final messageData = responseBody['data'];
        if (messageData == null) {
          throw Exception("Data message null dalam response");
        }

        // 🔧 PERBAIKAN: Validate message content
        if (messageData['message_content'] == null ||
            messageData['message_content'].toString().trim().isEmpty) {
          throw Exception("Message content kosong dalam response");
        }

        print("✅ Message sent successfully");
        return ChatMessage.fromJson(messageData);

      } catch (e) {
        print("❌ Error parsing send message response: $e");
        throw Exception("Gagal parse response pesan: $e");
      }
    } else {
      final body = jsonDecode(response.body);
      final errorMsg = body['error'] ?? 'Gagal mengirim pesan';
      print("❌ Send message failed: $errorMsg");
      throw Exception(errorMsg);
    }
  }

  // 🔧 PERBAIKAN: Tambah method untuk debug
  Future<void> debugSessionInfo(String sessionId) async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        _api.getUri('/chat/sessions/$sessionId'),
        headers: _api.ajsonHeadersWithToken(token),
      );

      print("🔍 Debug session $sessionId:");
      print("   Status: ${response.statusCode}");
      print("   Body: ${response.body}");

    } catch (e) {
      print("🔍 Debug session error: $e");
    }
  }
}