import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fitness/fitness_home_screen.dart';
import 'hydration/hydration_home_screen.dart';
import 'mentalHealth/home_screen.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';
import 'package:flutter_application_1/screens/profile/profile_screen.dart';

class HomeScreenCommon extends StatelessWidget {
  const HomeScreenCommon({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark Futuristic Background
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_rounded, color: Colors.cyanAccent),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Base Dark Background with Gradients
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF050505),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          // 2. Ambient Glow Orbs (Soft Gradients)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          
          // 3. Main Content - Glassmorphism
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Header Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.cyanAccent, Colors.purpleAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 20),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.black,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icon/well360_logo.png',
                                    fit: BoxFit.cover,
                                    width: 90,
                                    height: 90,
                                    errorBuilder: (c, o, s) => const Icon(Icons.person, size: 50, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "WELL360",
                          style: GoogleFonts.orbitron(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.cyanAccent.withValues(alpha: 0.8), blurRadius: 15),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "NEXT-GEN HEALTH ANALYZER",
                          style: GoogleFonts.exo2(
                            fontSize: 14,
                            letterSpacing: 3,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Module Cards
                  _buildFuturisticCard(
                    context,
                    title: "HYDRATION",
                    subtitle: "Fluid Intake Analysis",
                    icon: Icons.water_drop_outlined,
                    color: Colors.cyanAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HydrationHomeScreen())),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildFuturisticCard(
                    context,
                    title: "FITNESS AI",
                    subtitle: "Pose Detection & Form Analysis",
                    icon: Icons.fitness_center_outlined,
                    color: const Color(0xFFC6FF00), // Lime Neon
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                  ),
                  const SizedBox(height: 20),

                  _buildFuturisticCard(
                    context,
                    title: "MENTAL SYNC",
                    subtitle: "Wellness & Mood Tracking",
                    icon: Icons.psychology_outlined,
                    color: Colors.purpleAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage())),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 0,
                )
              ],
            ),
            child: Stack(
              children: [
                // Decorative Line
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 6,
                  child: Container(color: color),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 20),
                  child: Row(
                    children: [
                      // Icon with Glow
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15),
                          ],
                        ),
                        child: Icon(icon, color: color, size: 32),
                      ),
                      const SizedBox(width: 20),
                      // Text
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.orbitron(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.exo2(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.5), size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

