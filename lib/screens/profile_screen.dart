import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/fitness_provider.dart';
import '../models/fitness_data.dart';
import '../widgets/rank_progression_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _heightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _wristController;
  late TextEditingController _waistController;
  late TextEditingController _ageController;
  late TextEditingController _foodBioController;
  
  String _selectedBodyType = "Mesomorph";
  String _selectedBoneDensity = "Normal";

  @override
  void initState() {
    super.initState();
    final profile = context.read<FitnessProvider>().userProfile;
    _heightController = TextEditingController(text: profile.height.toString());
    _targetWeightController = TextEditingController(text: profile.targetWeight.toString());
    _wristController = TextEditingController(text: profile.wristCircumference.toString());
    _waistController = TextEditingController(text: profile.waistSize?.toString() ?? "");
    _ageController = TextEditingController(text: profile.age.toString());
    _foodBioController = TextEditingController(text: profile.foodBio);
    _selectedBodyType = profile.bodyType;
    _selectedBoneDensity = profile.boneDensity;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _targetWeightController.dispose();
    _wristController.dispose();
    _waistController.dispose();
    _ageController.dispose();
    _foodBioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<FitnessProvider>();
      final oldProfile = provider.userProfile;
      
      final updated = UserProfile(
        currentWeight: oldProfile.currentWeight,
        targetWeight: double.tryParse(_targetWeightController.text) ?? oldProfile.targetWeight,
        height: int.tryParse(_heightController.text) ?? oldProfile.height,
        wristCircumference: double.tryParse(_wristController.text) ?? oldProfile.wristCircumference,
        age: int.tryParse(_ageController.text) ?? oldProfile.age,
        waistSize: _waistController.text.trim().isEmpty ? null : double.tryParse(_waistController.text),
        bodyType: _selectedBodyType,
        boneDensity: _selectedBoneDensity,
        caloriesConsumed: oldProfile.caloriesConsumed,
        proteinConsumed: oldProfile.proteinConsumed,
        waterDrankMl: oldProfile.waterDrankMl,
        foodBio: _foodBioController.text.trim(),
      );

      provider.saveUserProfile(updated);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E5FF),
          content: Text(
            "BIOMETRICS SYNCED TO THE TANK AI",
            style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final profile = provider.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      appBar: AppBar(
        title: Text(
          "BIOMETRIC ENGINE",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 20,
            color: const Color(0xFFFF5E00),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFF007F).withOpacity(0.12), const Color(0xFF11121B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.2), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF007F).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.3)),
                      ),
                      child: const Icon(FontAwesomeIcons.dna, color: Color(0xFFFF007F), size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CURRENT PROFILE",
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFFFF007F),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${profile.currentWeight} kg @ ${profile.height} cm",
                            style: GoogleFonts.robotoMono(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "BMI: ${profile.bmi.toStringAsFixed(1)} | Type: ${profile.bodyType}",
                            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildRanksPanel(context, provider),
              const SizedBox(height: 28),
              
              _buildSectionTitle("PHYSICAL DIMENSIONS"),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _heightController,
                label: "HEIGHT (CM)",
                hint: "e.g. 178",
                icon: FontAwesomeIcons.arrowsUpDown,
                isNumber: true,
              ),
              const SizedBox(height: 18),
              
              _buildTextField(
                controller: _targetWeightController,
                label: "TARGET WEIGHT (KG)",
                hint: "e.g. 80.0",
                icon: FontAwesomeIcons.bullseye,
                isNumber: true,
              ),
              const SizedBox(height: 18),
              
              _buildTextField(
                controller: _wristController,
                label: "WRIST CIRCUMFERENCE (CM)",
                hint: "e.g. 18.5",
                icon: FontAwesomeIcons.hand,
                isNumber: true,
              ),
              const SizedBox(height: 18),

              _buildTextField(
                controller: _waistController,
                label: "WAIST CIRCUMFERENCE (CM) (OPTIONAL)",
                hint: "e.g. 95.0",
                icon: FontAwesomeIcons.ruler,
                isNumber: true,
              ),
              const SizedBox(height: 18),

              _buildTextField(
                controller: _ageController,
                label: "AGE (YEARS)",
                hint: "e.g. 30",
                icon: FontAwesomeIcons.calendarDays,
                isNumber: true,
              ),
              const SizedBox(height: 28),

              _buildSectionTitle("BIOTYPE CLASSIFICATION"),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: "BODY TYPE",
                value: _selectedBodyType,
                items: ["Ectomorph", "Mesomorph", "Endomorph"],
                icon: FontAwesomeIcons.childReaching,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBodyType = val);
                },
              ),
              const SizedBox(height: 18),

              _buildDropdownField(
                label: "BONE DENSITY / FRAME SIZE",
                value: _selectedBoneDensity,
                items: ["Slight", "Normal", "Heavy"],
                icon: FontAwesomeIcons.bone,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBoneDensity = val);
                },
              ),
              const SizedBox(height: 28),

              _buildSectionTitle("FUEL DIETARY PROTOCOLS"),
              const SizedBox(height: 16),

              _buildLargeTextField(
                controller: _foodBioController,
                label: "DIETARY PREFERENCES & DISLIKES",
                hint: "e.g., I hate mushrooms, love hot and spicy food, allergic to peanuts...",
                icon: FontAwesomeIcons.utensils,
              ),
              const SizedBox(height: 36),

              // Sync Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0083B0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveProfile,
                    child: Text(
                      "SYNC BIOMETRICS",
                      style: GoogleFonts.orbitron(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11121B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232533)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFF00E5FF),
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF00E5FF), size: 14),
          labelText: label,
          labelStyle: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 10, letterSpacing: 0.8),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 13),
          border: InputBorder.none,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            if (label.contains("OPTIONAL")) return null;
            return "Required";
          }
          if (isNumber && double.tryParse(value) == null) {
            return "Must be a number";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLargeTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11121B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232533)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.multiline,
        maxLines: 4,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFF00E5FF),
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF00E5FF), size: 14),
          labelText: label,
          labelStyle: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 10, letterSpacing: 0.8),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 13),
          border: InputBorder.none,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11121B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232533)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 14),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: const Color(0xFF11121B),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 10, letterSpacing: 0.8),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRanksPanel(BuildContext context, FitnessProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF232533), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => RankProgressionDialog.show(context, true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedRankBadge(
                      imagePath: provider.progressBadgePath,
                      fallbackIcon: FontAwesomeIcons.medal,
                      accentColor: const Color(0xFF00E5FF),
                      size: 68,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "PROGRESS RANK",
                      style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.progressRank,
                      style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: provider.progressRankProgress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF161823),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 110, color: const Color(0xFF2C2F3F)),
          Expanded(
            child: InkWell(
              onTap: () => RankProgressionDialog.show(context, false),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedRankBadge(
                      imagePath: provider.streakBadgePath,
                      fallbackIcon: FontAwesomeIcons.fire,
                      accentColor: const Color(0xFFFF5E00),
                      size: 68,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "STREAK RANK",
                      style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.streakRank,
                      style: GoogleFonts.orbitron(color: const Color(0xFFFF5E00), fontSize: 10, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: provider.streakRankProgress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF161823),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5E00)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedRankBadge extends StatefulWidget {
  final String imagePath;
  final IconData fallbackIcon;
  final Color accentColor;
  final double size;

  const AnimatedRankBadge({
    super.key,
    required this.imagePath,
    required this.fallbackIcon,
    required this.accentColor,
    this.size = 64,
  });

  @override
  State<AnimatedRankBadge> createState() => _AnimatedRankBadgeState();
}

class _AnimatedRankBadgeState extends State<AnimatedRankBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.3 + 0.15 * sin(_controller.value * pi)),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ScreenBlendImage(
            imagePath: widget.imagePath,
            width: widget.size,
            height: widget.size,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class ScreenBlendImage extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final Color accentColor;

  const ScreenBlendImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    required this.accentColor,
  });

  @override
  State<ScreenBlendImage> createState() => _ScreenBlendImageState();
}

class _ScreenBlendImageState extends State<ScreenBlendImage> {
  ui.Image? _resolvedImage;
  ImageStream? _imageStream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(ScreenBlendImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    _cleanup();
    final provider = AssetImage(widget.imagePath);
    _imageStream = provider.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _resolvedImage = info.image;
        });
      }
    });
    _imageStream!.addListener(_listener!);
  }

  void _cleanup() {
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedImage == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: widget.accentColor),
          ),
        ),
      );
    }
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: ScreenBlendPainter(_resolvedImage!),
    );
  }
}

class ScreenBlendPainter extends CustomPainter {
  final ui.Image image;
  ScreenBlendPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..filterQuality = FilterQuality.high;
    
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Offset.zero & size;
    
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant ScreenBlendPainter oldDelegate) => oldDelegate.image != image;
}
