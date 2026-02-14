// lib/screens/mentalHealth/video/stress_graph_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter_application_1/widgets/grid_painter.dart';
import 'package:flutter_application_1/services/api_service.dart';

class StressGraphScreen extends StatefulWidget {
  const StressGraphScreen({super.key});

  @override
  State<StressGraphScreen> createState() => _StressGraphScreenState();
}

class _StressGraphScreenState extends State<StressGraphScreen> {
  Map<String, dynamic>? _stressData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStressData();
  }

  Future<void> _loadStressData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getStressAnalysis();
      if (mounted) {
        setState(() {
          _stressData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  List<FlSpot> _buildChartSpots() {
    if (_stressData == null) return [];

    final trend = _stressData!['stress_trend'] as List<dynamic>? ?? [];
    if (trend.isEmpty) {
      // Fallback: generate from history
      final history = _stressData!['history'] as List<dynamic>? ?? [];
      if (history.isEmpty) return [const FlSpot(0, 0)];

      final stressEmotions = ['sad', 'angry', 'fear', 'disgust'];
      List<FlSpot> spots = [];
      int windowSize = 3;
      for (int i = 0; i < history.length; i++) {
        int start = (i - windowSize + 1).clamp(0, history.length);
        List<dynamic> window = history.sublist(start, i + 1);
        int stressCount = window.where((h) => stressEmotions.contains((h['emotion'] ?? '').toString().toLowerCase())).length;
        double prob = (stressCount / window.length) * 100;
        spots.add(FlSpot(i.toDouble(), prob));
      }
      return spots;
    }

    return trend.map<FlSpot>((item) {
      return FlSpot(
        (item['index'] as num).toDouble(),
        (item['stress_probability'] as num).toDouble(),
      );
    }).toList();
  }

  Color _getStressColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'moderate':
        return Colors.orangeAccent;
      case 'low':
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('STRESS ANALYSIS', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadStressData,
          ),
        ],
      ),
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
            child: _isLoading
                ? _buildLoading()
                : _errorMessage != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 20),
          Text(
            'Loading stress data...',
            style: GoogleFonts.exo2(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.analytics_outlined, size: 48, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Available',
              style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete some emotion analyses first to generate stress insights.',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(fontSize: 14, color: Colors.white60),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadStressData,
              icon: const Icon(Icons.refresh),
              label: Text('RETRY', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final stressLevel = _stressData?['stress_level'] ?? 'Low';
    final stressProb = (_stressData?['stress_probability'] ?? 0.0) as num;
    final dominantEmotion = _stressData?['dominant_emotion'] ?? 'Unknown';
    final emotionsAnalyzed = _stressData?['emotions_analyzed'] ?? 0;
    final stressColor = _getStressColor(stressLevel);
    final spots = _buildChartSpots();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STRESS TREND',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 1
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on $emotionsAnalyzed emotion analyses',
            style: GoogleFonts.exo2(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 20),
          
          // Graph Container
          Container(
            height: 320,
            padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: spots.length > 1
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.exo2(color: Colors.white38, fontSize: 12),
                              );
                            },
                            interval: (spots.length / 6).ceilToDouble().clamp(1, double.infinity),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: GoogleFonts.exo2(color: Colors.white38, fontSize: 10),
                              );
                            },
                            reservedSize: 40,
                            interval: 20,
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: spots.first.x,
                      maxX: spots.last.x,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Colors.cyanAccent, Colors.purpleAccent],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: Colors.purpleAccent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyanAccent.withValues(alpha: 0.2),
                                Colors.purpleAccent.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                '${touchedSpot.y.round()}%',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'Not enough data for trend graph.\nAnalyze more emotions to see trends.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.exo2(color: Colors.white38, fontSize: 14),
                    ),
                  ),
          ),

          const SizedBox(height: 32),
          
          _buildStatCard(
            'CURRENT STRESS',
            stressLevel.toUpperCase(),
            stressColor,
            '${(stressProb * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'DOMINANT EMOTION',
            dominantEmotion.toUpperCase(),
            Colors.blueAccent,
            '$emotionsAnalyzed analyzed',
          ),
          
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Colors.white10, Colors.white12]),
                border: Border.all(color: Colors.white24)
              ),
              child: ElevatedButton(
                onPressed: () {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'BACK TO HOME',
                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, String subValue) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      color: Colors.white54,
                      letterSpacing: 1
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.exo2(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: color.withValues(alpha: 0.3))
                ),
                child: Text(
                  subValue,
                  style: GoogleFonts.orbitron(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
