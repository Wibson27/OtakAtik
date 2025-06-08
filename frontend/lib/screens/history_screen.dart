import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/common/color_utils.dart'; // Import ColorUtils
import 'package:frontend/data/models/vocal_sentiment_analysis.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? expandedIndex;

  // sample data (akan diganti dengan data dari backend)
  final List<VocalSentimentAnalysis> historyData = [
    VocalSentimentAnalysis(
      id: 'history_001',
      vocalEntryId: 'entry_001',
      overallWellbeingScore: 5.5,
      wellbeingCategory:
          'Menghadapi beberapa tantangan yang sangat panjang dan mungkin memerlukan dukungan',
      reflectionPrompt:
          'Berdasarkan rekaman suara Anda, kami mendeteksi adanya beberapa tantangan yang mungkin sedang Anda hadapi. Penting untuk memproses emosi ini dan mencari dukungan dari orang-orang terdekat atau profesional jika diperlukan. Kami menemukan beberapa tema yang berulang dalam nada suara Anda dan kepuasan dalam percakapan Anda. Ini adalah indikasi yang baik dari well-being Anda.',
      createdAt: DateTime.parse('2025-06-06T10:00:00Z'),
      emotionalValence: 0.1,
      emotionalArousal: 0.2,
      emotionalDominance: 0.0,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_002',
      vocalEntryId: 'entry_002',
      overallWellbeingScore: 8.2,
      wellbeingCategory: 'Sangat Positif dan Penuh Semangat',
      reflectionPrompt:
          'Rekaman suara Anda memancarkan energi positif dan antusiasme yang tinggi. Terus pertahankan energi positif ini dengan melakukan aktivitas yang Anda sukai, seperti hobi atau olahraga rutin. Selamat!',
      createdAt: DateTime.parse('2025-06-05T14:30:00Z'),
      emotionalValence: 0.8,
      emotionalArousal: 0.7,
      emotionalDominance: 0.5,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_003',
      vocalEntryId: 'entry_003',
      overallWellbeingScore: 3.1,
      wellbeingCategory: 'Mengalami Beberapa Kesulitan Emosional Cukup Serius',
      reflectionPrompt:
          'Berdasarkan rekaman suara Anda, kami mendeteksi adanya beberapa kesulitan emosional. Kami sarankan untuk mencari dukungan atau melakukan aktivitas relaksasi seperti meditasi atau yoga. Penting untuk istirahat cukup dan menjaga diri.',
      createdAt: DateTime.parse('2025-06-04T09:15:00Z'),
      emotionalValence: -0.5,
      emotionalArousal: -0.3,
      emotionalDominance: -0.1,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_004',
      vocalEntryId: 'entry_004',
      overallWellbeingScore: 6.8,
      wellbeingCategory: 'Kesejahteraan Cukup Baik',
      reflectionPrompt:
          'Analisis suara Anda menunjukkan kesejahteraan yang cukup baik, namun ada ruang untuk peningkatan. Coba eksplorasi aktivitas baru yang menstimulasi pikiran Anda dan tetap jaga komunikasi dengan orang sekitar.',
      createdAt: DateTime.parse('2025-06-03T11:00:00Z'),
      emotionalValence: 0.3,
      emotionalArousal: 0.4,
      emotionalDominance: 0.2,
      analysisModelVersion: 'v1.0',
    ),
    VocalSentimentAnalysis(
      id: 'history_005',
      vocalEntryId: 'entry_005',
      overallWellbeingScore: 2.1,
      wellbeingCategory: 'Memerlukan Perhatian & Dukungan Mendesak',
      reflectionPrompt:
          'Kami mendeteksi adanya beban emosional yang signifikan dari rekaman suara Anda. Kami sangat menyarankan untuk segera mencari bantuan profesional atau berbicara dengan orang yang Anda percayai. Jangan hadapi ini sendirian, ada banyak dukungan yang tersedia.',
      createdAt: DateTime.parse('2025-06-02T16:45:00Z'),
      emotionalValence: -0.8,
      emotionalArousal: -0.7,
      emotionalDominance: -0.6,
      analysisModelVersion: 'v1.0',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

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

  Widget _buildMainContent(
      BuildContext context, double screenWidth, double screenHeight) {
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
            width: screenWidth, // Use scaled width
            height: context.scaleHeight(88),
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: context.scaleHeight(16),
          left: context.scaleWidth(8),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: SizedBox(
              width: context.scaleWidth(66),
              height: context.scaleHeight(66),
              child: Image.asset(
                'assets/images/arrow.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          top: context.scaleHeight(94),
          left: context.scaleWidth(16),
          right: context.scaleWidth(16),
          bottom: 0,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              0,
              context.scaleHeight(8),
              0,
              context.scaleHeight(24),
            ),
            itemCount: historyData.length,
            itemBuilder: (context, index) {
              final item = historyData[index];
              final isExpanded = expandedIndex == index;

              return Padding(
                padding: EdgeInsets.only(bottom: context.scaleHeight(16)),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      expandedIndex = isExpanded ? null : index;
                    });
                  },
                  child: HistoryCardItem(
                    item: item,
                    isExpanded: isExpanded,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HistoryCardItem extends StatelessWidget {
  final VocalSentimentAnalysis item;
  final bool isExpanded;

  const HistoryCardItem({
    Key? key,
    required this.item,
    required this.isExpanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemScore = item.overallWellbeingScore ?? 0.0;
    final itemCategory = item.wellbeingCategory ?? 'Analisis Tidak Tersedia';
    final itemReflection = item.reflectionPrompt ?? 'Tidak ada deskripsi.';
    final Color itemColor = ColorUtils.getScoreColor(itemScore); // Menggunakan ColorUtils

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.scaleWidth(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF80C2BC), // Warna hijau Tosca dengan hex code 80C2BC (bisa diganti AppColor.hijauTosca)
        borderRadius: BorderRadius.circular(context.scaleWidth(16)),
        boxShadow: [
          BoxShadow(
            color: itemColor.withOpacity(0.5),
            blurRadius: context.scaleWidth(8),
            offset: Offset(context.scaleWidth(2), context.scaleHeight(-2)),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(context.scaleWidth(12)),
                    decoration: BoxDecoration(
                      color: AppColor.putihNormal, // Use AppColor
                      borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: context.scaleWidth(4),
                          offset: Offset(0, context.scaleHeight(2)),
                        ),
                      ],
                    ),
                    child: Text(
                      itemCategory,
                      style: GoogleFonts.fredoka(
                        fontSize: context.scaleWidth(15),
                        color: AppColor.navyText, // Use AppColor
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.left,
                      maxLines: isExpanded ? null : 3,
                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: context.scaleWidth(12)),
                Container(
                  width: context.scaleWidth(50),
                  height: context.scaleHeight(50),
                  decoration: BoxDecoration(
                    color: itemColor,
                    borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                    boxShadow: [
                      BoxShadow(
                        color: itemColor.withOpacity(0.4),
                        blurRadius: context.scaleWidth(8),
                        offset: Offset(0, context.scaleHeight(2)),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      itemScore.round().toString(),
                      style: GoogleFonts.roboto(
                        color: AppColor.putihNormal, // Use AppColor
                        fontSize: context.scaleWidth(22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.scaleHeight(12)),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState:
                  isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.scaleWidth(12)),
                decoration: BoxDecoration(
                  color: AppColor.putihNormal, // Use AppColor
                  borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: context.scaleWidth(4),
                      offset: Offset(0, context.scaleHeight(2)),
                    ),
                  ],
                ),
                child: Text(
                  itemReflection,
                  style: GoogleFonts.fredoka(
                    fontSize: context.scaleWidth(13),
                    color: AppColor.navyText.withOpacity(0.8), // Use AppColor
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              secondChild: Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.scaleWidth(12)),
                decoration: BoxDecoration(
                  color: AppColor.putihNormal, // Use AppColor
                  borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: context.scaleWidth(4),
                      offset: Offset(0, context.scaleHeight(2)),
                    ),
                  ],
                ),
                child: Text(
                  itemReflection,
                  style: GoogleFonts.fredoka(
                    fontSize: context.scaleWidth(13),
                    color: AppColor.navyText.withOpacity(0.8), // Use AppColor
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}