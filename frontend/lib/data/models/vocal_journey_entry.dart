class VocalJournalEntry {
  final String id;
  final String userId;
  final String? entryTitle;
  final int durationSeconds;
  final int? fileSizeBytes;
  final String audioFilePath;
  final String? audioFormat;
  final String? recordingQuality;
  final String? ambientNoiseLevel;
  final List<String>? userTags;
  final bool? transcriptionEnabled;
  final String? analysisStatus;
  final String? privacyLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VocalJournalEntry({
    required this.id,
    required this.userId,
    this.entryTitle,
    required this.durationSeconds,
    this.fileSizeBytes,
    required this.audioFilePath,
    this.audioFormat,
    this.recordingQuality,
    this.ambientNoiseLevel,
    this.userTags,
    this.transcriptionEnabled,
    this.analysisStatus,
    this.privacyLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory VocalJournalEntry.fromJson(Map<String, dynamic> json) {
    return VocalJournalEntry(
      id: json['id'],
      userId: json['user_id'],
      entryTitle: json['entry_title'],
      durationSeconds: json['duration_seconds'],
      fileSizeBytes: json['file_size_bytes'],
      audioFilePath: json['audio_file_path'],
      audioFormat: json['audio_format'],
      recordingQuality: json['recording_quality'],
      ambientNoiseLevel: json['ambient_noise_level'],
      userTags: (json['user_tags'] as List?)?.map((e) => e.toString()).toList(),
      transcriptionEnabled: json['transcription_enabled'],
      analysisStatus: json['analysis_status'],
      privacyLevel: json['privacy_level'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'entry_title': entryTitle,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'audio_file_path': audioFilePath,
      'audio_format': audioFormat,
      'recording_quality': recordingQuality,
      'ambient_noise_level': ambientNoiseLevel,
      'user_tags': userTags,
      'transcription_enabled': transcriptionEnabled,
      'analysis_status': analysisStatus,
      'privacy_level': privacyLevel,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}