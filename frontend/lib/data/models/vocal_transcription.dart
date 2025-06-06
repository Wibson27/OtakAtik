class VocalTranscription {
  final String id;
  final String vocalEntryId;
  final String transcriptionText;
  final double? confidenceScore;
  final String? languageDetected;
  final int? wordCount;
  final String? processingService;
  final int? processingDurationMs;
  final bool? isEncrypted;
  final DateTime? createdAt;

  VocalTranscription({
    required this.id,
    required this.vocalEntryId,
    required this.transcriptionText,
    this.confidenceScore,
    this.languageDetected,
    this.wordCount,
    this.processingService,
    this.processingDurationMs,
    this.isEncrypted,
    this.createdAt,
  });

  factory VocalTranscription.fromJson(Map<String, dynamic> json) {
    return VocalTranscription(
      id: json['id'],
      vocalEntryId: json['vocal_entry_id'],
      transcriptionText: json['transcription_text'],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      languageDetected: json['language_detected'],
      wordCount: json['word_count'],
      processingService: json['processing_service'],
      processingDurationMs: json['processing_duration_ms'],
      isEncrypted: json['is_encrypted'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vocal_entry_id': vocalEntryId,
      'transcription_text': transcriptionText,
      'confidence_score': confidenceScore,
      'language_detected': languageDetected,
      'word_count': wordCount,
      'processing_service': processingService,
      'processing_duration_ms': processingDurationMs,
      'is_encrypted': isEncrypted,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}