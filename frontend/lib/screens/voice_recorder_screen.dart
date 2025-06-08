import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/sentiment_analysis_screen.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'package:frontend/common/app_color.dart'; // Import AppColor
import 'package:frontend/common/screen_utils.dart'; // Import ScreenUtils

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _hasRecording = false;
  String? _audioPath;

  Timer? _recordingTimer;
  int _recordingDuration = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<double> _audioLevels = List.generate(50, (index) => 0.0);
  Timer? _audioLevelTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudioLevels();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeAudioLevels() {
    setState(() {
      _audioLevels = List.generate(
        _audioLevels.length,
        (index) => 0.1,
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    _audioLevelTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  void _startAudioLevelSimulation() {
    _audioLevelTimer = Timer.periodic(
      const Duration(milliseconds: 60),
      (timer) {
        if (_isRecording) {
          setState(() {
            _audioLevels.removeAt(0);
            _audioLevels.add(Random().nextDouble() * 0.7 + 0.3);
          });
        }
      },
    );
  }

  void _stopAudioLevelSimulation() {
    _audioLevelTimer?.cancel();
    setState(() {
      _audioLevels = List.generate(_audioLevels.length, (index) => 0.2);
    });
  }

  Future<void> _startRecording() async {
    if (!await _requestPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin mikrofon diperlukan untuk merekam')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      _audioPath = '${directory.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _audioPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _hasRecording = false;
        _audioLevels = List.generate(_audioLevels.length, (index) => 0.1);
      });

      _pulseController.repeat(reverse: true);
      _startAudioLevelSimulation();
      _startRecordingTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai recording: $e')),
      );
    }
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          _recordingDuration++;
        });
      },
    );
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });

      _pulseController.stop();
      _pulseController.reset();
      _stopAudioLevelSimulation();
      _recordingTimer?.cancel();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghentikan recording: $e')),
      );
    }
  }

  void _discardRecording() {
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    setState(() {
      _hasRecording = false;
      _audioPath = null;
      _recordingDuration = 0;
      _initializeAudioLevels();
    });
  }

  void _analyzeRecording() {
    if (_audioPath != null) {
      // TODO: Logic untuk upload audio ke backend dan panggil API analisis
      // Misalnya:
      // final analysisResult = await AudioAnalysisService.uploadAndAnalyze(_audioPath!);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => SentimentAnalysisScreen(analysisResult: analysisResult),
      //   ),
      // );

      // Untuk saat ini, langsung navigasi dengan audioPath
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SentimentAnalysisScreen(audioPath: _audioPath!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada rekaman untuk dianalisis.')),
      );
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.putihNormal, // Use AppColor
      body: Stack(
        children: [
          // Background wave
          Positioned(
            right: 0,
            top: context.scaleHeight(460), // Use scaled height
            bottom: 0,
            child: Image.asset(
              'assets/images/wave_tosca.png',
              fit: BoxFit.cover,
              width: context.screenWidth, // Ensure it covers full width
            ),
          ),
          // Blur top
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
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: context.scaleHeight(50), left: context.scaleWidth(8), right: context.scaleWidth(37)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        'assets/images/arrow.png',
                        width: context.scaleWidth(66),
                        height: context.scaleHeight(66),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HistoryScreen()),
                        );
                      },
                      child: Image.asset(
                        'assets/images/history_button.png',
                        width: context.scaleWidth(34),
                        height: context.scaleHeight(34),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.scaleHeight(21)),
              Center(
                child: Container(
                  width: context.scaleWidth(348),
                  height: context.scaleHeight(164),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EBAB3), // Use AppColor.hijauTosca
                    borderRadius: BorderRadius.circular(context.scaleWidth(18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: context.scaleWidth(10),
                        offset: Offset(0, context.scaleHeight(4)),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.scaleWidth(20.0)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: _audioLevels.map((level) {
                            return Container(
                              width: context.scaleWidth(4),
                              height: (level * context.scaleHeight(80)).clamp(context.scaleHeight(5), context.scaleHeight(80)),
                              margin: EdgeInsets.symmetric(horizontal: context.scaleWidth(1)),
                              decoration: BoxDecoration(
                                color: AppColor.putihNormal.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(context.scaleWidth(2)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_isRecording)
                        Positioned(
                          top: context.scaleHeight(16),
                          left: context.scaleWidth(16),
                          child: Row(
                            children: [
                              Container(
                                width: context.scaleWidth(12),
                                height: context.scaleHeight(12),
                                decoration: BoxDecoration(
                                  color: AppColor.merahError, // Use AppColor
                                  borderRadius: BorderRadius.circular(context.scaleWidth(6)),
                                ),
                              ),
                              SizedBox(width: context.scaleWidth(8)),
                              Text(
                                _formatDuration(_recordingDuration),
                                style: GoogleFonts.fredoka( // Use GoogleFonts
                                  color: AppColor.putihNormal,
                                  fontSize: context.scaleWidth(16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  if (_isRecording)
                    Text(
                      _formatDuration(_recordingDuration),
                      style: GoogleFonts.fredoka(
                        fontSize: context.scaleWidth(30),
                        color: AppColor.navyText,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else if (_hasRecording)
                    Text(
                      _formatDuration(_recordingDuration),
                      style: GoogleFonts.fredoka(
                        fontSize: context.scaleWidth(30),
                        color: AppColor.navyText,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else
                    Text(
                      'Tap to record',
                      style: GoogleFonts.fredoka(
                        fontSize: context.scaleWidth(30),
                        color: AppColor.navyText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  SizedBox(height: context.scaleHeight(14)),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _pulseAnimation.value : 1.0,
                          child: Image.asset(
                            'assets/images/voice_record_button.png',
                            width: context.scaleWidth(68.44),
                            height: context.scaleHeight(64),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: context.scaleHeight(50)),
                  if (_hasRecording)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: _discardRecording,
                              child: Container(
                                width: context.scaleWidth(108),
                                height: context.scaleHeight(52),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                                ),
                                child: Center(
                                  child: Text(
                                    'Discard',
                                    style: GoogleFonts.fredoka(
                                      fontSize: context.scaleWidth(24),
                                      color: AppColor.navyText,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _analyzeRecording,
                              child: Container(
                                width: context.scaleWidth(108),
                                height: context.scaleHeight(52),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6EBAB3), // Use AppColor.hijauTosca
                                  borderRadius: BorderRadius.circular(context.scaleWidth(12)),
                                ),
                                child: Center(
                                  child: Text(
                                    'Analyze',
                                    style: GoogleFonts.fredoka(
                                      fontSize: context.scaleWidth(24),
                                      color: AppColor.putihNormal,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.scaleHeight(20)),
                      ],
                    )
                  else
                    SizedBox(height: context.scaleHeight(122)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}