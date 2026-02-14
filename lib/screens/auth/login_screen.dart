import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/screens/auth/register_screen.dart';
import 'package:flutter_application_1/screens/home_screen_common.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  final _googleSignIn = GoogleSignIn(
    serverClientId: '292610894914-vq7nvud4mohs8bvpc33d3s6f7vmsvo1o.apps.googleusercontent.com',
  );

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled
        setState(() => _loading = false);
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
         throw "Could not retrieve Google ID Token";
      }
      
      // Backend Verification
      final error = await AuthService.googleLoginBackend(idToken);
      
      if (error == null) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const HomeScreenCommon())
          );
      } else {
        throw error;
      }
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Failed: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _login() async {
    setState(() => _loading = true);
    try {
      final error = await AuthService.login(_emailCtrl.text, _passCtrl.text);
      if (error == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreenCommon()),
        );
      } else {
        if (!mounted) return;
        
        // Smart Error Handling for Connection Issues
        if (error.contains("Connection") || error.contains("SocketException")) {
           showDialog(
             context: context,
             builder: (_) => AlertDialog(
               backgroundColor: const Color(0xFF1E1E1E),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               titleTextStyle: GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
               contentTextStyle: GoogleFonts.exo2(color: Colors.white70),
               title: const Text("Connection Error"),
               content: Text(error),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(context), 
                   child: const Text("OK", style: TextStyle(color: Colors.cyanAccent))
                 ),
                 TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Slight delay to allow dialog to close
                      Future.delayed(const Duration(milliseconds: 200), _showSettingsDialog);
                    },
                    child: const Text("Open Settings", style: TextStyle(color: Colors.purpleAccent)),
                 ),
               ],
             )
           );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  void _showSettingsDialog() {
    final controller = TextEditingController(text: AuthService.baseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Server Settings", style: GoogleFonts.orbitron(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enter API Base URL:", style: GoogleFonts.exo2(fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "e.g. http://10.0.2.2:8000",
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.cyanAccent)),
                ),
              ),
              const SizedBox(height: 16),
              Text("Presets:", style: GoogleFonts.exo2(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip("Web", "http://127.0.0.1:8000", controller),
                  _buildPresetChip("Emulator", "http://10.0.2.2:8000", controller),
                  _buildPresetChip("Physical", "http://172.20.10.2:8000", controller),
                  _buildPresetChip("Localhost", "http://localhost:8000", controller),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.setBaseUrl(controller.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("URL Updated to ${AuthService.baseUrl}"), backgroundColor: Colors.cyan),
              );
              setState(() {}); // Refresh UI
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2)),
            child: const Text("Save", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String url, TextEditingController ctrl) {
    return ActionChip(
      backgroundColor: Colors.white10,
      labelStyle: const TextStyle(color: Colors.white),
      label: Text(label),
      onPressed: () => ctrl.text = url,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Dynamic Background
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
              opacity: 0.3,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          
          // 2. Main Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Icon
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(seconds: 2),
                            builder: (context, val, child) {
                              return Transform.scale(
                                scale: val,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.cyanAccent.withValues(alpha: 0.05 + (0.1 * val)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2 * val), blurRadius: 50 * val, spreadRadius: 5)
                                    ],
                                  ),
                                  child: const Icon(Icons.water_drop, size: 50, color: Colors.cyanAccent),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          
                          Text(
                            "ACCESS TERMINAL",
                            style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Secure Health Monitoring System",
                            style: GoogleFonts.exo2(fontSize: 12, color: Colors.white38),
                          ),
                          const SizedBox(height: 12),
                          
                          // Server Indicator (Clickable)
                          InkWell(
                            onTap: _showSettingsDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.dns, size: 12, color: AuthService.baseUrl.contains("localhost") ? Colors.orangeAccent : Colors.cyanAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    AuthService.baseUrl.replaceAll("http://", ""),
                                    style: GoogleFonts.exo2(fontSize: 11, color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Input Fields
                          _buildTextField(_emailCtrl, "Email Protocol", Icons.email_outlined, false),
                          const SizedBox(height: 16),
                          _buildTextField(_passCtrl, "Security Key", Icons.lock_outline, true),
                          const SizedBox(height: 32),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                                boxShadow: [
                                  BoxShadow(color: Colors.cyan.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 4))
                                ]
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text("INITIATE LOGIN", style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.5)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Google Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _googleLogin,
                              icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                              label: Text("SIGN IN WITH GOOGLE", style: GoogleFonts.orbitron(color: Colors.white, letterSpacing: 1.2)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Footer Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               TextButton.icon(
                                icon: const Icon(Icons.wifi_tethering, size: 16, color: Colors.white38),
                                label: Text("Test Ping", style: GoogleFonts.exo2(color: Colors.white38, fontSize: 12)),
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Pinging Network Node..."), duration: Duration(milliseconds: 500)),
                                  );
                                  final result = await AuthService.testConnection();
                                  if (!mounted) return;
                                  Color color = result.startsWith("SUCCESS") ? Colors.greenAccent : Colors.redAccent;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result),
                                      backgroundColor: color.withValues(alpha: 0.2), 
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    )
                                  );
                                },
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                child: Text("Create ID", style: GoogleFonts.exo2(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        filled: true,
        fillColor: Colors.black26,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
