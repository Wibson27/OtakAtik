class ApiService {
  // Gunakan IP 10.0.2.2 untuk emulator Android jika localhost tidak berfungsi
  static const String _baseUrl = "http://10.0.2.2:8080/api/v1";

  Uri getUri(String path) {
    return Uri.parse("$_baseUrl$path");
  }

  Map<String, String> get ajsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> ajsonHeadersWithToken(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
}