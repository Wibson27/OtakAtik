import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart'; 

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.fredoka(
            color: AppColor.navyText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.hijauTosca,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selamat Datang di Tenang.in!',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColor.navyElement,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Ini adalah halaman Dashboard Anda.',
              style: GoogleFonts.poppinsTextTheme().bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                //navigasi ke Forum Discuss
                Navigator.pushNamed(context, AppRoute.forumDiscussList);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kuning,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Pergi ke Forum Diskusi',
                style: GoogleFonts.fredoka(
                  color: AppColor.navyText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                //
                Navigator.pushNamed(context, AppRoute.profile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.biruNormal,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Lihat Profil',
                style: GoogleFonts.fredoka(
                  color: AppColor.putihNormal,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}