// frontend/lib/data/services/vocal_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:frontend/data/models/vocal_sentiment_analysis.dart';
import 'package:frontend/data/services/api_service.dart';
import 'package:frontend/data/services/secure_storage_service.dart';

class VocalService {
  final ApiService _api = ApiService();
  final SecureStorageService _storage = SecureStorageService();

  Future<String> _getAuthToken() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      throw Exception('Sesi tidak valid. Harap login ulang.');
    }
    return token;
  }

  /// Mengirim file audio ke backend untuk dianalisis.
  /// Menggunakan metode multipart/form-data untuk upload file.
  Future<VocalSentimentAnalysis> uploadAndAnalyzeAudio(String audioPath) async {
    final token = await _getAuthToken();
    final uri = _api.getUri('/vocal/entries'); // Sesuai dengan route di main.go

    // Membuat request multipart untuk mengirim file
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    // Menambahkan file audio ke request.
    // Key 'audio' harus sama dengan yang diharapkan di backend: c.Request.FormFile("audio")
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        contentType: MediaType('audio', 'wav'), // Sesuaikan jika format lain
      ),
    );

    // Mengirim request dan menunggu response
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      // Backend mengembalikan { "data": {...} }, jadi kita ambil dari key 'data'
      return VocalSentimentAnalysis.fromJson(responseBody['data']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Gagal menganalisis rekaman suara');
    }
  }
}