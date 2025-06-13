// frontend/lib/data/models/vocal_sentiment_analysis.dart

import 'package:flutter/material.dart';

class VocalSentimentAnalysis {
  final String id;
  final String vocalEntryId;
  final double? overallWellbeingScore;
  final String? wellbeingCategory;
  final String? reflectionPrompt;
  final DateTime? createdAt;

  // Anda bisa menyimpan data mentah ini jika perlu, atau hapus jika tidak digunakan di UI
  final double? emotionalValence;
  final double? emotionalArousal;
  final double? emotionalDominance;
  final int? processingDurationMs;
  final String? analysisModelVersion;

  VocalSentimentAnalysis({
    required this.id,
    required this.vocalEntryId,
    this.overallWellbeingScore,
    this.wellbeingCategory,
    this.reflectionPrompt,
    this.createdAt,
    this.emotionalValence,
    this.emotionalArousal,
    this.emotionalDominance,
    this.processingDurationMs,
    this.analysisModelVersion,
  });

  factory VocalSentimentAnalysis.fromJson(Map<String, dynamic> json) {
    // Helper untuk parsing tanggal dengan aman
    DateTime? parseDate(String? dateStr) {
      return dateStr != null ? DateTime.tryParse(dateStr) : null;
    }

    return VocalSentimentAnalysis(
      // PERBAIKAN UTAMA: Tambahkan null-safety checks '??' dengan nilai default
      // untuk semua properti non-nullable yang berasal dari JSON.
      id: json['ID'] as String? ?? 'fallback_id_${DateTime.now().millisecondsSinceEpoch}',
      vocalEntryId: json['VocalEntryID'] as String? ?? '',

      // Parsing aman untuk properti nullable
      overallWellbeingScore: (json['OverallWellbeingScore'] as num?)?.toDouble(),
      wellbeingCategory: json['WellbeingCategory'] as String?,
      reflectionPrompt: json['ReflectionPrompt'] as String?,
      createdAt: parseDate(json['CreatedAt'] as String?),

      // Parsing data opsional lainnya
      emotionalValence: (json['EmotionalValence'] as num?)?.toDouble(),
      emotionalArousal: (json['EmotionalArousal'] as num?)?.toDouble(),
      emotionalDominance: (json['EmotionalDominance'] as num?)?.toDouble(),
      processingDurationMs: json['ProcessingDurationMs'] as int?,
      analysisModelVersion: json['AnalysisModelVersion'] as String?,
    );
  }
}