import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:frontend/screens/profile_update_password_screen.dart';

// PERBAIKAN 1: Diubah menjadi StatefulWidget
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    // Panggil API saat halaman pertama kali dibuka
    _userFuture = _authService.getProfile();
  }

  // Fungsi untuk menangani proses logout
  void _handleLogout() async {
    // Tampilkan dialog konfirmasi
    final bool? confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirmLogout == true) {
      await _authService.logout();
      if (mounted) {
        // Arahkan ke halaman sign-in dan hapus semua rute sebelumnya
        Navigator.pushNamedAndRemoveUntil(context, AppRoute.signIn, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      // PERBAIKAN 2: Gunakan FutureBuilder untuk menangani state loading/error/data
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Gagal memuat profil: ${snapshot.error}"));
          }

          final user = snapshot.data!;
          // PERBAIKAN 3: Gunakan data asli, dengan fallback jika data null
          final displayName = user.fullName ?? user.username ?? 'Pengguna Tenang.in';
          final username = '@${user.username ?? user.email}';

          // Membangun UI dengan data dinamis
          return _buildProfileView(context, displayName, username);
        },
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, String displayName, String username) {
    // Seluruh kode UI Anda dari sini ke bawah hampir sama, hanya menambahkan tombol logout
    return SafeArea(
      child: Stack(
        children: [
          // Background dan Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset('assets/images/wave_top.png', width: context.screenWidth, height: context.scaleHeight(200), fit: BoxFit.fill),
          ),
          Positioned(
            top: context.scaleHeight(16), left: context.scaleWidth(8),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset('assets/images/arrow.png', width: context.scaleWidth(66), height: context.scaleHeight(66)),
            ),
          ),
          Positioned(
            top: context.scaleHeight(35), left: 0, right: 0,
            child: Center(
              child: Text('Profile', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColor.putihNormal)),
            ),
          ),

          // Kartu Profil Dinamis
          Positioned(
            top: context.scaleHeight(94), left: context.scaleWidth(25), right: context.scaleWidth(25),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.putihNormal,
                borderRadius: BorderRadius.circular(context.scaleWidth(18)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: context.scaleWidth(52),
                    backgroundImage: const AssetImage('assets/images/profile_photo_pink.png'),
                  ),
                  SizedBox(width: context.scaleWidth(20)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(displayName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis,),
                        SizedBox(height: context.scaleHeight(4)),
                        Text(username, style: GoogleFonts.inter(fontSize: 12, color: Colors.black.withOpacity(0.5))),
                        SizedBox(height: context.scaleHeight(8)),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoute.profileEdit),
                          child: Image.asset('assets/images/edit_profile_button.png', height: context.scaleHeight(48)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Daftar Menu
          Positioned(
            top: context.scaleHeight(271),
            left: context.scaleWidth(25),
            right: context.scaleWidth(25),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoute.settings),
                  child: Image.asset('assets/images/menu_setting.png', fit: BoxFit.fill),
                ),
                SizedBox(height: context.scaleHeight(10)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoute.feedback),
                  child: Image.asset('assets/images/menu_feedback.png', fit: BoxFit.fill),
                ),
                SizedBox(height: context.scaleHeight(10)),
                GestureDetector(
                  // onTap: () => Navigator.pushNamed(context, AppRoute.profileUpdatePassword), // Ganti dengan rute yang benar
                  child: Image.asset('assets/images/menu_update_password.png', fit: BoxFit.fill),
                ),
                SizedBox(height: context.scaleHeight(24)),
                 // FUNGSI BARU: Tombol Logout
                GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    height: context.scaleHeight(58),
                    decoration: BoxDecoration(
                      color: AppColor.merahError.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.merahError)
                    ),
                    child: Center(
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.merahError),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}