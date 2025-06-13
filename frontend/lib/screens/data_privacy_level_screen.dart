import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/screen_utils.dart'; 
import 'package:frontend/common/app_route.dart'; 

class DataPrivacyLevelScreen extends StatelessWidget {
  const DataPrivacyLevelScreen({super.key});

  final String _privacyPolicyText = """
1. Pendahuluan
Selamat datang di "Tenang.in", platform kesehatan mental digital yang dirancang sebagai teman suportif dalam perjalanan kesejahteraan emosional Anda. Kami berkomitmen penuh untuk melindungi privasi dan keamanan data pribadi Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan membagikan informasi Anda saat Anda menggunakan aplikasi dan layanan kami. Kami membangun platform ini dengan mengutamakan privasi pengguna dan memberikan kontrol penuh kepada Anda atas data Anda.

2. Informasi yang Kami Kumpulkan
Kami mengumpulkan informasi untuk menyediakan dan meningkatkan layanan kami kepada Anda. Ini mencakup:
* Informasi yang Anda Berikan Secara Langsung:
* Data Akun: Saat pendaftaran, kami mengumpulkan email Anda. Anda mungkin juga secara opsional memberikan username, nama lengkap, tanggal lahir, dan zona waktu Anda.
* Konten Chatbot: Percakapan Anda dengan "Tenang Assistant" disimpan dan dienkripsi untuk menjaga konteks dan memungkinkan Anda melanjutkan diskusi.
* Jurnal Vokal: Rekaman suara Anda ("Echo Heart") disimpan untuk analisis AI dan refleksi diri. Anda memiliki kontrol penuh untuk mengaktifkan/menonaktifkan transkripsi dan menghapus rekaman kapan saja.
* Konten Komunitas: Postingan dan balasan Anda di komunitas "Safe Space" disimpan untuk memfasilitasi dukungan. Anda memiliki opsi untuk berpartisipasi secara anonim.
* Preferensi: Pilihan Anda terkait notifikasi chat, notifikasi komunitas, jadwal notifikasi, mode anonim default di komunitas, dan opsi pemantauan media sosial.
* Informasi yang Kami Kumpulkan Secara Otomatis:
* Data Teknis dan Penggunaan: Informasi tentang bagaimana Anda mengakses dan menggunakan aplikasi, seperti sesi login, informasi perangkat, alamat IP, dan waktu aktivitas terakhir.
* Metadata Media Sosial (Opsional): Jika Anda memilih untuk menautkan akun media sosial dan mengaktifkan fitur "Pemantauan Media Sosial", kami menganalisis metadata postingan (bukan konten asli) untuk mendeteksi pola indikasi tekanan emosional.
* Hasil Analisis AI: Berdasarkan rekaman jurnal vokal Anda, kami menghasilkan skor kesejahteraan, kategori emosi, valence, arousal, dominasi, emosi terdeteksi, tema terdeteksi, indikator stres, dan fitur suara. Data ini untuk membantu kesadaran diri dan refleksi, bukan diagnosis medis.

3. Bagaimana Kami Menggunakan Informasi Anda
Kami menggunakan informasi yang kami kumpulkan untuk tujuan berikut:
* Menyediakan dan memelihara layanan "Tenang.in", termasuk fitur AI Chatbot, Jurnal Vokal, dan Komunitas.
* Mempersonalisasi pengalaman Anda, seperti notifikasi proaktif dan respons AI yang empati berdasarkan konteks Anda.
* Membantu Anda meningkatkan kesadaran diri dan mengelola stres melalui refleksi dan dukungan AI.
* Memfasilitasi dukungan emosional dalam komunitas yang aman dan non-judgmental.
* Mendeteksi potensi krisis emosional dan menyediakan eskalasi ke bantuan profesional jika diperlukan.
* Menganalisis penggunaan dan tren untuk meningkatkan fungsionalitas, kinerja, dan kualitas aplikasi kami (menggunakan data yang teranonimkan atau teragregasi).
* Memastikan keamanan aplikasi kami, termasuk mencegah penyalahgunaan dan penipuan.

4. Berbagi dan Pengungkapan Informasi Anda
Kami tidak membagikan data pribadi Anda dengan pihak ketiga, kecuali dalam situasi berikut:
* Penyedia Layanan Pihak Ketiga: Kami menggunakan layanan pihak ketiga yang terpercaya (misalnya, Azure OpenAI Service, Azure Speech Services, HuggingFace wav2vec2, Azure Text Analytics) untuk memproses data demi mengaktifkan fitur-fitur utama aplikasi (seperti speech-to-text, analisis sentimen, dan respons chatbot). Penyedia ini terikat perjanjian kerahasiaan dan hanya dapat menggunakan data untuk tujuan yang ditentukan. Semua komunikasi dengan layanan ini dienkripsi.
* Dengan Persetujuan Anda: Kami dapat membagikan informasi Anda jika Anda memberikan persetujuan eksplisit, seperti saat Anda memilih untuk berpartisipasi di komunitas tanpa mode anonim atau mengaktifkan integrasi media sosial.
* Data Agregat/Anonim: Kami dapat membagikan informasi non-pribadi, teragregasi, atau teranonimkan untuk riset, analisis, atau tujuan pemasaran. Informasi ini tidak dapat digunakan untuk mengidentifikasi Anda secara pribadi.
* Kewajiban Hukum: Kami dapat mengungkapkan informasi Anda jika diwajibkan oleh hukum, panggilan pengadilan, atau proses hukum lainnya, atau jika kami yakin bahwa pengungkapan tersebut diperlukan untuk melindungi hak, properti, atau keamanan kami, pengguna kami, atau publik.

5. Keamanan Data Anda
Kami mengambil langkah-langkah keamanan yang wajar untuk melindungi informasi Anda dari akses, penggunaan, atau pengungkapan yang tidak sah. Langkah-langkah ini meliputi:
* Enkripsi end-to-end untuk data sensitif.
* File audio dienkripsi saat disimpan (at rest) dan saat dalam transmisi (in transit).
* Implementasi Privacy by Design dengan pengumpulan data minimal yang diperlukan.
* Validasi input yang komprehensif untuk mencegah kerentanan.
* Pencatatan audit untuk memantau keamanan.

6. Kontrol dan Hak Anda
Anda memiliki kontrol penuh atas data Anda di "Tenang.in":
* Akses dan Koreksi: Anda dapat mengakses dan memperbarui informasi akun Anda kapan saja melalui pengaturan profil.
* Penghapusan Data: Anda memiliki hak untuk menghapus rekaman jurnal vokal dan data Anda kapan saja. Aplikasi mematuhi kepatuhan GDPR terkait hak untuk menghapus data.
* Menarik Persetujuan: Anda dapat mencabut persetujuan untuk fitur opt-in seperti pemantauan media sosial kapan saja.
* Preferensi Komunikasi: Anda dapat mengatur preferensi notifikasi Anda.

7. Perubahan pada Kebijakan Privasi Ini
Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Kami akan memberitahu Anda tentang perubahan signifikan dengan memposting kebijakan baru di aplikasi dan/atau melalui notifikasi lainnya. Anda disarankan untuk meninjau Kebijakan Privasi ini secara berkala.

8. Hubungi Kami
Jika Anda memiliki pertanyaan atau kekhawatiran tentang Kebijakan Privasi ini atau praktik data kami, silakan hubungi kami melalui:
* [Email Support Anda]
* [Alamat Fisik Perusahaan Anda (Opsional)]
* [Link ke Formulir Kontak di Situs Web (Opsional)]
""";

