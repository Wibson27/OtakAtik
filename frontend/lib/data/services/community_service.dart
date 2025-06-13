import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/data/models/community_post.dart';
import 'package:frontend/data/models/community_post_detail.dart';
import 'package:frontend/data/models/community_post_reply.dart';
import 'package:frontend/data/services/api_service.dart';
import 'package:frontend/data/services/secure_storage_service.dart';

class CommunityService {
  final ApiService _api = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  Future<String?> _getAuthTokenOptional() async => await _storage.getAccessToken();
  Future<String> _getAuthTokenRequired() async {
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('Sesi tidak valid. Harap login ulang.');
    return token;
  }

  Future<List<CommunityPost>> getPublicPosts() async {
    final token = await _getAuthTokenOptional();
    final headers = token != null ? _api.ajsonHeadersWithToken(token) : _api.ajsonHeaders;
    final response = await http.get(_api.getUri('/community/posts/public'), headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];
      return data.map((json) => CommunityPost.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat postingan forum');
    }
  }

  Future<CommunityPostDetail> getPostDetail(String postId) async {
    final token = await _getAuthTokenOptional();
    final headers = token != null ? _api.ajsonHeadersWithToken(token) : _api.ajsonHeaders;
    final response = await http.get(_api.getUri('/community/posts/$postId'), headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return CommunityPostDetail.fromJson(body['data']);
    } else {
      throw Exception('Gagal memuat detail diskusi');
    }
  }

  Future<CommunityPostReply> createReply({required String postId, required String content}) async {
    final token = await _getAuthTokenRequired();
    final response = await http.post(
      _api.getUri('/community/replies'),
      headers: _api.ajsonHeadersWithToken(token),
      body: jsonEncode({
        'post_id': postId,
        'content': content,
        'is_anonymous': false,
      }),
    );
    if (response.statusCode == 201) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return CommunityPostReply.fromJson(body['data']);
    } else {
      throw Exception('Gagal mengirim balasan');
    }
  }
}