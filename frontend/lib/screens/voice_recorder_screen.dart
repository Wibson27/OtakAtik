import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/sentiment_analysis_screen.dart';
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

  bool _isRecording = false;
  bool _hasRecording = false; 
  String? _audioPath;

  // Timer durasi recording
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Simulasi garis untuk visualisasi audio
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

  // toggle recording
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            right: 0,
            top: 460,
            bottom: 0,
            child: Image.asset(
              'assets/images/wave_tosca.png',
              fit: BoxFit.cover,
            ),
          ),

          
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50, left: 8, right: 37),
                child: Row(
                  children: [
                    // arrow button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        'assets/images/arrow.png',
                        width: 66,
                        height: 66,
                      ),
                    ),
                    const Spacer(),
                    // history button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>  HistoryScreen()),
                        );
                      },
                      child: Image.asset(
                        'assets/images/history_button.png',
                        width: 34,
                        height: 34,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 21),

              // Recording area
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
                    alignment: Alignment.center,
                    children: [
                      // ini untuk visualisasi audio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: _audioLevels.map((level) {
                            return Container(
                              width: 4,
                              height: (level * 80).clamp(5, 80),
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // timer ketika recording
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
                    ],
                  ),
                ),
              ),

              const Spacer(), 

              // Recording 
              Column(
                children: [
                  if (_isRecording) 
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        fontSize: 30,
                        color: Color(0xFF001F3F),
                        fontFamily: 'FredokaOne',
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else if (_hasRecording)
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        fontSize: 30,
                        color: Color(0xFF001F3F),
                        fontFamily: 'FredokaOne',
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else 
                    const Text(
                      'Tap to record', 
                      style: TextStyle(
                        fontSize: 30,
                        color: Color(0xFF001F3F),
                        fontFamily: 'FredokaOne',
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Voice record button
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRecording ? _pulseAnimation.value : 1.0,
                          child: Image.asset(
                            'assets/images/voice_record_button.png',
                            width: 68.44,
                            height: 64,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 50), 

                  // discard and analyze buttons
                  if (_hasRecording)
                    Column(
                      children: [
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
                        const SizedBox(height: 20), 
                      ],
                    )
                  else
                    const SizedBox(height: 122), 
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}