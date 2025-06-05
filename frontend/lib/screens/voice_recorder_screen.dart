import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  // State management - seperti remote control untuk tape recorder
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _audioPath;
  
  // Timer untuk durasi recording
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  
  // Animation controllers - seperti DJ mixer dengan efek visual
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  // Simulasi gelombang suara - seperti equalizer
  List<double> _audioLevels = [];
  Timer? _audioLevelTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Pulse animation untuk tombol recording - seperti detak jantung
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

    // Wave animation untuk latar belakang
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _recordingTimer?.cancel();
    _audioLevelTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // Fungsi untuk meminta izin mikrofon - seperti mengetuk pintu sebelum masuk
  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Simulasi level audio - seperti VU meter di studio
  void _startAudioLevelSimulation() {
    _audioLevelTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (_isRecording) {
          setState(() {
            _audioLevels = List.generate(
              20,
              (index) => Random().nextDouble() * 0.8 + 0.2,
            );
          });
        }
      },
    );
  }

  void _stopAudioLevelSimulation() {
    _audioLevelTimer?.cancel();
    setState(() {
      _audioLevels.clear();
    });
  }

  // Fungsi recording - seperti menekan tombol REC di tape recorder
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
      });

      // Mulai animasi dan timer
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

  // Fungsi stop recording - seperti menekan tombol STOP
  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });

      // Stop animasi dan timer
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

  // Fungsi discard - seperti membuang kaset rusak
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
    });
  }

  // Fungsi analyze - seperti mengirim kaset ke ahli untuk dianalisis
  void _analyzeRecording() {
    if (_audioPath != null) {
      // Di sini Anda bisa menambahkan logika untuk mengirim audio ke AI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menganalisis audio...')),
      );
      // TODO: Implementasi analisis AI
    }
  }

  // Format durasi - seperti display timer di tape recorder
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Wave background - seperti latar belakang studio
          Positioned(
            left: screenWidth - 471 + 681,
            top: screenHeight - 932 + 932,
            child: Image.asset(
              'assets/wave_tosca.png',
              width: 471,
              height: 932,
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          Column(
            children: [
              // Header dengan tombol back dan history
              Container(
                padding: const EdgeInsets.only(top: 50),
                child: Row(
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/arrow.png',
                          width: 66,
                          height: 66,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // History button
                    Padding(
                      padding: const EdgeInsets.only(right: 37, top: 33),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Navigate to history
                        },
                        child: Image.asset(
                          'assets/history_button.png',
                          width: 34,
                          height: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 21),

              // Recording area - seperti area utama studio
              Center(
                child: Container(
                  width: 348,
                  height: 164,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EBAB3),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Audio visualization - seperti equalizer
                      if (_isRecording && _audioLevels.isNotEmpty)
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _audioLevels.map((level) {
                              return Container(
                                width: 4,
                                height: level * 60,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      
                      // Recording indicator dan timer
                      if (_isRecording)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(_recordingDuration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Static waveform ketika tidak recording
                      if (!_isRecording && !_hasRecording)
                        Center(
                          child: Icon(
                            Icons.graphic_eq,
                            size: 60,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 454),

              // Recording controls
              Column(
                children: [
                  // Hold to record text
                  const Text(
                    'Hold to record',
                    style: TextStyle(
                      fontSize: 36,
                      color: Color(0xFF001F3F),
                      fontFamily: 'FredokaOne',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Voice record button - seperti tombol besar di mixing console
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    onTap: _hasRecording ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tahan tombol untuk merekam'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _pulseAnimation.value : 1.0,
                          child: Image.asset(
                            'assets/voice_record_button.png',
                            width: 68.44,
                            height: 64,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 159),

                  // Action buttons - seperti kontrol playback di tape deck
                  if (_hasRecording)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Discard button
                        GestureDetector(
                          onTap: _discardRecording,
                          child: Container(
                            width: 108,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Discard',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF001F3F),
                                  fontFamily: 'FredokaOne',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Analyze button
                        GestureDetector(
                          onTap: _analyzeRecording,
                          child: Container(
                            width: 108,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6EBAB3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Analyze',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontFamily: 'FredokaOne',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}