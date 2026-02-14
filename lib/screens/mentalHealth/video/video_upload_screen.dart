// lib/screens/mentalHealth/video/video_upload_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'stress_graph_screen.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen>
    with TickerProviderStateMixin {
  String? _fileName;
  String? _filePath;
  Uint8List? _fileBytes;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
          _filePath = result.files.single.path;
          _fileBytes = result.files.single.bytes;
          _analysisResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error picking file: $e');
      }
    }
  }

  Future<void> _analyzeVideo() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    _progressController.forward(from: 0.0);

    try {
      final result = await ApiService.predictVideoEmotion(
        _filePath ?? '',
        webBytes: _fileBytes,
        fileName: _fileName,
      );

      if (mounted) {
        _progressController.animateTo(1.0,
            duration: const Duration(milliseconds: 300));
        setState(() {
          _isAnalyzing = false;
          _analysisResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.exo2())),
          ],
        ),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.greenAccent;
      case 'sad':
        return Colors.blueAccent;
      case 'angry':
        return Colors.redAccent;
      case 'fear':
        return Colors.purpleAccent;
      case 'surprise':
        return Colors.orangeAccent;
      case 'disgust':
        return Colors.tealAccent;
      case 'neutral':
      default:
        return Colors.cyanAccent;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.mood_bad;
      case 'fear':
        return Icons.sentiment_neutral;
      case 'surprise':
        return Icons.sentiment_satisfied;
      case 'disgust':
        return Icons.sick_outlined;
      case 'neutral':
      default:
        return Icons.emoji_emotions_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF050505), Color(0xFF101015)],
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          // Ambient Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      blurRadius: 100,
                      spreadRadius: 50),
                ],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.videocam,
                          size: 64,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'VIDEO ANALYSIS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'Upload a video to analyze facial expressions\nand detect emotions over time',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        color: Colors.white60,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Upload Area
                    GestureDetector(
                      onTap: _isAnalyzing ? null : _pickVideoFile,
                      child: AnimatedBuilder(
                        animation: _fileName != null
                            ? _pulseAnimation
                            : const AlwaysStoppedAnimation(1.0),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _fileName != null
                                ? _pulseAnimation.value
                                : 1.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: _fileName != null
                                          ? Colors.greenAccent
                                          : Colors.white.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: (_fileName != null
                                                  ? Colors.greenAccent
                                                  : Colors.cyanAccent)
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: (_fileName != null
                                                        ? Colors.greenAccent
                                                        : Colors.cyanAccent)
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 15)
                                          ],
                                        ),
                                        child: Icon(
                                          _fileName != null
                                              ? Icons.check_circle_outline
                                              : Icons.video_file,
                                          size: 48,
                                          color: _fileName != null
                                              ? Colors.greenAccent
                                              : Colors.cyanAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _fileName ?? 'Tap to select video file',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.orbitron(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _fileName != null
                                              ? Colors.greenAccent
                                              : Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      if (_fileName != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Video ready for analysis',
                                          style: GoogleFonts.exo2(
                                            fontSize: 12,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Supported: MP4, AVI, MOV, MKV',
                                          style: GoogleFonts.exo2(
                                            fontSize: 12,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null && _analysisResult == null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.exo2(
                                    fontSize: 12, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Analyze Button
                    if (_fileName != null && _analysisResult == null) ...[
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.cyanAccent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _isAnalyzing ? null : _analyzeVideo,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: _isAnalyzing
                                  ? Column(
                                      children: [
                                        const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'PROCESSING VIDEO...',
                                          style: GoogleFonts.orbitron(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Scanning frames for emotions',
                                          style: GoogleFonts.exo2(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40),
                                          child: AnimatedBuilder(
                                            animation: _progressAnimation,
                                            builder: (context, child) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child:
                                                    LinearProgressIndicator(
                                                  value:
                                                      _progressAnimation.value,
                                                  minHeight: 4,
                                                  backgroundColor:
                                                      Colors.black12,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                          Color>(Colors.black),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.play_arrow_rounded,
                                            color: Colors.black, size: 24),
                                        const SizedBox(width: 12),
                                        Text(
                                          'ANALYZE VIDEO',
                                          style: GoogleFonts.orbitron(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Analysis Results
                    if (_analysisResult != null) ...[
                      const SizedBox(height: 48),
                      _buildResultsSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RESULTS SECTION
  // ==========================================
  Widget _buildResultsSection() {
    final emotion = _analysisResult!['emotion'] ?? 'Unknown';
    final confidence = (_analysisResult!['confidence'] ?? 0.0) as num;
    final confidenceLabel = _analysisResult!['confidence_label'] ?? 'Unknown';
    final facesDetected = _analysisResult!['faces_detected'] ?? 0;
    final framesAnalyzed = _analysisResult!['frames_analyzed'] ?? 0;
    final durationSec = (_analysisResult!['duration_sec'] ?? 0.0) as num;
    final emotionBreakdown =
        _analysisResult!['emotion_breakdown'] as Map<String, dynamic>? ?? {};
    final recommendations =
        _analysisResult!['recommendations'] as List<dynamic>? ?? [];
    final emotionColor = _getEmotionColor(emotion);
    final emotionIcon = _getEmotionIcon(emotion);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Banner
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 40, color: Colors.greenAccent),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ANALYSIS COMPLETE',
                              style: GoogleFonts.orbitron(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$framesAnalyzed frames analyzed • ${durationSec.toStringAsFixed(1)}s video',
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Dominant Emotion Card
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: emotionColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: emotionColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          // Large Emotion Icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: emotionColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        emotionColor.withValues(alpha: 0.3),
                                    blurRadius: 20)
                              ],
                            ),
                            child:
                                Icon(emotionIcon, color: emotionColor, size: 48),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'DOMINANT EMOTION',
                            style: GoogleFonts.orbitron(
                              fontSize: 10,
                              color: Colors.white54,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            emotion.toUpperCase(),
                            style: GoogleFonts.orbitron(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confidence bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Confidence',
                                      style: GoogleFonts.exo2(
                                          fontSize: 13, color: Colors.white70),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${(confidence * 100).toStringAsFixed(0)}%',
                                          style: GoogleFonts.orbitron(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: emotionColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: emotionColor
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            confidenceLabel,
                                            style: GoogleFonts.exo2(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: emotionColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: confidence.toDouble(),
                                    minHeight: 6,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        emotionColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Stats Row
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      Icons.face,
                      '$facesDetected',
                      'Faces Found',
                      Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatChip(
                      Icons.movie_filter,
                      '$framesAnalyzed',
                      'Frames Scanned',
                      Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatChip(
                      Icons.timer,
                      '${durationSec.toStringAsFixed(1)}s',
                      'Duration',
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Emotion Breakdown
        if (emotionBreakdown.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildEmotionBreakdown(emotionBreakdown),
        ],

        // Recommendations
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildRecommendations(recommendations),
        ],

        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _fileName = null;
                    _filePath = null;
                    _fileBytes = null;
                    _analysisResult = null;
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  "NEW VIDEO",
                  style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StressGraphScreen()),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: Text(
                  "STRESS",
                  style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home, size: 18),
            label: Text(
              "HOME",
              style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.exo2(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionBreakdown(Map<String, dynamic> breakdown) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.cyanAccent, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'EMOTION BREAKDOWN',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...breakdown.entries.map((entry) {
                  final emo = entry.key;
                  final data = entry.value as Map<String, dynamic>;
                  final pct = (data['percentage'] as num).toDouble();
                  final count = data['count'] as int;
                  final color = _getEmotionColor(emo);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_getEmotionIcon(emo),
                                    color: color, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  emo.toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}% ($count)',
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendations(List<dynamic> recommendations) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'RECOMMENDATIONS',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...recommendations.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: GoogleFonts.orbitron(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: GoogleFonts.exo2(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
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
      },
    );
  }
}
