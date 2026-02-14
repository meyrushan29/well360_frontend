// lib/screens/hydration/form_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/hydration_results_service.dart';
import 'combined_result_screen.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  String timeSlot = "12 PM-4 PM";

  @override
  void initState() {
    super.initState();
    _setTimeSlot();
    _loadProfile();
    _fetchWeather();
  }

  double? _currentTemp;
  double? _currentHum;
  bool _weatherLoading = false;

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() => _weatherLoading = true);
    try {
      final pos = await LocationService.getLocation();
      final weather = await ApiService.getWeather(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentTemp = (weather['temperature_c'] as num).toDouble();
          _currentHum = (weather['humidity_percent'] as num).toDouble();
        });
      }
    } catch (e) {
      debugPrint("Weather fetch error: $e");
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  void _setTimeSlot() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 4) {
      timeSlot = "Midnight-4 AM";
    } else if (hour >= 4 && hour < 8) timeSlot = "4 AM-8 AM";
    else if (hour >= 8 && hour < 12) timeSlot = "8 AM-12 PM";
    else if (hour >= 12 && hour < 16) timeSlot = "12 PM-4 PM";
    else if (hour >= 16 && hour < 20) timeSlot = "4 PM-8 PM";
    else timeSlot = "8 PM-Midnight";
    timeSlotController.text = timeSlot;
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          if (profile['age'] != null) ageController.text = profile['age'].toString();
          if (profile['weight'] != null) weightController.text = profile['weight'].toString();
          if (profile['height'] != null) heightController.text = profile['height'].toString();
          if (profile['gender'] != null) gender = profile['gender'];
        });
      }
    } catch (e) {
      debugPrint("Profile load error: $e");
    }
  }

  // ---------------- Controllers ----------------
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final waterController = TextEditingController();
  final exerciseController = TextEditingController();
  final timeSlotController = TextEditingController();

  // ---------------- Dropdown values ----------------
  String gender = "Male";
  String activity = "Moderate";
  String urinated = "Yes";
  int urineColor = 4;
  String thirsty = "No";
  String dizziness = "No";
  String fatigue = "No";
  String headache = "No";
  String sweating = "Moderate";


  bool loading = false;

  // ---------------- Submit ----------------
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // 0. Pre-check: backend reachable
      final backendOk = await ApiService.checkBackendReachable();
      if (!backendOk && mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Backend not reachable. Start it first: double-click START_BACKEND.bat in the project folder (or run 'python run.py' from Final_Backend) and keep that window open. Then check URL in Settings (gear icon).",
              style: GoogleFonts.exo2(),
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // 1. Get Location (Default to 0,0 if fails)
      double lat = 0.0;
      double lon = 0.0;
      try {
        final pos = await LocationService.getLocation();
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (e) {
        debugPrint("Location error: $e");
      }

      // 2. Prepare Data
      final requestData = {
        "Age": int.parse(ageController.text),
        "Gender": gender,
        "Weight": double.parse(weightController.text),
        "Height": double.parse(heightController.text),
        "Water_Intake_Last_4_Hours": double.parse(waterController.text),
        "Exercise_Time_Last_4_Hours": double.parse(exerciseController.text),
        "Physical_Activity_Level": activity,
        "Urinated_Last_4_Hours": urinated,
        "Urine_Color": urineColor,
        "Thirsty": thirsty,
        "Dizziness": dizziness,
        "Fatigue": fatigue,
        "Headache": headache,
        "Sweating_Level": sweating,
        "Time_Slot": timeSlot,
        "Latitude": lat,
        "Longitude": lon,
        "Existing Diseases / Medical Conditions": "None",
      };

      // 3. Call API
      final response = await ApiService.predictHydration(requestData);

      if (!mounted) return;

      // 4. Map Response to UI Model
      final double recommended = response['recommended_total_water_liters']?.toDouble() ?? 0.0;
      
      // Handle Medical Conditions
      final rawConditions = response['predicted_medical_conditions'];
      Map<String, String> risks = {};
      
      if (rawConditions is Map) {
        rawConditions.forEach((k, v) {
           if (v.toString() != "Low") {
             risks[k.toString().replaceAll("_", " ").toUpperCase()] = v.toString();
           }
        });
      } else if (rawConditions is String && rawConditions != "None") {
        risks[rawConditions] = "Potential Risk";
      }

      String riskLevel = "Normal";
      if (recommended > 2.0) {
        riskLevel = "High Dehydration";
      } else if (recommended > 1.0) riskLevel = "Mild Dehydration";
      
      final uiResult = {
        "recommended_total_water_liters": recommended,
        "hydration_risk_level": riskLevel,
        "hydration_score": response['hydration_score'],
        "temperature_c": response['temperature_c'],
        "humidity_percent": response['humidity_percent'],
        "health_risks": risks,
        "ai_reasoning": response['ai_reasoning'],
        "recommendations": response['recommendations'] ?? [],
        "personalized_suggestions": response['personalized_suggestions'] ?? [], // NEW: Database-driven suggestions
      };

      // SAVE TO SERVICE
      final service = HydrationResultsService();
      service.saveFormResult(uiResult);
      if (service.userName == "User") await service.fetchUserName();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CombinedResultScreen(
            formResult: service.formResult,
            lipResult: service.lipResult,
            userName: service.userName,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           content: Text("Error: $e", style: GoogleFonts.exo2()), 
           backgroundColor: Colors.redAccent.withOpacity(0.3),
           behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Dark BG
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
           "DAILY LOG",
           style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildLiveWeatherCard(),
                          const SizedBox(height: 20),
                          // Personal Information Section
                          _buildGlassSection(
                            title: "PERSONAL INFO",
                            icon: Icons.person_outline,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _modernTextField(
                                      ageController,
                                      "Age",
                                      Icons.cake,
                                      isInteger: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _modernDropdown(
                                      "Gender",
                                      gender,
                                      ["Male", "Female"],
                                      (v) => setState(() => gender = v),
                                      Icons.people_outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _modernTextField(
                                      weightController,
                                      "Weight (kg)",
                                      Icons.monitor_weight_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _modernTextField(
                                      heightController,
                                      "Height (cm)",
                                      Icons.height,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 20),
      
                          // Activity Information Section
                          _buildGlassSection(
                            title: "ACTIVITY & INTAKE",
                            icon: Icons.directions_run,
                            children: [
                              _modernTextField(
                                waterController,
                                "Water intake (L) - Last 4h",
                                Icons.local_drink,
                              ),
                              const SizedBox(height: 16),
                              _modernTextField(
                                exerciseController,
                                "Exercise (min) - Last 4h",
                                Icons.fitness_center,
                              ),
                              const SizedBox(height: 16),
                              _modernDropdown(
                                "Activity Level",
                                activity,
                                [
                                  "Sedentary",
                                  "Light",
                                  "Moderate",
                                  "Heavy",
                                  "Very Heavy",
                                ],
                                (v) => setState(() => activity = v),
                                Icons.trending_up,
                              ),
                              const SizedBox(height: 16),
                              _modernDropdown(
                                "Time Slot",
                                timeSlot,
                                [
                                  "Midnight-4 AM",
                                  "4 AM-8 AM",
                                  "8 AM-12 PM",
                                  "12 PM-4 PM",
                                  "4 PM-8 PM",
                                  "8 PM-Midnight"
                                ],
                                (v) => setState(() => timeSlot = v),
                                Icons.access_time, 
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 20),
      
                          // Urination & Symptoms Section
                          _buildGlassSection(
                            title: "HYDRATION SIGNS",
                            icon: Icons.water_drop_outlined,
                            children: [
                               _modernDropdown(
                                "Urinated in last 4h?",
                                urinated,
                                ["Yes", "No"],
                       (v) => setState(() => urinated = v),
                                Icons.wc,
                              ),
                              if (urinated == "Yes") ...[
                                const SizedBox(height: 20),
                                Text(
                                  "URINE COLOR SCALE",
                                  style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1),
                                ),
                                const SizedBox(height: 12),
                                _urineColorPicker(),
                              ],
                            ],
                          ),
      
                          const SizedBox(height: 20),
                          
                          _buildGlassSection(
                            title: "SYMPTOMS CHECK",
                            icon: Icons.health_and_safety_outlined,
                            children: [
                              _modernDropdown(
                                "Feeling Thirsty?",
                                thirsty,
                                ["Yes", "No"],
                                (v) => setState(() => thirsty = v),
                                Icons.water_drop,
                              ),
                               const SizedBox(height: 16),
                              _modernDropdown(
                                "Sweating Level",
                                sweating,
                                ["None", "Light", "Moderate", "Heavy", "Very Heavy"],
                                (v) => setState(() => sweating = v),
                                Icons.thermostat,
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  _toggleChip("DIZZINESS", dizziness, (v) => setState(() => dizziness = v)),
                                  _toggleChip("FATIGUE", fatigue, (v) => setState(() => fatigue = v)),
                                  _toggleChip("HEADACHE", headache, (v) => setState(() => headache = v)),
                                ],
                              ),
                            ],
                          ),
      
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),),
      
                // Bottom Submit Button Area
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                      ),
                      child: SafeArea(
                        child: loading
                            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                            : Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 1
                                    )
                                  ]
                                ),
                                child: ElevatedButton(
                                  onPressed: submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyanAccent,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    "ANALYZE DATA",
                                    style: GoogleFonts.orbitron(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
         ]
       ),
    );
  }

  // ---------------- Widgets ----------------
  Widget _buildGlassSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Icon(icon, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1
                    ),
                  ),
                ],
              ),
              Divider(height: 30, color: Colors.white.withValues(alpha: 0.1)),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isInteger = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      style: GoogleFonts.exo2(color: Colors.white, fontWeight: FontWeight.bold),
      cursorColor: Colors.cyanAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Req.";
        if (isInteger) {
          final n = int.tryParse(v);
          if (n == null) return "Integers only";
          if (n <= 0) return "> 0";
        } else {
          final n = double.tryParse(v);
          if (n == null) return "Invalid #";
          if (label.contains("Water") || label.contains("Exercise")) {
             if (n < 0) return ">= 0";
          } else {
             // Weight, Height
             if (n <= 0) return "> 0";
          }
        }
        return null;
      },
    );
  }

  Widget _modernDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1E1E1E),
      style: GoogleFonts.exo2(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.purpleAccent.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.purpleAccent),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e, 
                child: Text(e),
              ))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _urineColorPicker() {
    final options = [
      {'value': 1, 'color': const Color(0xFFFFF9C4), 'label': 'Clear'},
      {'value': 4, 'color': const Color(0xFFFFB74D), 'label': 'Yellow'}, 
      {'value': 8, 'color': const Color(0xFFE65100), 'label': 'Dark'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((opt) {
          final int val = opt['value'] as int;
          final Color color = opt['color'] as Color;
          final String label = opt['label'] as String;
          final isSelected = urineColor == val;

          return GestureDetector(
            onTap: () => setState(() => urineColor = val),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 50 : 40,
                  height: isSelected ? 50 : 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : Border.all(color: Colors.white10),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 15, spreadRadius: 5)]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 24)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.exo2(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _toggleChip(String label, String value, ValueChanged<String> onChanged) {
    final bool isYes = value == "Yes";
    return GestureDetector(
      onTap: () => onChanged(isYes ? "No" : "Yes"),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isYes ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isYes ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isYes ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 8)] : []
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isYes ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isYes ? Colors.cyanAccent : Colors.white38,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 12,
                color: isYes ? Colors.white : Colors.white70,
                fontWeight: isYes ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 1
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.1),
            Colors.cyanAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LIVE WEATHER CONDITION",
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Based on your current location",
                style: GoogleFonts.exo2(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
          if (_weatherLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
            )
          else if (_currentTemp != null)
            Row(
              children: [
                _weatherMetric(Icons.thermostat, "${_currentTemp!.toStringAsFixed(1)}°C"),
                const SizedBox(width: 16),
                _weatherMetric(Icons.water_drop, "${_currentHum!.toStringAsFixed(0)}%"),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white38, size: 20),
              onPressed: _fetchWeather,
            ),
        ],
      ),
    );
  }

  Widget _weatherMetric(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    waterController.dispose();
    exerciseController.dispose();
    super.dispose();
  }
}
