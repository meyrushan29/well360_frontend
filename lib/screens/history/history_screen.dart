// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/api_service.dart'; 
import 'package:flutter_application_1/widgets/grid_painter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _hydrationHistory = [];
  List<dynamic> _lipHistory = [];
  Map<String, dynamic>? _trendsData;
  String? _lastError;
  
  bool _loading = true;
  late TabController _tabController;
  final bool _showTodayOnly = false;
  
  // Trend State: 0 = Today, 1 = Weekly, 2 = Monthly
  int _trendViewMode = 0; 
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHistory();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    
    if (token == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _lastError = "Please Log In to view history.";
        });
      }
      return;
    }

    final baseUrl = AuthService.baseUrl;
    String query = "";
      
    if (_showTodayOnly) {
         final now = DateTime.now();
         DateTime start = DateTime(now.year, now.month, now.day, 6);
         if (now.hour < 6) start = start.subtract(const Duration(days: 1));
         query = "?start_time=${start.toIso8601String()}";
    }

    // 1. Hydration
    try {
      final res = await http.get(Uri.parse("$baseUrl/history/hydration$query"), headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) _hydrationHistory = jsonDecode(res.body);
    } catch(e) { debugPrint("Hydration Error: $e"); }

    // 2. Lip Scans
    try {
      final res = await http.get(Uri.parse("$baseUrl/history/lip$query"), headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) _lipHistory = jsonDecode(res.body);
    } catch(e) { debugPrint("Lip Error: $e"); }

    // 3. Trends
    try {
      _trendsData = await ApiService.getTrends();
      _lastError = null; // Clear error if success
    } catch(e) { 
      debugPrint("Trends Error: $e");
      _lastError = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Clear History?", style: GoogleFonts.orbitron(color: Colors.white)),
        content: Text("Delete ALL logs?", style: GoogleFonts.exo2(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Clear All", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) return;
    final baseUrl = AuthService.baseUrl;
    await http.delete(Uri.parse("$baseUrl/history/clear"), headers: {"Authorization": "Bearer $token"});
    _fetchHistory(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "HISTORY & TRENDS",
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context), color: Colors.white),
        actions: [
           IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetchHistory),
           IconButton(
             icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
             tooltip: "Clear All Data",
             onPressed: _clearHistory,
           ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
             margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
             padding: const EdgeInsets.all(4),
             decoration: BoxDecoration(
               color: Colors.white.withValues(alpha: 0.05),
               borderRadius: BorderRadius.circular(30),
               border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
             ),
             child: TabBar(
               controller: _tabController,
               indicator: BoxDecoration(
                 gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                 borderRadius: BorderRadius.circular(26),
               ),
               labelColor: Colors.black,
               unselectedLabelColor: Colors.white60,
               labelStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 11),
               dividerColor: Colors.transparent,
               tabs: const [
                 Tab(text: "LOGS"),
                 Tab(text: "SCANS"),
                 Tab(text: "ANALYZE"),
               ],
             ),
          ),
        ),
      ),
      body: Stack(
         children: [
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
            child: Opacity(opacity: 0.1, child: CustomPaint(painter: GridPainter())),
          ),
          
          SafeArea(
             child: _loading
                 ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                 : TabBarView(
                     controller: _tabController,
                     children: [
                       _buildHydrationTab(),
                       _buildLipTab(),
                       _buildTrendsTab(),
                     ],
                   ),
          )
         ]
      )
    );
  }

  Widget _buildTrendsTab() {
     if (_trendsData == null) return const Center(child: Text("No trend data available", style: TextStyle(color: Colors.white)));

     // Determine Data based on Selection
     List<dynamic> data = [];
     double total = 0.0;
     String units = "L";
     int mode = _trendViewMode;

     if (mode == 0) { // DAILY (Today)
       data = _trendsData!['hourly'] ?? [];
       total = (_trendsData!['today_total_liters'] ?? 0.0).toDouble();
     } else if (mode == 1) { // WEEKLY
       data = _trendsData!['weekly'] ?? [];
       total = (_trendsData!['weekly_total_liters'] ?? 0.0).toDouble();
     } else { // MONTHLY
       data = _trendsData!['monthly'] ?? [];
       total = (_trendsData!['monthly_total_liters'] ?? 0.0).toDouble();
     }

     return SingleChildScrollView(
       padding: const EdgeInsets.all(24),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           // Toggle Row (3 Buttons)
           Container(
             padding: const EdgeInsets.all(4),
             decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
             child: Row(
               children: [
                 _buildToggleBtn("TODAY", 0),
                 _buildToggleBtn("WEEK", 1),
                 _buildToggleBtn("MONTH", 2),
               ],
             ),
           ),
           const SizedBox(height: 30),

           // Stats Row
           Row(
             children: [
               Expanded(child: _buildStatCard("TOTAL INTAKE", "${total.toStringAsFixed(1)} $units", Colors.cyanAccent)),
               if (mode > 0) ...[ // Show Avg only for Week/Month
                   const SizedBox(width: 15),
                   Expanded(
                       child: _buildStatCard(
                           "DAILY AVERAGE", 
                           "${(total / (data.isEmpty ? 1 : data.length)).toStringAsFixed(1)} $units", 
                           Colors.purpleAccent
                       )
                   ),
               ]
             ],
           ),

           const SizedBox(height: 30),

           // Chart
           Container(
             height: 320,
             padding: const EdgeInsets.only(right: 20, top: 30, bottom: 10),
             decoration: BoxDecoration(
               color: Colors.black26, 
               borderRadius: BorderRadius.circular(24),
               border: Border.all(color: Colors.white10),
             ),
             child: BarChart(
               BarChartData(
                 gridData: const FlGridData(show: false),
                 borderData: FlBorderData(show: false),
                 titlesData: FlTitlesData(
                   leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(color: Colors.white24, fontSize: 10)))),
                   bottomTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       getTitlesWidget: (val, meta) {
                         if (val.toInt() >= 0 && val.toInt() < data.length) {
                            String label = "";
                            if (mode == 0) {
                               // Hourly: "10:00" -> "10"
                               label = data[val.toInt()]['hour'].toString().split(':').first;
                               if (val.toInt() % 4 != 0) return const SizedBox.shrink(); // Show every 4th hour
                            } else {
                               // Date: "2023-10-21" -> "21"
                               label = data[val.toInt()]['date'].toString().split('-').last;
                               if (mode == 2 && val.toInt() % 5 != 0) return const SizedBox.shrink(); // Show every 5th day for month
                            }
                            return Padding(padding: const EdgeInsets.only(top:8), child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)));
                         }
                         return const SizedBox.shrink();
                       }
                     )
                   ),
                   topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 ),
                 barGroups: data.asMap().entries.map((e) {
                   return BarChartGroupData(
                     x: e.key,
                     barRods: [
                       BarChartRodData(
                         toY: (e.value['liters'] as num).toDouble(),
                         color: mode == 0 ? Colors.greenAccent : (mode == 1 ? Colors.cyanAccent : Colors.purpleAccent),
                         width: mode == 2 ? 6 : 12, // Thinner for month
                         borderRadius: BorderRadius.circular(4),
                         backDrawRodData: BackgroundBarChartRodData(show: true, toY: 4, color: Colors.white.withValues(alpha: 0.05))
                       )
                     ]
                   );
                 }).toList(),
               )
             ),
           ),
           
           const SizedBox(height: 20),
           Center(child: Text(mode == 0 ? "Hours (0-23)" : "Days (Timeline)", style: GoogleFonts.exo2(color: Colors.white38, fontSize: 12))),
           
           if (_lastError != null)
             Padding(
               padding: const EdgeInsets.only(top: 20),
               child: Text(
                 "Sync Error: $_lastError",
                 style: GoogleFonts.exo2(color: Colors.redAccent, fontSize: 12),
                 textAlign: TextAlign.center,
               ),
             ),
         ],
       ),
     );
  }

  Widget _buildToggleBtn(String text, int index) {
    bool active = _trendViewMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _trendViewMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
             border: active ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)) : null,
          ),
          child: Text(
            text, 
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              color: active ? Colors.cyanAccent : Colors.white60, 
              fontWeight: FontWeight.bold,
              fontSize: 12
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHydrationTab() => _hydrationHistory.isEmpty 
     ? const Center(child: Text("No Logs", style: TextStyle(color: Colors.white38)))
     : ListView.builder(
         padding: const EdgeInsets.all(20),
         itemCount: _hydrationHistory.length,
         itemBuilder: (c, i) => _buildHydrationCard(_hydrationHistory[_hydrationHistory.length - 1 - i])
       );

  Widget _buildLipTab() => _lipHistory.isEmpty 
     ? const Center(child: Text("No Scans", style: TextStyle(color: Colors.white38)))
     : ListView.builder(
         padding: const EdgeInsets.all(20),
         itemCount: _lipHistory.length,
         itemBuilder: (c, i) => _buildLipCard(_lipHistory[_lipHistory.length - 1 - i])
       );

  Widget _buildHydrationCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text("${item['liters']} L", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
           Text(item['date'].toString().split('T').first, style: GoogleFonts.exo2(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLipCard(dynamic item) {
     return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text("Score: ${item['hydration_score']}", style: GoogleFonts.orbitron(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold)),
           Text(item['prediction'], style: GoogleFonts.exo2(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
