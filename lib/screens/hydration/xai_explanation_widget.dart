// lib/screens/hydration/xai_explanation_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class XaiExplanationWidget extends StatefulWidget {
  final String heatmapUrl;
  final String? description;

  const XaiExplanationWidget({
    super.key,
    required this.heatmapUrl,
    this.description,
  });

  @override
  State<XaiExplanationWidget> createState() => _XaiExplanationWidgetState();
}

class _XaiExplanationWidgetState extends State<XaiExplanationWidget> {
  bool _showGuide = false;

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = "${AuthService.baseUrl}${widget.heatmapUrl}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "HOW AI SAW YOUR LIPS",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Visual breakdown of the analysis",
                      style: GoogleFonts.exo2(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showGuide ? Icons.expand_less : Icons.help_outline,
                  color: Colors.orangeAccent,
                ),
                onPressed: () => setState(() => _showGuide = !_showGuide),
                tooltip: "How to read this",
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Expandable Guide
          if (_showGuide) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "HOW TO READ THIS",
                        style: GoogleFonts.orbitron(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideStep("1", "The AI looks at your lip photo", Icons.image),
                  _buildGuideStep("2", "It highlights important areas with colors", Icons.palette),
                  _buildGuideStep("3", "Red/Yellow = Areas that influenced the decision", Icons.priority_high),
                  _buildGuideStep("4", "Blue/Green = Less important background areas", Icons.blur_on),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Heatmap Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.network(
                  fullImageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white24, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            "Heatmap unavailable",
                            style: GoogleFonts.exo2(color: Colors.white24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Overlay label
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "AI FOCUS MAP",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Color Legend
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "COLOR GUIDE",
                  style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildColorLegendItem(Colors.red, "High Focus", "Key areas")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildColorLegendItem(Colors.yellow, "Medium", "Supporting")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildColorLegendItem(Colors.blue, "Low", "Background")),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Description
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.description ??
                        "The highlighted areas show which parts of your lips the AI focused on to make its decision. Warmer colors (red/yellow) indicate areas that had the most influence.",
                    style: GoogleFonts.exo2(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildGuideStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.orbitron(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.exo2(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorLegendItem(Color color, String label, String sublabel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0.3)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            sublabel,
            style: GoogleFonts.exo2(
              color: Colors.white54,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