  @override
  Widget build(BuildContext context) {
    final double screenWidth = context.screenWidth;
    final double screenHeight = context.screenHeight;
    final double cardHeight = context.scaleHeight(403);
    final double cardWidth = context.scaleWidth(380);
    final double scrollableAreaPaddingTop = context.scaleHeight(78);
    final double scrollableAreaPaddingBottom = context.scaleHeight(30); 


    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // wave_top.png 
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/wave_top.png',
                  width: context.scaleWidth(431.5),
                  height: context.scaleHeight(200),
                  fit: BoxFit.fill,
                ),
              ),

              // arrow.png 
              Positioned(
                top: context.scaleHeight(16),
                left: context.scaleWidth(8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset(
                    'assets/images/arrow.png',
                    width: context.scaleWidth(66),
                    height: context.scaleHeight(66),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Text 'Data Privacy Level'
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Data Privacy Level',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // card yang bisa di scroll
              Positioned(
                top: context.scaleHeight(265),
                left: context.scaleWidth((431.5 - 380) / 2),
                right: context.scaleWidth((431.5 - 380) / 2),
                child: Container(
                  width: cardWidth,
                  height: cardHeight, 
                  clipBehavior: Clip.antiAlias, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.scaleWidth(18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack( 
                    children: [
                      // frame_data_privacy_level.png
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/frame_data_privacy_level.png',
                          fit: BoxFit.fill, 
                        ),
                      ),
                      // untuk scroll
                      Positioned(
                        top: scrollableAreaPaddingTop, 
                        left: context.scaleWidth(19),
                        right: context.scaleWidth(13),
                        bottom: scrollableAreaPaddingBottom,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _privacyPolicyText,
                                textAlign: TextAlign.justify,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black.withOpacity(0.8),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Bar Bawah 
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: context.scaleHeight(100),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColor.putihNormal,
                    border: Border(
                      top: BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, AppRoute.dashboard);
                        },
                        child: Image.asset(
                          'assets/images/home_button_profile.png',
                          width: context.scaleWidth(46),
                          height: context.scaleHeight(50),
                          fit: BoxFit.contain,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, AppRoute.profile);
                        },
                        child: Image.asset(
                          'assets/images/button_profile.png',
                          width: context.scaleWidth(68),
                          height: context.scaleHeight(68),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}