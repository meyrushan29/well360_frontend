// lib/screens/fitness/processing_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'result_screen.dart';
import 'package:flutter_application_1/services/api_service.dart';

class ProcessingScreen extends StatefulWidget {
  final PlatformFile videoFile;
  final String videoName;
  final String videoSource;
  
  const ProcessingScreen({
    super.key,
    required this.videoFile,
    required this.videoName,
    required this.videoSource,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  
  int currentStep = 0;
  final List<String> steps = [
    'Initializing Neural Networks...',
    'Detecting Pose Keypoints...',
    'Analyzing Biomechanics...',
    'Calculating Repetitions...',
    'Generating Insights...',
  ];

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  Future<void> _startProcessing() async {
    _progressController.forward();
    
    // Visual progress (non-blocking) - cycles through steps
    _animateSteps();

    try {
      Map<String, dynamic> result;

      if (kIsWeb) {
         if (widget.videoFile.bytes == null) {
            throw Exception("Video bytes missing for web upload");
         }
         result = await ApiService.predictFitnessVideo(
            widget.videoName, 
            webBytes: widget.videoFile.bytes
         );
      } else {
        if (widget.videoFile.path == null) {
          throw Exception("Video path is missing. Cannot upload.");
        }
        result = await ApiService.predictFitnessVideo(widget.videoFile.path!);
      }

      if (!mounted) return;
      
      // Navigate to Result
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ResultScreen(
                videoFile: widget.videoFile,
                videoName: widget.videoName,
                videoSource: widget.videoSource,
                analysisResult: result,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString().replaceAll("Exception:", "").trim();
      bool isHumanError = errorMessage.contains("No human detected") || errorMessage.contains("visible for accurate analysis");

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isHumanError ? Colors.orangeAccent : Colors.redAccent)
          ),
          title: Row(
            children: [
              Icon(isHumanError ? Icons.accessibility_new_rounded : Icons.error_outline, 
                   color: isHumanError ? Colors.orangeAccent : Colors.redAccent),
              const SizedBox(width: 10),
              Text(isHumanError ? "Validation Failed" : "Processing Error", 
                   style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            isHumanError 
                ? "We couldn't detect a person in the video.\n\nPlease ensure your full body is visible and the lighting is good for the AI to analyze your form."
                : "An error occurred during analysis:\n\n$errorMessage",
            style: GoogleFonts.exo2(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to Home
              },
              child: const Text("Try Again", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  void _animateSteps() async {
    for (int i = 0; i < steps.length; i++) {
      if (!mounted) return;
      setState(() {
        currentStep = i;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
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
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(50),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent.withValues(alpha: 0.05),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 2),
                                  gradient: RadialGradient(
                                     colors: [Colors.cyanAccent.withValues(alpha: 0.2), Colors.transparent]
                                  )
                                ),
                                child: const Icon(
                                  Icons.psychology,
                                  size: 80,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                          ),
      
                          const SizedBox(height: 50),
      
                          Text(
                            'AI ANALYSIS IN PROGRESS',
                            style: GoogleFonts.orbitron(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
      
                          const SizedBox(height: 16),
      
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.videoSource == 'camera' 
                                      ? Icons.videocam 
                                      : Icons.upload_file,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    widget.videoName,
                                    style: GoogleFonts.exo2(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
      
                          const SizedBox(height: 60),
      
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        height: 6,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: _progressAnimation.value,
                                        child: Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Colors.cyanAccent, Colors.purpleAccent],
                                            ),
                                            borderRadius: BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.cyanAccent.withValues(alpha: 0.5),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '${(_progressAnimation.value * 100).toInt()}%',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
      
                          const SizedBox(height: 50),
      
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: List.generate(
                                steps.length,
                                (index) => _buildStepItem(
                                  steps[index],
                                  index,
                                  currentStep >= index,
                                ),
                              ),
                            ),
                          ),
      
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String text, int index, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: isActive ? [
                BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 10)
              ] : [],
            ),
            child: Center(
              child: isActive
                  ? const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    )
                  : null
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.exo2(
                fontSize: 16,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(text),
            ),
          ),
          if (currentStep == index)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}