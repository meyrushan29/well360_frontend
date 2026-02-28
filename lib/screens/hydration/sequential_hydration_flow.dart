import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/hydration_results_service.dart';
import 'combined_result_screen.dart';
import 'package:flutter_application_1/widgets/grid_painter.dart';
import 'camera_screen.dart';

class SequentialHydrationFlow extends StatefulWidget {
  const SequentialHydrationFlow({super.key});

  @override
  State<SequentialHydrationFlow> createState() => _SequentialHydrationFlowState();
}

class _SequentialHydrationFlowState extends State<SequentialHydrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _loading = false;

  // ---------------- STEP 1: FORM DATA ----------------
  final _formKey = GlobalKey<FormState>();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final waterController = TextEditingController();
  final exerciseController = TextEditingController();
  final timeSlotController = TextEditingController();

  String gender = "Male";
  String activity = "Moderate";
  String urinated = "Yes";
  int urineColor = 4;
  String thirsty = "No";
  String dizziness = "No";
  String fatigue = "No";
  String headache = "No";
  String sweating = "Moderate";
  String timeSlot = "12 PM-4 PM";

  // Results from Step 1
  Map<String, dynamic>? _formResult;

  // ---------------- STEP 2: TIMER ----------------
  Timer? _timer;
  int _remainingSeconds = 120; // 2 Minutes
  bool _timerComplete = false;

  // ---------------- STEP 3: LIP IMAGE ----------------
  XFile? _image;
  Uint8List? _displayBytes;

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

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    waterController.dispose();
    exerciseController.dispose();
    timeSlotController.dispose();
    super.dispose();
  }

  void _setTimeSlot() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 4) {
      timeSlot = "Midnight-4 AM";
    } else if (hour >= 4 && hour < 8) {
      timeSlot = "4 AM-8 AM";
    } else if (hour >= 8 && hour < 12) {
      timeSlot = "8 AM-12 PM";
    } else if (hour >= 12 && hour < 16) {
      timeSlot = "12 PM-4 PM";
    } else if (hour >= 16 && hour < 20) {
      timeSlot = "4 PM-8 PM";
    } else {
      timeSlot = "8 PM-Midnight";
    }
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

  // ==================== LOGIC: STEP 1 -> 2 ====================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);

    try {
      double lat = 0.0;
      double lon = 0.0;
      try {
        final pos = await LocationService.getLocation();
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (e) {
        debugPrint("Location error: $e");
      }

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

      final response = await ApiService.predictHydration(requestData);

      // Process Result
      final double recommended = response['recommended_total_water_liters']?.toDouble() ?? 0.0;
      final rawConditions = response['predicted_medical_conditions'];
      Map<String, String> risks = {};
      if (rawConditions is Map) {
        rawConditions.forEach((k, v) {
           if (v.toString() != "Low") risks[k.toString().replaceAll("_", " ").toUpperCase()] = v.toString();
        });
      }

      String riskLevel = "Normal";
      if (recommended > 2.0) {
        riskLevel = "High Dehydration";
      } else if (recommended > 1.0) {
        riskLevel = "Mild Dehydration";
      }

      _formResult = {
        "recommended_total_water_liters": recommended,
        "hydration_risk_level": riskLevel,
        "hydration_score": response['hydration_score'],
        "temperature_c": response['temperature_c'],
        "humidity_percent": response['humidity_percent'],
        "health_risks": risks,
        "ai_reasoning": response['ai_reasoning'],
        "recommendations": response['recommendations'] ?? [],
      };

      // Save to Service (Transient)
      final service = HydrationResultsService();
      service.saveFormResult(_formResult!);

      // Move to Timer
      _startTimer();
      _nextPage();

    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ==================== LOGIC: STEP 2 (TIMER) ====================
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _timerComplete = true);
        // Automatically move to next step or let user click?
        // User request: "Provide a time count for lip img Upload That is Most Relastice"
        // We'll let them click "Continue" when done or auto-enable button
      }
    });
  }

  String get _timerString {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // ==================== LOGIC: STEP 3 (IMAGE) ====================
  Future<void> _pickImage(ImageSource source) async {
    XFile? pickedFile;
    if (source == ImageSource.camera) {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
      if (result is XFile) pickedFile = result;
    } else {
      pickedFile = await ImagePicker().pickImage(source: source);
    }

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = pickedFile;
        _displayBytes = bytes;
      });
    }
  }

  Future<void> _submitImage() async {
    if (_image == null && _displayBytes == null) return;
    setState(() => _loading = true);

    try {
      final result = await ApiService.predictLip(imageFile: _image, webImage: _displayBytes);
      
      final String prediction = result['prediction'] ?? "Unknown";
      final double confidence = (result['confidence'] ?? 0.0) * 100;
      final int score = result['hydration_score'] ?? 0;

      final lipUiResult = {
        "hydration_risk_level": prediction == "Dehydrate" ? "Dehydrated" : "Normal",
        "hydration_score": score,
        "xai_url": result['xai_url'],
        "xai_description": result['xai_description'],
        "recommendations": [
          result['recommendation'] ?? "No specific advice.",
          "AI Confidence: ${confidence.toStringAsFixed(1)}%",
        ]
      };

      final service = HydrationResultsService();
      service.saveLipResult(lipUiResult);
      if (service.userName == "User") await service.fetchUserName();

      // FINISH -> Go to Combined Result
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CombinedResultScreen(
              formResult: service.formResult,
              lipResult: service.lipResult,
              userName: service.userName,
            ),
          ),
        );
      }

    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    setState(() => _currentStep++);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ==================== UI BUILDER ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
           "COMPLETE CHECK",
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
          Container(
             decoration: const BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
                 colors: [Color(0xFF050505), Color(0xFF101015)],
               ),
             ),
          ),
          Positioned.fill(child: Opacity(opacity: 0.1, child: CustomPaint(painter: GridPainter()))),
          
          SafeArea(
            child: Column(
              children: [
                // STEP INDICATOR
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepDot(0, "Form"),
                      _buildStepLine(0),
                      _buildStepDot(1, "Wait"),
                      _buildStepLine(1),
                      _buildStepDot(2, "Scan"),
                    ],
                  ),
                ),
                
                Expanded(
                  child: PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    children: [
                      _buildStep1Form(),
                      _buildStep2Timer(),
                      _buildStep3Image(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_loading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int stepIndex, String label) {
    bool isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.cyanAccent : Colors.white10,
            boxShadow: isActive ? [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 10)] : []
          ),
          child: Center(
            child: isActive 
              ? const Icon(Icons.check, size: 16, color: Colors.black)
              : Text((stepIndex + 1).toString(), style: const TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.exo2(color: Colors.white54, fontSize: 10))
      ],
    );
  }

  Widget _buildStepLine(int index) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
      color: _currentStep > index ? Colors.cyanAccent : Colors.white10,
    );
  }

  // ---------------- STEP 1 UI ----------------
  Widget _buildStep1Form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildLiveWeatherCard(),
            const SizedBox(height: 16),
            _buildGlassSection("PERSONAL INFO", Icons.person, [
              Row(children: [
                Expanded(child: _modernTextField(ageController, "Age", Icons.cake, isInteger: true)),
                const SizedBox(width: 10),
                Expanded(child: _modernDropdown("Gender", gender, ["Male", "Female"], (v) => setState(() => gender = v))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _modernTextField(weightController, "Weight (kg)", Icons.monitor_weight)),
                const SizedBox(width: 10),
                Expanded(child: _modernTextField(heightController, "Height (cm)", Icons.height)),
              ]),
            ]),
            const SizedBox(height: 15),
             _buildGlassSection("INTAKE & ACTIVITY", Icons.directions_run, [
               _modernTextField(waterController, "Water Intake (L) - 4h", Icons.local_drink),
               const SizedBox(height: 10),
               _modernTextField(exerciseController, "Exercise (min) - 4h", Icons.fitness_center),
               const SizedBox(height: 10),
                _modernDropdown("Activity", activity, ["Sedentary", "Light", "Moderate", "Heavy", "Very Heavy"], (v) => setState(() => activity = v)),
             ]),
             const SizedBox(height: 15),
             _buildGlassSection("SIGNS", Icons.water_drop, [
                _modernDropdown("Urinated?", urinated, ["Yes", "No"], (v) => setState(() => urinated = v)),
                if (urinated == "Yes") ...[
                   const SizedBox(height: 10),
                   const Text("Urine Color", style: TextStyle(color: Colors.white70)),
                   const SizedBox(height: 5),
                   _urineColorPicker(),
                ]
             ]),
             const SizedBox(height: 15),
             _buildGlassSection("SYMPTOMS", Icons.healing, [
                _modernDropdown("Thirsty?", thirsty, ["Yes", "No"], (v) => setState(() => thirsty = v)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _toggleChip("Dizziness", dizziness, (v) => setState(() => dizziness = v)),
                    _toggleChip("Fatigue", fatigue, (v) => setState(() => fatigue = v)),
                    _toggleChip("Headache", headache, (v) => setState(() => headache = v)),
                  ],
                ),
                const SizedBox(height: 15),
                _modernDropdown("Sweating Level", sweating, ["None", "Light", "Moderate", "Heavy", "Very Heavy"], (v) => setState(() => sweating = v)),
             ]),
             const SizedBox(height: 30),
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _submitForm,
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                 child: Text("ANALYZE & CONTINUE", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.black)),
               ),
             ),
             const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ---------------- STEP 2 UI ----------------
  Widget _buildStep2Timer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, size: 80, color: Colors.cyanAccent),
          const SizedBox(height: 30),
          Text("WAIT FOR 2 MINUTES", style: GoogleFonts.orbitron(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Allow your body to stabilize for accurate lip analysis.", textAlign: TextAlign.center, style: GoogleFonts.exo2(color: Colors.white60)),
          const SizedBox(height: 50),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200, height: 200,
                child: CircularProgressIndicator(
                  value: _remainingSeconds / 120,
                  strokeWidth: 10,
                  backgroundColor: Colors.white10,
                  color: Colors.cyanAccent,
                ),
              ),
              Text(
                _timerString,
                style: GoogleFonts.orbitron(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 50),
          if (_timerComplete)
             ElevatedButton(
               onPressed: _nextPage,
               style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
               child: Text("CONTINUE TO SCAN", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.black)),
             )
          else 
             TextButton(
               onPressed: () {
                 // Cheat for testing: skip timer
                 _timer?.cancel();
                 setState(() { _remainingSeconds = 0; _timerComplete = true; });
               },
               child: const Text("Skip Timer (Testing)", style: TextStyle(color: Colors.white30))
             )
        ],
      ),
    );
  }

  // ---------------- STEP 3 UI ----------------
  Widget _buildStep3Image() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text("LIP HYDRATION SCAN", style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text("Take a clear photo of your lips.", style: GoogleFonts.exo2(color: Colors.white70)),
          const SizedBox(height: 30),
          
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _displayBytes != null 
                  ? Image.memory(_displayBytes!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.face, size: 100, color: Colors.white10)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _actionButton("Camera", Icons.camera_alt, Colors.cyanAccent, () => _pickImage(ImageSource.camera)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _actionButton("Gallery", Icons.photo_library, Colors.purpleAccent, () => _pickImage(ImageSource.gallery)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_displayBytes != null)
            SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _submitImage,
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                 child: Text("GET FINAL RESULTS", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.black)),
               ),
             ),
             
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ---------------- REUSED WIDGETS ----------------
  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.black, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 12)),
    );
  }

  Widget _buildGlassSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: Colors.cyanAccent, size: 18), const SizedBox(width: 10), Text(title, style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold))]),
          const Divider(color: Colors.white10),
          ...children
        ],
      ),
    );
  }

  Widget _modernTextField(TextEditingController c, String label, IconData icon, {bool isInteger = false}) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true, fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      validator: (v) => v!.isEmpty ? "Req" : null,
    );
  }

  Widget _modernDropdown(String label, String val, List<String> items, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: val,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _urineColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _uColorBtn(1, const Color(0xFFFFF9C4), "Clear"),
        _uColorBtn(4, const Color(0xFFFFB74D), "Yellow"),
        _uColorBtn(8, const Color(0xFFE65100), "Dark"),
      ],
    );
  }

  Widget _uColorBtn(int val, Color color, String lbl) {
    bool sel = urineColor == val;
    return GestureDetector(
      onTap: () => setState(() => urineColor = val),
      child: Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: sel ? Border.all(color: Colors.white, width: 2) : null),
            child: sel ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
          ),
          Text(lbl, style: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 10))
        ],
      ),
    );
  }

  Widget _toggleChip(String label, String val, ValueChanged<String> onChanged) {
    bool isYes = val == "Yes";
    return GestureDetector(
      onTap: () => onChanged(isYes ? "No" : "Yes"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isYes ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isYes ? Colors.cyanAccent : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isYes ? Colors.white : Colors.white54, fontSize: 11)),
      ),
    );
  }

  Widget _buildLiveWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LIVE WEATHER",
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Local Conditions",
                style: GoogleFonts.exo2(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          if (_weatherLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
            )
          else if (_currentTemp != null)
            Row(
              children: [
                _weatherMetric(Icons.thermostat, "${_currentTemp!.toStringAsFixed(1)}°C"),
                const SizedBox(width: 12),
                _weatherMetric(Icons.water_drop, "${_currentHum!.toStringAsFixed(0)}%"),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white38, size: 16),
              onPressed: _fetchWeather,
            ),
        ],
      ),
    );
  }

  Widget _weatherMetric(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
