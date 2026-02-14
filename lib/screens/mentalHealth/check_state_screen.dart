// lib/screens/mentalHealth/check_state_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'video/video_upload_screen.dart';
import 'audio/audio_upload_screen.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';
import 'package:flutter_application_1/services/api_service.dart';

class CheckStateScreen extends StatefulWidget {
  final bool isVideoFlow;

  const CheckStateScreen({super.key, required this.isVideoFlow});

  @override
  State<CheckStateScreen> createState() => _CheckStateScreenState();
}

class _CheckStateScreenState extends State<CheckStateScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Backend data
  String? _lastEmotion;
  bool _hasPrevious = false;
  List<dynamic> _recommendations = [];
  bool _isLoading = true;

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

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    _loadLastEmotion();
  }

  Future<void> _loadLastEmotion() async {
    try {
      final source = widget.isVideoFlow ? "video" : "audio";
      final data = await ApiService.getLastEmotion(source: source);
      if (mounted) {
        setState(() {
          _hasPrevious = data['has_previous'] ?? false;
          _lastEmotion = data['emotion'];
          _recommendations = data['recommendations'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasPrevious = false;
        });
      }
    }
  }

  IconData _getEmotionIcon(String? emotion) {
    switch ((emotion ?? '').toLowerCase()) {
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
        return Icons.sentiment_satisfied;
    }
  }

  Color _getEmotionColor(String? emotion) {
    switch ((emotion ?? '').toLowerCase()) {
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
        return Colors.greenAccent;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isVideoFlow ? Colors.cyanAccent : Colors.purpleAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
           // Dynamic Background
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
            top: 100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.emoji_emotions_outlined,
                                size: 64,
                                color: accentColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Title
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        'EMOTIONAL\nCHECK-IN',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          height: 1.2
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Question Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.help_outline, color: accentColor, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'PREVIOUS STATE',
                                      style: GoogleFonts.orbitron(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                        letterSpacing: 1
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _hasPrevious
                                      ? 'Are you still experiencing the previously detected emotional state?'
                                      : 'No previous emotional state detected.\nStart a new analysis to begin tracking.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.exo2(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Previous State Display
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _isLoading
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accentColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Loading previous state...',
                                    style: GoogleFonts.exo2(fontSize: 14, color: Colors.white54),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _hasPrevious
                                      ? _getEmotionColor(_lastEmotion).withValues(alpha: 0.3)
                                      : accentColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (_hasPrevious
                                              ? _getEmotionColor(_lastEmotion)
                                              : Colors.white38)
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _hasPrevious
                                          ? _getEmotionIcon(_lastEmotion)
                                          : Icons.help_outline,
                                      color: _hasPrevious
                                          ? _getEmotionColor(_lastEmotion)
                                          : Colors.white38,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'LAST DETECTED',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 10,
                                          color: Colors.white54,
                                          letterSpacing: 1
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _hasPrevious
                                            ? (_lastEmotion ?? 'Unknown').toUpperCase()
                                            : 'NO DATA YET',
                                        style: GoogleFonts.exo2(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              title: 'NEW ANALYSIS',
                              icon: Icons.refresh,
                              color: accentColor,
                              isPrimary: true,
                              onTap: () {
                                if (widget.isVideoFlow) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VideoUploadScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AudioUploadScreen(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              title: 'CONTINUE',
                              icon: Icons.arrow_forward,
                              color: Colors.greenAccent,
                              isPrimary: false,
                              onTap: () {
                                _showRecommendationsBottomSheet(context, accentColor);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary 
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 1)]
            : [],
        border: isPrimary ? null : Border.all(color: Colors.white.withValues(alpha: 0.2))
      ),
      child: Material(
        color: isPrimary ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.black : Colors.white,
                    letterSpacing: 1
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecommendationsBottomSheet(
    BuildContext context,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecommendationsSheet(
        accentColor: accentColor,
        lastEmotion: _lastEmotion,
        recommendations: _recommendations,
      ),
    );
  }
}

// ============================================
// RECOMMENDATIONS BOTTOM SHEET
// ============================================
class _RecommendationsSheet extends StatefulWidget {
  final Color accentColor;
  final String? lastEmotion;
  final List<dynamic> recommendations;

  const _RecommendationsSheet({
    required this.accentColor,
    this.lastEmotion,
    this.recommendations = const [],
  });

  @override
  State<_RecommendationsSheet> createState() => _RecommendationsSheetState();
}

class _RecommendationsSheetState extends State<_RecommendationsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getEmotionColor(String? emotion) {
    switch ((emotion ?? '').toLowerCase()) {
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
        return Colors.greenAccent;
    }
  }

  IconData _getEmotionIcon(String? emotion) {
    switch ((emotion ?? '').toLowerCase()) {
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
        return Icons.sentiment_satisfied;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emotionColor = _getEmotionColor(widget.lastEmotion);
    final emotionIcon = _getEmotionIcon(widget.lastEmotion);
    final emotionLabel = (widget.lastEmotion ?? 'Unknown').toUpperCase();

    // Build recommendation items from API data or use defaults
    final List<Map<String, dynamic>> recItems = widget.recommendations.isNotEmpty
        ? widget.recommendations.asMap().entries.map((entry) {
            final icons = [Icons.self_improvement, Icons.music_note, Icons.directions_walk, Icons.water_drop, Icons.favorite, Icons.local_cafe];
            final colors = [Colors.purpleAccent, Colors.pinkAccent, Colors.cyanAccent, Colors.blueAccent, Colors.redAccent, Colors.orangeAccent];
            return {
              'icon': icons[entry.key % icons.length],
              'title': 'SUGGESTION ${entry.key + 1}',
              'description': entry.value.toString(),
              'color': colors[entry.key % colors.length],
            };
          }).toList()
        : [
            {'icon': Icons.self_improvement, 'title': 'MINDFULNESS', 'description': 'Take 5 minutes for meditation', 'color': Colors.purpleAccent},
            {'icon': Icons.music_note, 'title': 'MUSIC THERAPY', 'description': 'Calming playlist recommended', 'color': Colors.pinkAccent},
            {'icon': Icons.directions_walk, 'title': 'ACTIVE BREAK', 'description': '10-minute outdoor walk', 'color': Colors.cyanAccent},
            {'icon': Icons.water_drop, 'title': 'HYDRATION', 'description': 'Drink a glass of water', 'color': Colors.blueAccent},
          ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101015).withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.lightbulb, color: widget.accentColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECOMMENDATIONS',
                                style: GoogleFonts.orbitron(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Based on your emotional state',
                                style: GoogleFonts.exo2(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Current State Display
                    FadeTransition(
                      opacity: _animation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: emotionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: emotionColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(emotionIcon, color: emotionColor, size: 32),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT STATUS',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    letterSpacing: 1
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  emotionLabel,
                                  style: GoogleFonts.exo2(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recommendations List
                    ...recItems.asMap().entries.map(
                          (entry) => _buildRecommendationCard(entry.value, entry.key),
                        ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              "NEW ANALYSIS",
                              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.accentColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0
                            ),
                            child: Text(
                              "COMPLETE",
                              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: rec['color'].withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rec['icon'], color: rec['color'], size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['title'],
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec['description'],
                          style: GoogleFonts.exo2(
                            fontSize: 13,
                            color: Colors.white60,
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
    );
  }
}