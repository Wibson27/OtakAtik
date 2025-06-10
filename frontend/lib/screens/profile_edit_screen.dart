// lib/screens/profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
// Import model User jika nanti akan menampilkan data user dari model
// import 'package:frontend/data/models/user.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Controllers input
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // FocusNodes
  final FocusNode _displayNameFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();

  // GlobalKey for Form
  final _formKey = GlobalKey<FormState>();

  // Error texts
  String? _displayNameErrorText;
  String? _usernameErrorText;

  // efek animation button reset and done
  bool _isResetButtonActive = false;
  bool _isDoneButtonActive = false;

  @override
  void initState() {
    super.initState();
    _displayNameFocusNode.addListener(_onFocusChange);
    _usernameFocusNode.addListener(_onFocusChange);
    _displayNameController.addListener(_clearDisplayNameError);
    _usernameController.addListener(_clearUsernameError);

    // TODO: Load existing user data into controllers from actual user model
    _displayNameController.text = 'El fonso mantey'; // Dummy data dari Figma
    _usernameController.text = '@Elcuphacabra'; // Dummy data dari Figma
  }

  void _onFocusChange() {
    setState(() {}); // Untuk me-rebuild UI saat fokus berubah
  }

  void _clearDisplayNameError() {
    if (_displayNameErrorText != null && _displayNameController.text.isNotEmpty) {
      setState(() {
        _displayNameErrorText = null;
      });
    }
  }

  void _clearUsernameError() {
    if (_usernameErrorText != null && _usernameController.text.isNotEmpty) {
      setState(() {
        _usernameErrorText = null;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.removeListener(_clearDisplayNameError);
    _usernameController.removeListener(_clearUsernameError);
    _displayNameController.dispose();
    _usernameController.dispose();
    _displayNameFocusNode.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  // method untuk handle update profile
  void _handleUpdateProfile() {
    setState(() {
      _displayNameErrorText = null;
      _usernameErrorText = null;
    });

    bool isValid = true;

    // Validate Display Name
    if (_displayNameController.text.isEmpty) {
      setState(() {
        _displayNameErrorText = 'Nama tidak boleh kosong';
      });
      isValid = false;
    }

    // Validate Username
    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameErrorText = 'Nama pengguna tidak boleh kosong';
      });
      isValid = false;
    } else if (!_usernameController.text.startsWith('@')) {
      setState(() {
        _usernameErrorText = 'Username harus diawali dengan @';
      });
      isValid = false;
    }


    if (isValid) {
      // Jika form valid, lakukan proses update profil
      print('Display Name: ${_displayNameController.text}');
      print('Username: ${_usernameController.text}');
      // TODO: Panggil API backend untuk update profil
      // Misalnya: context.read<UserCubit>().updateProfile(_displayNameController.text, _usernameController.text);
      Navigator.pop(context); // Kembali ke ProfileScreen setelah berhasil update
      // Tampilkan SnackBar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil berhasil diupdate!', style: GoogleFonts.roboto(color: AppColor.putihNormal)),
          backgroundColor: AppColor.hijauSuccess,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleReset() {
    setState(() {
      _displayNameController.text = 'El fonso mantey'; // Reset ke dummy awal
      _usernameController.text = '@Elcuphacabra'; // Reset ke dummy awal
      _displayNameFocusNode.unfocus();
      _usernameFocusNode.unfocus();
      _displayNameErrorText = null;
      _usernameErrorText = null;
    });
    print('Profile reset');
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = context.screenWidth;
    final double screenHeight = context.screenHeight;

    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              // wave_top.png (background atas)
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

              // arrow.png (tombol kembali)
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

              // Text 'Edit Profile' - posisinya di wave_top
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.roboto( // Menggunakan Roboto untuk teks judul
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal, // Warna putihNormal agar sesuai
                    ),
                  ),
                ),
              ),

              // Konten Utama Edit Profile (Rectangle 31)
              Positioned(
                top: context.scaleHeight(200), // Posisi container putih disesuaikan
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Container(
                  width: context.scaleWidth(380),
                  // Tinggi container bisa disesuaikan atau dihilangkan jika pakai SingleChildScrollView
                  // height: context.scaleHeight(373),
                  decoration: BoxDecoration(
                    color: AppColor.putihNormal,
                    borderRadius: BorderRadius.circular(context.scaleWidth(18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView( // Tambahkan SingleChildScrollView
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: context.scaleHeight(60)),

                          // Bagian Foto Profil
                          Container(
                            width: context.scaleWidth(104),
                            height: context.scaleHeight(104),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(context.scaleWidth(52)),
                              border: Border.all(
                                color: AppColor.putihNormal.withOpacity(0.5),
                                width: context.scaleWidth(2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(context.scaleWidth(52)),
                              child: Image.asset(
                                'assets/images/profile_photo_pink.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.person, size: context.scaleWidth(60), color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: context.scaleHeight(15)),

                          Text(
                            'Ubah foto profil',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5CC4BB),
                            ),
                          ),
                          SizedBox(height: context.scaleHeight(50)), // Jarak ke input fields

                          // Input Field Display Name
                          _buildInputField(
                            context: context,
                            controller: _displayNameController,
                            focusNode: _displayNameFocusNode,
                            hintText: 'Nama',
                            width: context.scaleWidth(297),
                            height: context.scaleHeight(50), // Ubah tinggi menjadi 50
                            validator: (value) {
                              return null; // Validasi akan dilakukan di _handleUpdateProfile
                            },
                          ),
                          // Untuk menampilkan error Display Name
                          if (_displayNameErrorText != null)
                            Padding(
                              padding: EdgeInsets.only(top: context.scaleHeight(5)),
                              child: Text(
                                _displayNameErrorText!,
                                style: GoogleFonts.roboto(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(height: context.scaleHeight(20)),

                          // Input Field Username
                          _buildInputField(
                            context: context,
                            controller: _usernameController,
                            focusNode: _usernameFocusNode,
                            hintText: 'Nama pengguna',
                            width: context.scaleWidth(297),
                            height: context.scaleHeight(50), // Ubah tinggi menjadi 50
                            validator: (value) {
                              return null; // Validasi akan dilakukan di _handleUpdateProfile
                            },
                          ),
                          // Untuk menampilkan error Username
                          if (_usernameErrorText != null)
                            Padding(
                              padding: EdgeInsets.only(top: context.scaleHeight(5)),
                              child: Text(
                                _usernameErrorText!,
                                style: GoogleFonts.roboto(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(height: context.scaleHeight(50)), // Jarak ke tombol

                          // Buttons: Reset dan Done
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                context: context,
                                text: 'Reset',
                                buttonWidth: 127,
                                buttonHeight: 46,
                                backgroundColor: AppColor.hijauTosca,
                                textColor: AppColor.whiteText,
                                onPressed: _handleReset,
                                isActive: _isResetButtonActive,
                                onActiveStateChanged: (isActive) {
                                  setState(() => _isResetButtonActive = isActive);
                                },
                              ),
                              SizedBox(width: context.scaleWidth(20)),
                              _buildActionButton(
                                context: context,
                                text: 'Done',
                                buttonWidth: 157,
                                buttonHeight: 46,
                                backgroundColor: AppColor.kuning,
                                textColor: AppColor.whiteText,
                                onPressed: _handleUpdateProfile,
                                isActive: _isDoneButtonActive,
                                onActiveStateChanged: (isActive) {
                                  setState(() => _isDoneButtonActive = isActive);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: context.scaleHeight(20)), // Jarak di bawah tombol
                        ],
                      ),
                    ),
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

  // _buildInputField kustom
  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required double width,
    required double height,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    Color boxColor = AppColor.hijauTosca;
    Color borderColor = focusNode.hasFocus ? AppColor.biruNormal : AppColor.hijauTosca;
    double borderWidth = focusNode.hasFocus ? 2 : 1;
    double blurRadius = focusNode.hasFocus ? 8 : 0;
    Offset offset = focusNode.hasFocus ? const Offset(0, 4) : const Offset(0, 0);

    final double textFontSize = 16.0; // Ukuran font dari Figma

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(context.scaleWidth(25)),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: blurRadius,
            offset: offset,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.scaleWidth(20),
            vertical: (height - textFontSize * 1.0 - borderWidth * 2) / 2, // Sesuaikan padding vertikal
          ).clamp(
            EdgeInsets.zero,
            EdgeInsets.all(context.scaleWidth(10)),
          ),
          child: TextSelectionTheme(
            data: const TextSelectionThemeData(
              cursorColor: AppColor.navyText,
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.fredoka( // Menggunakan Fredoka agar konsisten
                color: AppColor.whiteText,
                fontSize: textFontSize,
                fontWeight: FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.fredoka( // Menggunakan Fredoka agar konsisten
                  color: AppColor.whiteText.withOpacity(0.7),
                  fontSize: textFontSize,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk button Reset dan Done (sama dengan ProfileUpdatePasswordScreen)
  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required double buttonWidth,
    required double buttonHeight,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    required bool isActive,
    required Function(bool) onActiveStateChanged,
  }) {
    return GestureDetector(
      onTapDown: (_) => onActiveStateChanged(true),
      onTapUp: (_) => onActiveStateChanged(false),
      onTapCancel: () => onActiveStateChanged(false),
      onTap: onPressed,
      child: AnimatedScale(
        scale: isActive ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: context.scaleWidth(buttonWidth),
          height: context.scaleHeight(buttonHeight),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(context.scaleWidth(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}