import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/data/models/vocal_sentiment_analysis.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  //function warna skor
  Color _getScoreColor(double score) {
    if (score >= 7.0) {
      return AppColor.hijauSuccess; 
    } else if (score >= 4.0) {
      return AppColor.kuning; 
    } else {
      return AppColor.merahError; 
    }
  }

  // sample data 
  final List<VocalSentimentAnalysis> historyData = [
    VocalSentimentAnalysis(
      id: 'history_001',
      vocalEntryId: 'entry_001',
      overallWellbeingScore: 5.5,
      wellbeingCategory: 'Menghadapi beberapa tantangan yang sangat panjang dan mungkin memerlukan dukungan',
      reflectionPrompt: 'Berdasarkan rekaman suara Anda, kami mendeteksi adanya beberapa tantangan yang mungkin sedang Anda hadapi. Penting untuk memproses emosi ini dan mencari dukungan dari orang-orang terdekat atau profesional jika diperlukan.',
      createdAt: DateTime.parse('2025-06-06T10:00:00Z'),
      emotionalValence: 0.1,
      emotionalArousal: 0.2,
      emotionalDominance: 0.0,
      processingDurationMs: 1000,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_002',
      vocalEntryId: 'entry_002',
      overallWellbeingScore: 8.2,
      wellbeingCategory: 'Sangat Positif dan Penuh Semangat',
      reflectionPrompt: 'Rekaman suara Anda memancarkan energi positif dan antusiasme yang tinggi. Terus pertahankan energi positif ini dengan melakukan aktivitas yang Anda sukai, seperti hobi atau olahraga rutin. Selamat!',
      createdAt: DateTime.parse('2025-06-05T14:30:00Z'),
      emotionalValence: 0.8,
      emotionalArousal: 0.7,
      emotionalDominance: 0.5,
      processingDurationMs: 1200,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_003',
      vocalEntryId: 'entry_003',
      overallWellbeingScore: 3.1,
      wellbeingCategory: 'Mengalami Beberapa Kesulitan Emosional Cukup Serius',
      reflectionPrompt: 'Berdasarkan rekaman suara Anda, kami mendeteksi adanya beberapa kesulitan emosional. Kami sarankan untuk mencari dukungan atau melakukan aktivitas relaksasi seperti meditasi atau yoga. Penting untuk istirahat cukup dan menjaga diri.',
      createdAt: DateTime.parse('2025-06-04T09:15:00Z'),
      emotionalValence: -0.5,
      emotionalArousal: -0.3,
      emotionalDominance: -0.1,
      processingDurationMs: 900,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_004',
      vocalEntryId: 'entry_004',
      overallWellbeingScore: 6.8,
      wellbeingCategory: 'Kesejahteraan Cukup Baik',
      reflectionPrompt: 'Analisis suara Anda menunjukkan kesejahteraan yang cukup baik, namun ada ruang untuk peningkatan. Coba eksplorasi aktivitas baru yang menstimulasi pikiran Anda dan tetap jaga komunikasi dengan orang sekitar.',
      createdAt: DateTime.parse('2025-06-03T11:00:00Z'),
      emotionalValence: 0.3,
      emotionalArousal: 0.4,
      emotionalDominance: 0.2,
      processingDurationMs: 1100,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_005',
      vocalEntryId: 'entry_005',
      overallWellbeingScore: 2.1,
      wellbeingCategory: 'Memerlukan Perhatian & Dukungan Mendesak',
      reflectionPrompt: 'Kami mendeteksi adanya beban emosional yang signifikan dari rekaman suara Anda. Kami sangat menyarankan untuk segera mencari bantuan profesional atau berbicara dengan orang yang Anda percayai. Jangan hadapi ini sendirian, ada banyak dukungan yang tersedia.',
      createdAt: DateTime.parse('2025-06-02T16:45:00Z'),
      emotionalValence: -0.8,
      emotionalArousal: -0.7,
      emotionalDominance: -0.6,
      processingDurationMs: 1500,
      analysisModelVersion: 'v1.0',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _buildMainContent(context, screenWidth, screenHeight),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double screenWidth, double screenHeight) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset(
            'assets/images/wave_history_voice.png',
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/blur_top_history.png',
            width: 429,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 16,
          left: 8,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context); 
            },
            child: SizedBox(
              width: 66,
              height: 66,
              child: Image.asset(
                'assets/images/arrow.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        Positioned(
          top: 94,
          left: 16,
          right: 16,
          bottom: 0,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              0,
              8,
              0,
              24, 
            ),
            itemCount: historyData.length,
            itemBuilder: (context, index) {
              final item = historyData[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: HistoryCardItem(
                  item: item,
                  getScoreColor: _getScoreColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- widget card
class HistoryCardItem extends StatelessWidget {
  final VocalSentimentAnalysis item;
  final Function(double) getScoreColor;

  const HistoryCardItem({
    Key? key,
    required this.item,
    required this.getScoreColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemScore = item.overallWellbeingScore ?? 0.0;
    final itemCategory = item.wellbeingCategory ?? 'Analisis Tidak Tersedia';
    final itemReflection = item.reflectionPrompt ?? 'Tidak ada deskripsi.';
    final Color itemColor = getScoreColor(itemScore);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: context.scaleHeight(140),
      ),
      child: IntrinsicHeight(
        child: Container(
          padding: EdgeInsets.all(context.scaleWidth(16)),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: itemColor,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // title dan score
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // kotak title
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(context.scaleWidth(12)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        itemCategory,
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          color: AppColor.navyText,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: context.scaleWidth(12)),
                  
                  // kotak score
                  Container(
                    width: context.scaleWidth(50),
                    height: context.scaleHeight(50),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: itemColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: itemColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        itemScore.round().toString(),
                        style: GoogleFonts.roboto(
                          color: itemColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: context.scaleHeight(12)),
              
              // kotak detail deskripsi
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.scaleWidth(12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  itemReflection,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: AppColor.navyText.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}