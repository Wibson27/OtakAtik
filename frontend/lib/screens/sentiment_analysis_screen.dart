// frontend/lib/screens/sentiment_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/common/color_utils.dart';
import 'package:frontend/data/models/vocal_sentiment_analysis.dart';

class SentimentAnalysisScreen extends StatelessWidget {
  // PERBAIKAN 1: Widget ini sekarang menerima objek VocalSentimentAnalysis yang asli.
  final VocalSentimentAnalysis analysisResult;

  // PERBAIKAN 2: Constructor diubah untuk menerima 'analysisResult', bukan 'audioPath'.
  const SentimentAnalysisScreen({Key? key, required this.analysisResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

    // PERBAIKAN 3: HAPUS 'dummyAnalysisResult' dan gunakan 'analysisResult' yang diterima.
    final itemScore = analysisResult.overallWellbeingScore ?? 0.0;
    final itemCategory = analysisResult.wellbeingCategory ?? 'Analisis Tidak Tersedia';
    final itemReflection = analysisResult.reflectionPrompt ?? 'Tidak ada penjelasan dari hasil analisis.';
    final Color scoreColor = ColorUtils.getScoreColor(itemScore);

    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      body: SafeArea(
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
                width: context.screenWidth,
                height: context.scaleHeight(88),
                fit: BoxFit.fill,
              ),
            ),

            // Header: Tombol kembali ke Dashboard
            Positioned(
              top: context.scaleHeight(16),
              left: context.scaleWidth(8),
              child: GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoute.dashboard, (route) => false),
                child: Image.asset(
                  'assets/images/arrow.png',
                  width: context.scaleWidth(66),
                  height: context.scaleHeight(66),
                ),
              ),
            ),

            // Konten utama yang sekarang dinamis
            Positioned.fill(
              top: context.scaleHeight(88),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: context.scaleWidth(20), vertical: context.scaleHeight(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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

                    // Bagian Skor
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: context.scaleWidth(100),
                          height: context.scaleHeight(50),
                          decoration: BoxDecoration(
                            color: scoreColor,
                            borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                          ),
                          child: Center(
                            child: Text(
                              itemScore.toStringAsFixed(1), // Menampilkan skor asli
                              style: GoogleFonts.roboto(
                                fontSize: 28,
                                color: AppColor.putihNormal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.scaleHeight(25)),

                    // Kategori
                    Text(
                      itemCategory, // Menampilkan kategori asli
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        color: AppColor.navyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: context.scaleHeight(25)),

                    // Box Penjelasan/Refleksi
                    Container(
                      width: screenWidth - context.scaleWidth(40),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(context.scaleWidth(18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: context.scaleWidth(20),
                              vertical: context.scaleHeight(15),
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(context.scaleWidth(18)),
                                topRight: Radius.circular(context.scaleWidth(18)),
                              ),
                            ),
                            child: Text(
                              'Refleksi untuk Anda',
                              style: GoogleFonts.fredoka(
                                fontSize: 24,
                                color: AppColor.putihNormal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(context.scaleWidth(20)),
                            child: Text(
                              itemReflection, // Menampilkan refleksi dinamis dari AI
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: AppColor.putihNormal,
                                height: 1.5,
                              ),
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