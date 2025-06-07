import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/data/models/vocal_sentiment_analysis.dart';

class SentimentAnalysisScreen extends StatelessWidget {
  final String audioPath;

  final VocalSentimentAnalysis dummyAnalysisResult = VocalSentimentAnalysis(
    id: 'analysis_result_001',
    vocalEntryId: 'entry_dummy',
    overallWellbeingScore: 7.5, // Contoh skor positif (akan jadi hijau)
    // overallWellbeingScore: 5.0, // Contoh skor netral (akan jadi kuning)
    // overallWellbeingScore: 2.5, // Contoh skor negatif (akan jadi merah)
    wellbeingCategory: 'Kesejahteraan Positif dan Stabil',
    reflectionPrompt: 'Berdasarkan rekaman suara Anda, sistem kami mendeteksi bahwa kondisi emosional Anda saat ini cenderung positif dan stabil. Angka 5 ini merefleksikan suasana hati yang baik dan adanya keseimbangan. Kami menemukan beberapa tema yang menunjukkan adanya rasa tenang dan kepuasan dalam narasi Anda. Ini adalah indikasi yang baik dari well-being Anda.',
    createdAt: DateTime.now(),
    emotionalValence: 0.6, emotionalArousal: 0.3, emotionalDominance: 0.4,
    processingDurationMs: 2500, analysisModelVersion: 'v1.1',
  );

  SentimentAnalysisScreen({Key? key, required this.audioPath}) : super(key: key);

  Color _getScoreColor(double score) {
    if (score >= 7.0) {
      return AppColor.hijauSuccess; // Sangat Positif
    } else if (score >= 4.0) {
      return AppColor.kuning; // Netral/Cukup Positif
    } else {
      return AppColor.merahError; // Negatif/Membutuhkan Perhatian
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

    // Data dari dummyAnalysisResult
    final itemScore = dummyAnalysisResult.overallWellbeingScore ?? 0.0;
    final itemCategory = dummyAnalysisResult.wellbeingCategory ?? 'Analisis Tidak Tersedia';
    final itemReflection = dummyAnalysisResult.reflectionPrompt ?? 'Tidak ada penjelasan.';
    final Color scoreColor = _getScoreColor(itemScore);

    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      body: SafeArea( // <-- BARU: Membungkus seluruh konten dengan SafeArea
        child: Stack(
          children: [
            // Background wave
            Positioned.fill(
              child: Image.asset(
                'assets/images/wave_history_voice.png',
                fit: BoxFit.cover,
              ),
            ),

            // Header Blur Top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/blur_top_history.png',
                width: context.scaleWidth(429),
                height: context.scaleHeight(88),
                fit: BoxFit.fill,
              ),
            ),

            // Header: Back Button
            Positioned(
              top: context.scaleHeight(16),
              left: context.scaleWidth(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  'assets/images/arrow.png',
                  width: context.scaleWidth(66),
                  height: context.scaleHeight(66),
                ),
              ),
            ),

            // Header: Judul Halaman
            Positioned(
              top: context.scaleHeight(33),
              left: context.scaleWidth(8) + context.scaleWidth(66) + context.scaleWidth(10),
              child: Text(
                'Voice Sentiment - Result',
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  color: AppColor.navyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Main Content Area (Waveform, Score, Info, Penjelasan)
            Positioned.fill(
              top: context.scaleHeight(88), // Dimulai di bawah header blur
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.scaleWidth(20), vertical: context.scaleHeight(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Box Waveform
                    Container(
                      width: context.scaleWidth(348),
                      height: context.scaleHeight(164),
                      decoration: BoxDecoration(
                        color: AppColor.hijauTosca,
                        borderRadius: BorderRadius.circular(context.scaleWidth(18)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.graphic_eq,
                          size: context.scaleHeight(100),
                          color: AppColor.putihNormal.withOpacity(0.8),
                        ),
                      ),
                    ),

                    SizedBox(height: context.scaleHeight(25)),

                    // Box Score & Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Box Score
                        Container(
                          width: context.scaleWidth(100),
                          height: context.scaleHeight(50),
                          decoration: BoxDecoration(
                            color: scoreColor,
                            borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              itemScore.round().toString(),
                              style: GoogleFonts.roboto(
                                fontSize: 28,
                                color: AppColor.putihNormal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: context.scaleWidth(15)),

                        // Box Info
                        Container(
                          width: context.scaleWidth(100),
                          height: context.scaleHeight(50),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                            border: Border.all(color: scoreColor, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/info_symbol.png',
                              width: context.scaleWidth(30),
                              height: context.scaleHeight(30),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.scaleHeight(25)),

                    // Teks Kategori Analisis
                    Text(
                      itemCategory,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        color: AppColor.navyText,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: context.scaleHeight(25)),

                    // Box Penjelasan (Konten Utama)
                    Container(
                      width: screenWidth - context.scaleWidth(40),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.8),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(context.scaleWidth(30)),
                          topRight: Radius.circular(context.scaleWidth(30)),
                          bottomLeft: Radius.circular(context.scaleWidth(10)),
                          bottomRight: Radius.circular(context.scaleWidth(10)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bagian Judul "Penjelasan"
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: context.scaleWidth(20),
                              vertical: context.scaleHeight(15),
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(context.scaleWidth(30)),
                                topRight: Radius.circular(context.scaleWidth(30)),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Penjelasan',
                              style: GoogleFonts.fredoka(
                                fontSize: 24,
                                color: AppColor.putihNormal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Garis Pemisah (Divider)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColor.putihNormal.withOpacity(0.5),
                            indent: context.scaleWidth(20),
                            endIndent: context.scaleWidth(20),
                          ),
                          // Konten Teks Penjelasan
                          Padding(
                            padding: EdgeInsets.all(context.scaleWidth(20)),
                            child: Text(
                              itemReflection,
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: AppColor.putihNormal,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.scaleHeight(40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}