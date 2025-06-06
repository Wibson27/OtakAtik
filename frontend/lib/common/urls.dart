class Urls {
  static const host = '192.168.100.15:8080';
  static String image(String filename) {
    return '$host/images/$filename';
  }
}