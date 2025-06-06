import 'package:frontend/common/enums.dart';

class AttachmentFile {
  final String name;
  final String path;
  final AttachmentType type;
  final int? size;

  AttachmentFile({
    required this.name,
    required this.path,
    required this.type,
    this.size,
  });

  factory AttachmentFile.fromJson(Map<String, dynamic> json) {
    return AttachmentFile(
      name: json['name'] as String,
      path: json['path'] as String,
      type: AttachmentType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => AttachmentType.unknown),
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type.toString().split('.').last,
      'size': size,
    };
  }
}