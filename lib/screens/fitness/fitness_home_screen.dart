// lib/screens/fitness/fitness_home_screen.dart
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'processing_screen.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PlatformFile? selectedVideoFile;
  String? videoName;
  String? videoSource;

  Future<void> uploadVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      
      if (result != null) {
        setState(() {
          selectedVideoFile = result.files.single;
          videoName = result.files.single.name;
          videoSource = 'upload';
        });
        
        if (mounted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Video uploaded: ${result.files.single.name}', style: const TextStyle(color: Colors.black)),
                  ),
                ],
              ),
              backgroundColor: Colors.cyanAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        navigateToProcessing();
      }
    } catch (e) {
      _showError('Failed to upload video: ${e.toString()}');
    }
  }

  Future<void> recordLiveVideo() async {
    if (kIsWeb) {
      _showError('Camera recording not supported on web. Please use mobile app.');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        setState(() {
          videoName = video.name;
          videoSource = 'camera';
          selectedVideoFile = PlatformFile(
            name: video.name,
            size: 0,
            path: video.path,
          );
        });
        
        if (mounted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                   Icon(Icons.check_circle, color: Colors.black),
                   SizedBox(width: 8),
                  Expanded(
                    child: Text('Video recorded successfully!', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
              backgroundColor: Colors.cyanAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        navigateToProcessing();
      }
    } catch (e) {
       _showError('Failed to record video: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
  }

  void navigateToProcessing() {
    if (selectedVideoFile == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          videoFile: selectedVideoFile!,
          videoName: videoName ?? 'workout.mp4',
          videoSource: videoSource ?? 'upload',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI FITNESS TRAINER',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.cyanAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
           // 1. Base Dark Background with Gradients
          Container(
             decoration: const BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
                 colors: [Color(0xFF050505), Color(0xFF101015)],
               ),
             ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
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
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
      
                  // Hero Section
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.1),
                          Colors.purpleAccent.withValues(alpha: 0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
                            ]
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 60,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'AI FORM ANALYSIS',
                          style: GoogleFonts.orbitron(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Real-time pose detection & correction',
                          style: GoogleFonts.exo2(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
      
                  const SizedBox(height: 40),
      
                  // Instructions
                  Text(
                    'SELECT INPUT METHOD',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
      
                  const SizedBox(height: 28),
      
                  // Option 1: Upload Video
                  _buildOptionCard(
                    icon: Icons.upload_file,
                    title: 'UPLOAD VIDEO',
                    description: 'Analyze pre-recorded workout',
                    color: Colors.cyanAccent,
                    onTap: uploadVideo,
                  ),
      
                  const SizedBox(height: 20),
      
                  // OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1)),
                    ],
                  ),
      
                  const SizedBox(height: 20),
      
                  // Option 2: Record Live
                  _buildOptionCard(
                    icon: Icons.videocam,
                    title: 'RECORD LIVE',
                    description: 'Real-time camera analysis',
                    color: Colors.purpleAccent,
                    onTap: recordLiveVideo,
                  ),
      
                  const SizedBox(height: 36),
      
                  // Features Info
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, color: Colors.cyanAccent, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'CAPABILITIES',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildFeatureItem(Icons.sports_gymnastics, 'Exercise Identification', Colors.cyanAccent),
                            _buildFeatureItem(Icons.check_circle, 'Form Correction', Colors.purpleAccent),
                            _buildFeatureItem(Icons.repeat, 'Rep Counting', Colors.blueAccent),
                            _buildFeatureItem(Icons.whatshot, 'Heatmap Visualization', Colors.orangeAccent),
                          ],
                        ),
                      ),
                    ),
                  ),
      
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ABOUT SYSTEM', style: GoogleFonts.orbitron(color: Colors.white)),
        content: Text(
          'Upload or record your workout video and get AI-powered analysis including:\n\n'
          '• Exercise identification\n'
          '• Form correction\n'
          '• Rep counting\n'
          '• Heatmap visualization\n'
          '• Personalized recommendations',
          style: GoogleFonts.exo2(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ACKNOWLEDGE', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: GoogleFonts.exo2(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.exo2(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}