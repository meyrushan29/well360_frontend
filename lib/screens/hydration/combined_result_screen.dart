// lib/screens/hydration/combined_result_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';
import 'xai_explanation_widget.dart';

class CombinedResultScreen extends StatelessWidget {
  final Map<String, dynamic> formResult;
  final Map<String, dynamic>? lipResult;
  final String userName;

  const CombinedResultScreen({
    super.key,
    this.formResult = const {},
    this.lipResult,
    this.userName = "Merus",
  });

  @override
  Widget build(BuildContext context) {
    // ---------------- Data Extraction ----------------
    final bool hasForm = formResult.isNotEmpty;
    final bool hasLip = lipResult != null && lipResult!.isNotEmpty;

    // 1. Water Need (Form)
    double waterNeed = 0.0;
    if (hasForm && formResult.containsKey('recommended_total_water_liters')) {
      final val = formResult['recommended_total_water_liters'];
      if (val is num) {
        waterNeed = val.toDouble();
      } else if (val is String) {
        waterNeed = double.tryParse(val) ?? 0.0;
      }
    }
    
    // 2. Lip Score (Image)
    int lipScore = 0;
    String lipStatus = "N/A";
    
    if (hasLip) {
      if (lipResult!.containsKey('hydration_score')) {
         final val = lipResult!['hydration_score'];
         if (val is num) {
           lipScore = val.toInt();
         } else if (val is String) {
           lipScore = int.tryParse(val) ?? 0;
         }
      }
      lipStatus = lipResult!['prediction']?.toString() ?? 
                  lipResult!['status']?.toString() ?? 
                  lipResult!['hydration_risk_level']?.toString() ??
                  "Unknown";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
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
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context), 
                        icon: const Icon(Icons.close, color: Colors.white70)
                      ),
                      Text(
                        "ANALYSIS RESULT",
                        style: GoogleFonts.orbitron(
                          color: Colors.white, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2
                        ),
                      ),
                      const SizedBox(width: 40), // Balance
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Here is your hydration breakdown.",
                    style: GoogleFonts.exo2(color: Colors.white60, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // ===============================
                  // METRIC 1: WATER NEED (FORM)
                  // ===============================
                  if (hasForm)
                    _buildBigMetricCard(
                      title: "NEXT 4 HOURS NEED",
                      value: "${waterNeed.toStringAsFixed(1)} L",
                      subtitle: "Based on your body metrics & activity",
                      icon: Icons.water_drop,
                      color: Colors.cyanAccent,
                    )
                  else
                    _buildMissingDataCard("Water Need Data Missing", Colors.cyanAccent),

                  const SizedBox(height: 24),

                  // ===============================
                  // METRIC 2: LIP SCORE (IMAGE)
                  // ===============================
                  if (hasLip)
                    Column(
                      children: [
                        _buildBigMetricCard(
                          title: "LIP HYDRATION SCORE",
                          value: "$lipScore / 100",
                          subtitle: "Status: $lipStatus",
                          icon: Icons.face_retouching_natural,
                          color: lipScore > 75 ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        if (lipResult!.containsKey('xai_url') && lipResult!['xai_url'] != null) ...[
                          const SizedBox(height: 16),
                          XaiExplanationWidget(
                            heatmapUrl: lipResult!['xai_url'],
                            description: lipResult!['xai_description'],
                          ),
                        ],
                      ],
                    )
                  else
                    _buildMissingDataCard("Lip Scan Data Missing", Colors.orangeAccent),

                  // ===============================
                  // NEW: AI REASONING (FORM)
                  // ===============================
                  if (hasForm && formResult.containsKey('ai_reasoning')) ...[
                    const SizedBox(height: 30),
                    _buildAiReasoningCard(formResult['ai_reasoning']),
                  ],

                  // ===============================
                  // NEW: PERSONALIZED SUGGESTIONS
                  // ===============================
                  const SizedBox(height: 30),
                  _buildPersonalizedSuggestions(),

                  const SizedBox(height: 50),

                  // Action Button
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, spreadRadius: 0)]
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0
                      ),
                      child: Text(
                        "DONE", 
                        style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBigMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 30, spreadRadius: 5)
        ]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.orbitron(color: Colors.white60, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.exo2(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAiReasoningCard(dynamic reasoning) {
    List<String> factors = [];
    if (reasoning is List) {
      factors = reasoning.map((e) => e.toString()).toList();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                "AI REASONING",
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (factors.isEmpty)
             Text("No specific reasoning available.", style: GoogleFonts.exo2(color: Colors.white60))
          else
            Column(
              children: factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Colors.cyanAccent, fontSize: 18)),
                    Expanded(
                      child: Text(f, style: GoogleFonts.exo2(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }



  Widget _buildMissingDataCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white24, size: 40),
           const SizedBox(height: 10),
          Text(text, style: GoogleFonts.exo2(color: Colors.white24)),
        ],
      ),
    );
  }

  // ===============================
  // NEW: PERSONALIZED SUGGESTIONS
  // ===============================
  Widget _buildPersonalizedSuggestions() {
    // Collect suggestions from both form and lip results
    final List<dynamic> allSuggestions = [];
    
    if (formResult.isNotEmpty && formResult.containsKey('personalized_suggestions')) {
      final formSuggestions = formResult['personalized_suggestions'];
      if (formSuggestions is List) {
        allSuggestions.addAll(formSuggestions);
      }
    }
    
    if (lipResult != null && lipResult!.containsKey('personalized_suggestions')) {
      final lipSuggestions = lipResult!['personalized_suggestions'];
      if (lipSuggestions is List) {
        // Avoid duplicates by checking IDs
        final existingIds = allSuggestions
            .where((s) => s is Map && s.containsKey('id'))
            .map((s) => s['id'])
            .toSet();
        
        for (var suggestion in lipSuggestions) {
          if (suggestion is Map && 
              suggestion.containsKey('id') && 
              !existingIds.contains(suggestion['id'])) {
            allSuggestions.add(suggestion);
          }
        }
      }
    }

    // If no suggestions, don't show the section
    if (allSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                "PERSONALIZED SUGGESTIONS",
                style: GoogleFonts.orbitron(
                  color: Colors.amberAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Suggestions List
          ...allSuggestions.map((suggestion) {
            if (suggestion is! Map) return const SizedBox.shrink();
            return _buildSuggestionCard(Map<String, dynamic>.from(suggestion));
          }),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final String category = suggestion['category']?.toString() ?? 'general';
    final String title = suggestion['title']?.toString() ?? 'Suggestion';
    final String content = suggestion['content']?.toString() ?? '';
    final int priority = suggestion['priority'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(category).withOpacity(0.15),
            _getCategoryColor(category).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(category).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(category).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              _getCategoryIcon(category),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.exo2(
                    color: _getCategoryColor(category),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          Text(
            content,
            style: GoogleFonts.exo2(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          // Priority Indicator
          if (priority == 1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.priority_high,
                  size: 14,
                  color: Colors.redAccent.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'HIGH PRIORITY',
                  style: GoogleFonts.exo2(
                    color: Colors.redAccent.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return Colors.cyanAccent;
      case 'health':
        return Colors.redAccent;
      case 'nutrition':
        return Colors.greenAccent;
      case 'activity':
        return Colors.orangeAccent;
      case 'environment':
        return Colors.purpleAccent;
      case 'general':
        return Colors.blueAccent;
      default:
        return Colors.white70;
    }
  }

  Icon _getCategoryIcon(String category) {
    IconData iconData;
    switch (category.toLowerCase()) {
      case 'hydration':
        iconData = Icons.water_drop;
        break;
      case 'health':
        iconData = Icons.favorite;
        break;
      case 'nutrition':
        iconData = Icons.restaurant;
        break;
      case 'activity':
        iconData = Icons.directions_run;
        break;
      case 'environment':
        iconData = Icons.wb_sunny;
        break;
      case 'general':
        iconData = Icons.info_outline;
        break;
      default:
        iconData = Icons.lightbulb_outline;
    }
    return Icon(
      iconData,
      color: _getCategoryColor(category),
      size: 18,
    );
  }
}
