import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';

class ProfileFeedbackScreen extends StatefulWidget {
  const ProfileFeedbackScreen({super.key});

  @override
  State<ProfileFeedbackScreen> createState() => _ProfileFeedbackScreenState();
}

class _ProfileFeedbackScreenState extends State<ProfileFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final FocusNode _feedbackFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  String? _feedbackErrorText;

  bool _isResetButtonActive = false;
  bool _isDoneButtonActive = false;

  @override
  void initState() {
    super.initState();
    _feedbackFocusNode.addListener(_onFocusChange);
    _feedbackController.addListener(_clearFeedbackError);
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _clearFeedbackError() {
    if (_feedbackErrorText != null && _feedbackController.text.isNotEmpty) {
      setState(() {
        _feedbackErrorText = null;
      });
    }
  }

  @override
  void dispose() {
    _feedbackController.removeListener(_clearFeedbackError);
    _feedbackController.dispose();
    _feedbackFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmitFeedback() {
    setState(() {
      _feedbackErrorText = null;
    });

    bool isValid = true;
    if (_feedbackController.text.isEmpty) {
      setState(() {
        _feedbackErrorText = 'Feedback tidak boleh kosong';
      });
      isValid = false;
    }

    if (isValid) {
      print('Feedback submitted: ${_feedbackController.text}');

      // snackBar 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback berhasil dikirim!', style: GoogleFonts.roboto(color: AppColor.putihNormal)),
          backgroundColor: AppColor.hijauSuccess,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _handleReset() {
    setState(() {
      _feedbackController.clear();
      _feedbackFocusNode.unfocus();
      _feedbackErrorText = null;
    });
    print('Feedback form reset');
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

              // Text 'Feedback' 
              Positioned(
                top: context.scaleHeight(35),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Feedback',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColor.putihNormal,
                    ),
                  ),
                ),
              ),

              // kotak putih background input feedback
              Positioned(
                top: context.scaleHeight(130), 
                left: context.scaleWidth(25),
                right: context.scaleWidth(25),
                child: Container(
                  width: context.scaleWidth(380),
                  height: context.scaleHeight(373), 
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.scaleWidth(20),
                      vertical: context.scaleHeight(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          Text(
                            'Feedback', 
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColor.navyText,
                            ),
                          ),
                          SizedBox(height: context.scaleHeight(20)),
                          _buildFeedbackInputField(
                            context: context,
                            controller: _feedbackController,
                            focusNode: _feedbackFocusNode,
                            hintText: 'ketik disini',
                            width: context.scaleWidth(330), 
                            height: context.scaleHeight(200), 
                          ),
                          if (_feedbackErrorText != null)
                            Padding(
                              padding: EdgeInsets.only(top: context.scaleHeight(5)),
                              child: Text(
                                _feedbackErrorText!,
                                style: GoogleFonts.roboto(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(height: context.scaleHeight(30)),
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
                                onPressed: _handleSubmitFeedback,
                                isActive: _isDoneButtonActive,
                                onActiveStateChanged: (isActive) {
                                  setState(() => _isDoneButtonActive = isActive);
                                },
                              ),
                            ],
                          ),
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

  // untuk input field feedback 
  Widget _buildFeedbackInputField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required double width,
    required double height,
  }) {
    Color boxColor = AppColor.hijauTosca;
    Color borderColor = focusNode.hasFocus ? AppColor.biruNormal : AppColor.hijauTosca;
    double borderWidth = focusNode.hasFocus ? 2 : 1;
    double blurRadius = focusNode.hasFocus ? 8 : 0;
    Offset offset = focusNode.hasFocus ? const Offset(0, 4) : const Offset(0, 0);

    final double textFontSize = 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(context.scaleWidth(18)),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: blurRadius,
            offset: offset,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.scaleWidth(20), vertical: context.scaleHeight(15)),
        child: TextSelectionTheme(
          data: const TextSelectionThemeData(
            cursorColor: AppColor.navyText,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: null, 
            expands: true, 
            keyboardType: TextInputType.multiline, 
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.top, 
            style: GoogleFonts.fredoka(
              color: AppColor.whiteText,
              fontSize: textFontSize,
              fontWeight: FontWeight.normal,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.fredoka(
                color: AppColor.whiteText.withOpacity(0.7),
                fontSize: textFontSize,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  // untuk button Reset dan Done 
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