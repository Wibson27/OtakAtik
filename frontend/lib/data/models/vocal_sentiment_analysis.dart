class VocalSentimentAnalysis {
  final String id;
  final String vocalEntryId;
  final double? overallWellbeingScore;
  final String? wellbeingCategory;
  final double? emotionalValence;
  final double? emotionalArousal;
  final double? emotionalDominance;
  final Map<String, dynamic>? detectedEmotions;
  final List<String>? detectedThemes;
  final Map<String, dynamic>? stressIndicators;
  final Map<String, dynamic>? voiceFeatures;
  final String? analysisModelVersion;
  final double? confidenceScore;
  final int? processingDurationMs;
  final String? reflectionPrompt;
  final DateTime? createdAt;

  VocalSentimentAnalysis({
    required this.id,
    required this.vocalEntryId,
    this.overallWellbeingScore,
    this.wellbeingCategory,
    this.emotionalValence,
    this.emotionalArousal,
    this.emotionalDominance,
    this.detectedEmotions,
    this.detectedThemes,
    this.stressIndicators,
    this.voiceFeatures,
    this.analysisModelVersion,
    this.confidenceScore,
    this.processingDurationMs,
    this.reflectionPrompt,
    this.createdAt,
  });

  factory VocalSentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return VocalSentimentAnalysis(
      id: json['id'],
      vocalEntryId: json['vocal_entry_id'],
      overallWellbeingScore: (json['overall_wellbeing_score'] as num?)?.toDouble(),
      wellbeingCategory: json['wellbeing_category'],
      emotionalValence: (json['emotional_valence'] as num?)?.toDouble(),
      emotionalArousal: (json['emotional_arousal'] as num?)?.toDouble(),
      emotionalDominance: (json['emotional_dominance'] as num?)?.toDouble(),
      detectedEmotions: json['detected_emotions'],
      detectedThemes: (json['detected_themes'] as List?)?.map((e) => e.toString()).toList(),
      stressIndicators: json['stress_indicators'],
      voiceFeatures: json['voice_features'],
      analysisModelVersion: json['analysis_model_version'],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      processingDurationMs: json['processing_duration_ms'],
      reflectionPrompt: json['reflection_prompt'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vocal_entry_id': vocalEntryId,
      'overall_wellbeing_score': overallWellbeingScore,
      'wellbeing_category': wellbeingCategory,
      'emotional_valence': emotionalValence,
      'emotional_arousal': emotionalArousal,
      'emotional_dominance': emotionalDominance,
      'detected_emotions': detectedEmotions,
      'detected_themes': detectedThemes,
      'stress_indicators': stressIndicators,
      'voice_features': voiceFeatures,
      'analysis_model_version': analysisModelVersion,
      'confidence_score': confidenceScore,
      'processing_duration_ms': processingDurationMs,
      'reflection_prompt': reflectionPrompt,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}