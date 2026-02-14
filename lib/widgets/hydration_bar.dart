// lib/widgets/hydration_bar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HydrationBar extends StatelessWidget {
  final int score;

  const HydrationBar({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final hydrationData = _getHydrationData(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hydrationData.color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hydrationData.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hydrationData.icon,
                      color: hydrationData.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HYDRATION LEVEL',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hydrationData.label,
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
              // Score Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: hydrationData.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hydrationData.color.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: hydrationData.color.withValues(alpha: 0.2),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Text(
                  '$score',
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: hydrationData.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Bar with Scale
          Column(
            children: [
              // Scale Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildScaleLabel('0', Colors.redAccent),
                  _buildScaleLabel('40', Colors.orangeAccent),
                  _buildScaleLabel('70', Colors.cyanAccent),
                  _buildScaleLabel('100', Colors.greenAccent),
                ],
              ),
              const SizedBox(height: 8),

              // Animated Progress Bar
              Stack(
                children: [
                  // Background bar
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white10,
                    ),
                  ),
                  // Foreground bar (filled portion)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth * (score / 100),
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              hydrationData.color.withValues(alpha: 0.4),
                              hydrationData.color,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: hydrationData.color.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: hydrationData.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hydrationData.description,
                    style: GoogleFonts.exo2(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleLabel(String text, Color color) {
    return Column(
      children: [
        Container(
          width: 2,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.exo2(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  _HydrationData _getHydrationData(int score) {
    if (score < 40) {
      return _HydrationData(
        color: Colors.redAccent,
        label: 'DEHYDRATED',
        icon: Icons.warning_amber_rounded,
        description: 'Hydration level critical. Initiate rehydration immediately.',
      );
    } else if (score < 70) {
      return _HydrationData(
        color: Colors.orangeAccent,
        label: 'MODERATE',
        icon: Icons.water_drop_outlined,
        description: 'Hydration levels acceptable. Recommend additional fluid intake.',
      );
    } else {
      return _HydrationData(
        color: Colors.greenAccent,
        label: 'OPTIMAL',
        icon: Icons.check_circle_outline,
        description: 'Hydration levels optimal. Maintain current fluid intake regimen.',
      );
    }
  }
}

class _HydrationData {
  final Color color;
  final String label;
  final IconData icon;
  final String description;

  _HydrationData({
    required this.color,
    required this.label,
    required this.icon,
    required this.description,
  });
}
