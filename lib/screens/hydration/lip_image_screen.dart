// lib/screens/hydration/lip_image_screen.dart
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/hydration_results_service.dart';
import 'combined_result_screen.dart';
import 'camera_screen.dart';
import 'lip_trends_screen.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';

class LipImageScreen extends StatefulWidget {
  const LipImageScreen({super.key});

  @override
  State<LipImageScreen> createState() => _LipImageScreenState();
}

class _LipImageScreenState extends State<LipImageScreen> {
  XFile? image; 
  Uint8List? displayBytes; 
  bool loading = false;

  // --------------------------------------------------
  // Pick Image (All Platforms)
  // --------------------------------------------------
  Future<void> pickImage(ImageSource source) async {
    XFile? pickedFile;

    if (source == ImageSource.camera) {
      // 1. Show Instructions first
      final proceed = await _showInstructionsDialog();
      if (proceed != true) return;

      if (!mounted) return;
      // 2. Use Custom Camera Screen
      final result = await Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => const CameraScreen())
      );
      if (!context.mounted) return;
      if (result != null && result is XFile) {
        pickedFile = result;
      } else {
        return; // Cancelled
      }
    } else {
      // Use Gallery Picker with compression for faster analysis
      final picker = ImagePicker();
      pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    }

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    setState(() {
      image = pickedFile;
      displayBytes = bytes;
    });
  }

  // --------------------------------------------------
  // Submit Image (Web + Mobile)
  // --------------------------------------------------
  Future<void> submit() async {
    if (image == null && displayBytes == null) return;

    setState(() => loading = true);

    try {
      // Pre-check: backend reachable and lip model available
      final backendOk = await ApiService.checkHydrationBackend();
      if (!backendOk && mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Backend not reachable at ${ApiService.baseUrl}. Start it first: double-click START_BACKEND.bat or check URL in Settings (gear icon).",
              style: GoogleFonts.exo2(),
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      final result = await ApiService.predictLip(
        imageFile: image, // Now XFile
        webImage: displayBytes,
      );

      if (!mounted) return;

      // Extract Backend Data
      final String prediction = result['prediction'] ?? "Unknown";
      final String recommendation = result['recommendation'] ?? "No advice available.";
      final double confidence = (result['confidence'] ?? 0.0) * 100;
      final int score = result['hydration_score'] ?? 0;

      // Map to CombinedResultScreen format
      final uiResult = {
        "prediction": prediction,
        "hydration_risk_level": prediction == "Dehydrate" ? "Dehydrated" : "Normal",
        "hydration_score": score, 
        "xai_url": result['xai_url'],
        "xai_description": result['xai_description'],
        "recommendations": [
          recommendation,
          "AI Confidence: ${confidence.toStringAsFixed(1)}%",
          if (prediction == "Dehydrate") "Consider drinking water immediately."
        ],
        "personalized_suggestions": result['personalized_suggestions'] ?? [], // NEW: Database-driven suggestions
      };

      // SAVE TO SERVICE
      final service = HydrationResultsService();
      service.saveLipResult(uiResult);
      if (service.userName == "User") await service.fetchUserName();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CombinedResultScreen(
            lipResult: service.lipResult,
            formResult: service.formResult,
            userName: service.userName,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Analysis failed: $e", style: GoogleFonts.exo2()),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<bool?> _showInstructionsDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF15151A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
          title: Text(
            "CAPTURE GUIDE",
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _instructionItem(Icons.wb_sunny_outlined, "Use flash/brightness slider in low light"),
              _instructionItem(Icons.face_retouching_natural, "Keep lips relaxed (no pout/smile)"),
              _instructionItem(Icons.no_photography_outlined, "Remove lipstick or heavy balm"),
              _instructionItem(Icons.touch_app, "Tap screen to focus on your lips"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("I'M READY", style: GoogleFonts.orbitron(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: GoogleFonts.exo2(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final hasImage = displayBytes != null;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "LIP ANALYSIS",
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LipTrendsScreen()),
              );
            },
            tooltip: "View Trends",
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
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!hasImage) ...[
                    _buildPrepGuide(),
                  ] else ...[
                    // Instructions / Header
                    ClipRRect(
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
                              const Icon(Icons.face_retouching_natural, size: 48, color: Colors.cyanAccent),
                              const SizedBox(height: 16),
                              Text(
                                'AI VISUAL ASSESSMENT',
                                style: GoogleFonts.orbitron(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload a clear photo of your lips for instant hydration analysis.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.exo2(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.4
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
            
                  const SizedBox(height: 24),
            
                  // Image Preview Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: hasImage
                          ? _buildImagePreview()
                          : _buildPlaceholder(),
                    ),
                  ),
            
                  const SizedBox(height: 24),
            
                  // Instructions Card
                  if (!hasImage) _buildInstructionsCard(),
            
                  const SizedBox(height: 24),
            
                  // Action Buttons
                  if (!hasImage) _buildImageSourceButtons(),
            
                  // Analyze Button (shown when image is selected)
                  if (hasImage) ...[
                    _buildAnalyzeButton(),
                    const SizedBox(height: 16),
                    _buildRetakeButton(),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // UI Components
  // --------------------------------------------------

  Widget _buildImagePreview() {
    return Stack(
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: Image.memory(displayBytes!, fit: BoxFit.cover),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'IMAGE READY',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return SizedBox(
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'NO IMAGE SELECTED',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
              letterSpacing: 1
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'TIPS FOR BEST RESULTS',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                      letterSpacing: 1
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTipItem('Ensure good lighting (avoid shadows)'),
              _buildTipItem('Keep face/lips centered'),
              _buildTipItem('Maintain a neutral expression'),
              _buildTipItem('Remove heavy makeup if possible'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check, size: 14, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.exo2(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButtons() {
    return Column(
      children: [
        _buildScanButton(
          label: "TAKE PHOTO",
          icon: Icons.camera_alt,
          color: Colors.cyanAccent,
          onTap: () => pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 16),
        _buildScanButton(
          label: "UPLOAD FROM GALLERY",
          icon: Icons.photo_library,
          color: Colors.purpleAccent,
          onTap: () => pickImage(ImageSource.gallery),
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildScanButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isOutlined ? [] : [
           BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 1)
        ]
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: isOutlined ? color : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isOutlined ? BorderSide(color: color.withValues(alpha: 0.5), width: 1) : BorderSide.none
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(icon, size: 20),
             const SizedBox(width: 12),
             Text(
               label, 
               style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 1)
        ]
      ),
      child: ElevatedButton(
        onPressed: loading ? null : submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.analytics_outlined, size: 24),
                   const SizedBox(width: 12),
                   Text(
                    'START ANALYSIS',
                    style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRetakeButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton.icon(
        onPressed: loading ? null : () {
          setState(() {
            image = null;
            displayBytes = null;
          });
        },
        icon: const Icon(Icons.refresh, size: 20, color: Colors.white54),
        label: Text(
          'SELECT DIFFERENT IMAGE',
          style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildPrepGuide() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.cyanAccent.withValues(alpha: 0.1), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tips_and_updates_outlined, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                "FOR BEST RESULTS",
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _stepTip("1", "Find a well-lit area with bright natural light"),
          const SizedBox(height: 12),
          _stepTip("2", "Wipe lips clean (no food, lipstick, or balm)"),
          const SizedBox(height: 12),
          _stepTip("3", "Maintain a relaxed, natural lip expression"),
          const SizedBox(height: 12),
          _stepTip("4", "Steady your hand and align within the ring"),
        ],
      ),
    );
  }

  Widget _stepTip(String step, String tip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.2)),
            child: Center(child: Text(step, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(tip, style: GoogleFonts.exo2(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }
}
