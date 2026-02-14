import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInit = false;
  String? _error;
  CameraDescription? _selectedCamera;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Quality Enhancement Settings
  double _currentExposure = 0.0;
  double _minExposure = 0.0;
  double _maxExposure = 0.0;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = "No cameras found");
        return;
      }

      // Default to Front
      final initialCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      await _startCamera(initialCamera);
      
      if (!mounted) return;
      setState(() => _isInit = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Camera Error: $e");
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    
    _selectedCamera = camera;

    _controller = CameraController(
      camera, 
      ResolutionPreset.veryHigh, // Changed from max for better quality/performance balance
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      
      // Get exposure range
      _minExposure = await _controller!.getMinExposureOffset();
      _maxExposure = await _controller!.getMaxExposureOffset();
      
      try {
        await _controller!.setFocusMode(FocusMode.auto);
        await _controller!.setExposureMode(ExposureMode.auto);
        
        // For front camera in low light, boost exposure slightly
        if (camera.lensDirection == CameraLensDirection.front) {
          final boostValue = (_maxExposure * 0.3).clamp(_minExposure, _maxExposure);
          await _controller!.setExposureOffset(boostValue);
          _currentExposure = boostValue;
        }
      } catch (_) {}
      
      if (mounted) setState(() {});
    } catch (e) {
      print("Camera Start Error: $e");
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;
    
    if (_selectedCamera != null) {
       final lensDirection = _selectedCamera!.lensDirection;
       CameraDescription newCamera;
       
       if (lensDirection == CameraLensDirection.front) {
         newCamera = _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => _cameras.first);
       } else {
         newCamera = _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => _cameras.first);
       }
       
       setState(() => _isInit = false); 
       await _startCamera(newCamera);
       setState(() => _isInit = true);
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Enable flash if turned on
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.torch);
        await Future.delayed(const Duration(milliseconds: 100)); // Let flash stabilize
      }
      
      // Capture with highest quality
      final XFile rawFile = await _controller!.takePicture();
      
      // Turn off flash
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      }
      
      await _processCenterCrop(rawFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Capture failed: $e", style: GoogleFonts.exo2())));
    }
  }

  Future<void> _processCenterCrop(XFile rawFile) async {
    final bytes = await rawFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    
    if (originalImage != null) {
      // Fix rotation
      originalImage = img.bakeOrientation(originalImage);
      
      final int w = originalImage.width;
      final int h = originalImage.height;
      
      // Calculate Crop to match the UI Overlay (80% width, 0.45 aspect ratio)
      const double overlayWidthFactor = 0.8; 
      
      final int cropW = (w * overlayWidthFactor).toInt();
      final int cropH = (cropW * 0.45).toInt(); 
      
      final int cropX = (w - cropW) ~/ 2;
      final int cropY = (h - cropH) ~/ 2;
      
      // Perform Crop
      img.Image cropped = img.copyCrop(originalImage, x: cropX, y: cropY, width: cropW, height: cropH);
      
      // QUALITY ENHANCEMENT: Improve brightness and contrast for low-light images
      cropped = _enhanceImageQuality(cropped);
      
      // Encode with high quality (100 = maximum quality)
      final jpg = img.encodeJpg(cropped, quality: 95);
      
      final String newPath = '${rawFile.path}_processed.jpg';
      await File(newPath).writeAsBytes(jpg);
      
      if (!mounted) return;
      Navigator.pop(context, XFile(newPath));
    } else {
      if (!mounted) return;
      Navigator.pop(context, rawFile);
    }
  }
  
  // Enhance image quality for better AI detection
  img.Image _enhanceImageQuality(img.Image image) {
    // Calculate average brightness
    int totalBrightness = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        totalBrightness += ((r + g + b) / 3).round();
        pixelCount++;
      }
    }
    
    final avgBrightness = totalBrightness / pixelCount;
    
    // If image is too dark (low light), enhance it
    if (avgBrightness < 100) {
      // Boost brightness and contrast
      image = img.adjustColor(image, 
        brightness: 1.2,  // Increase brightness by 20%
        contrast: 1.15,   // Increase contrast by 15%
        saturation: 1.1,  // Slight saturation boost
      );
    } else if (avgBrightness < 130) {
      // Moderate enhancement
      image = img.adjustColor(image, 
        brightness: 1.1,
        contrast: 1.1,
      );
    }
    
    // Apply slight sharpening for better edge detection
    image = img.convolution(image, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0
    ]);
    
    return image;
  }

  void _onTapFocus(TapUpDetails details, BoxConstraints constraints) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    
    try {
      _controller!.setFocusPoint(offset);
      _controller!.setExposurePoint(offset);
    } catch (_) {}
  }
  
  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    setState(() => _isFlashOn = !_isFlashOn);
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFlashOn ? "Flash enabled for next capture" : "Flash disabled",
          style: GoogleFonts.exo2(),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: _isFlashOn ? Colors.amber.withOpacity(0.8) : Colors.grey.withOpacity(0.8),
      ),
    );
  }
  
  void _adjustExposure(double value) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      await _controller!.setExposureOffset(value);
      setState(() => _currentExposure = value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text("CAMERA ERROR", style: GoogleFonts.orbitron()), backgroundColor: Colors.transparent),
        body: Center(child: Text(_error!, style: GoogleFonts.exo2(color: Colors.redAccent))),
      );
    }

    if (!_isInit || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final overlayWidth = screenWidth * 0.8;
    final overlayHeight = overlayWidth * 0.45;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Camera Feed with Tap to Focus
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) => _onTapFocus(details, constraints),
                behavior: HitTestBehavior.opaque,
                child: SizedBox.expand(
                  child: Center(
                    child: CameraPreview(_controller!),
                  ),
                ),
              );
            }
          ),
          
          // 2. Simple Static Overlay (Guide)
          Positioned.fill(
             child: IgnorePointer(
               child: Stack(
                 children: [
                   // Dark Mask
                   ColorFiltered(
                     colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut),
                     child: Stack(
                       children: [
                         Container(
                           decoration: const BoxDecoration(
                             color: Colors.black,
                             backgroundBlendMode: BlendMode.dstOut,
                           ), 
                         ),
                         // The "Hole"
                         Center(
                           child: Container(
                             width: overlayWidth,
                             height: overlayHeight,
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(overlayHeight / 2),
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                   // Simple Border with Pulse
                   Center(
                     child: ScaleTransition(
                       scale: _pulseAnimation,
                       child: Container(
                         width: overlayWidth + 4,
                         height: overlayHeight + 4,
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(overlayHeight),
                           border: Border.all(
                             color: Colors.cyanAccent.withOpacity(0.8), 
                             width: 3,
                           ),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.cyanAccent.withOpacity(0.3),
                               blurRadius: 20,
                               spreadRadius: 2,
                             )
                           ]
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          // 3. UI Controls
          Positioned(
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Close
                FloatingActionButton(
                  heroTag: "cancel",
                  backgroundColor: Colors.white10,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                const SizedBox(width: 20),
                // Flash Toggle
                FloatingActionButton(
                  heroTag: "flash",
                  backgroundColor: _isFlashOn ? Colors.amber.withOpacity(0.3) : Colors.white10,
                  onPressed: _toggleFlash,
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? Colors.amber : Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                // Capture
                FloatingActionButton.large(
                  heroTag: "capture",
                  backgroundColor: Colors.white,
                  onPressed: _takePicture,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent, width: 2)
                    ),
                    child: const Icon(Icons.camera, color: Colors.black, size: 40),
                  ),
                ),
                const SizedBox(width: 20),
                // Switch Camera
                 FloatingActionButton(
                  heroTag: "switch_cam",
                  backgroundColor: Colors.white10,
                  onPressed: _switchCamera,
                  child: const Icon(Icons.cameraswitch, color: Colors.white),
                ), 
              ],
            ),
          ),
          
          // Exposure Control Slider
          if (_controller != null && _controller!.value.isInitialized)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height * 0.3,
              child: Container(
                height: 200,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.brightness_high, color: Colors.white, size: 20),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _currentExposure,
                          min: _minExposure,
                          max: _maxExposure,
                          activeColor: Colors.cyanAccent,
                          inactiveColor: Colors.white24,
                          onChanged: _adjustExposure,
                        ),
                      ),
                    ),
                    const Icon(Icons.brightness_low, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          
          // 4. Instruction Text
          Positioned(
            top: 60,
            child: Column(
              children: [
                Text(
                  "LIP SCANNER",
                  style: GoogleFonts.orbitron(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    shadows: [const Shadow(blurRadius: 10, color: Colors.cyanAccent)]
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "PLACE LIPS INSIDE THE PULSING RING",
                  style: GoogleFonts.exo2(
                    color: Colors.cyanAccent, 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // 5. Bottom Tips Card
          Positioned(
            bottom: 150,
            child: Container(
              width: screenWidth * 0.85,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildTipRow(Icons.wb_sunny, "Use flash or adjust brightness if too dark"),
                  const SizedBox(height: 10),
                  _buildTipRow(Icons.face_retouching_natural, "Keep a relaxed, neutral expression"),
                  const SizedBox(height: 10),
                  _buildTipRow(Icons.touch_app, "Tap screen to focus on your lips"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.exo2(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
