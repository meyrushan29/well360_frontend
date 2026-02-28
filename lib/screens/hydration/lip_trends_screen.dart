// lib/screens/hydration/lip_trends_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';

class LipTrendsScreen extends StatefulWidget {
  const LipTrendsScreen({super.key});

  @override
  State<LipTrendsScreen> createState() => _LipTrendsScreenState();
}

class _LipTrendsScreenState extends State<LipTrendsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _trendsData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrends();
  }

  Future<void> _fetchTrends() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getLipTrends();
      if (mounted) {
        setState(() {
          _trendsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "LIP HEALTH TRENDS",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
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

          // Content
          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.cyanAccent),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 20),
          Text(
            "Failed to load trends",
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            _error ?? "Unknown error",
            style: GoogleFonts.exo2(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchTrends,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            child: Text("RETRY", style: GoogleFonts.orbitron(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_trendsData == null) return const SizedBox.shrink();

    final List<dynamic> trendData = _trendsData!['trend_data'] ?? [];
    final Map<String, dynamic> summary = _trendsData!['summary'] ?? {};

    if (trendData.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Cards
          _buildSummaryCards(summary),
          const SizedBox(height: 30),

          // Line Chart
          _buildTrendChart(trendData),
          const SizedBox(height: 30),

          // Insights
          _buildInsights(summary),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_chart_outlined, color: Colors.white24, size: 80),
          const SizedBox(height: 20),
          Text(
            "NO DATA YET",
            style: GoogleFonts.orbitron(
              color: Colors.white54,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Complete a few lip scans to see your trends!",
            style: GoogleFonts.exo2(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final totalScans = summary['total_scans'] ?? 0;
    final avgScore = summary['avg_score'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total Scans",
            totalScans.toString(),
            Icons.camera_alt,
            Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Avg Score",
            avgScore.toStringAsFixed(1),
            Icons.star,
            Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.exo2(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<dynamic> trendData) {
    // Prepare data points
    final spots = <FlSpot>[];
    for (int i = 0; i < trendData.length; i++) {
      final score = (trendData[i]['score'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), score));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withValues(alpha: 0.1),
            Colors.blueAccent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HYDRATION SCORE TREND",
            style: GoogleFonts.orbitron(
              color: Colors.cyanAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (spots.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= trendData.length) return const SizedBox();
                        final date = trendData[value.toInt()]['date'] ?? '';
                        final parts = date.split('-');
                        if (parts.length >= 2) {
                          return Text(
                            '${parts[1]}/${parts[2]}',
                            style: GoogleFonts.exo2(color: Colors.white38, fontSize: 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.exo2(color: Colors.white54, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.cyanAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.cyanAccent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.3),
                          Colors.cyanAccent.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildInsights(Map<String, dynamic> summary) {
    final improvement = summary['improvement'] ?? 0.0;
    final dehydratedCount = summary['dehydrated_count'] ?? 0;
    final normalCount = summary['normal_count'] ?? 0;
    final bestScore = summary['best_score'] ?? 0;
    final worstScore = summary['worst_score'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.greenAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                "INSIGHTS",
                style: GoogleFonts.orbitron(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            improvement >= 0 ? "Improvement" : "Change",
            "${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)} points",
            improvement >= 0 ? Icons.trending_up : Icons.trending_down,
            improvement >= 0 ? Colors.greenAccent : Colors.orangeAccent,
          ),
          _buildInsightRow(
            "Best Score",
            bestScore.toString(),
            Icons.star,
            Colors.yellowAccent,
          ),
          _buildInsightRow(
            "Worst Score",
            worstScore.toString(),
            Icons.warning_amber,
            Colors.redAccent,
          ),
          _buildInsightRow(
            "Dehydrated Scans",
            "$dehydratedCount / ${dehydratedCount + normalCount}",
            Icons.water_drop,
            Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.exo2(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
