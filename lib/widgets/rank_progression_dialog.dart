import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/fitness_provider.dart';

class RankProgressionDialog extends StatefulWidget {
  final bool isProgressRank;

  const RankProgressionDialog({
    super.key,
    required this.isProgressRank,
  });

  static void show(BuildContext context, bool isProgressRank) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => RankProgressionDialog(isProgressRank: isProgressRank),
    );
  }

  @override
  State<RankProgressionDialog> createState() => _RankProgressionDialogState();
}

class _RankProgressionDialogState extends State<RankProgressionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  final List<FloatingParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize floating background particles
    for (int i = 0; i < 25; i++) {
      _particles.add(FloatingParticle(
        x: _random.nextDouble() * 320,
        y: _random.nextDouble() * 450,
        speed: _random.nextDouble() * 0.4 + 0.1,
        radius: _random.nextDouble() * 3 + 1,
        angle: _random.nextDouble() * 2 * pi,
        color: widget.isProgressRank 
            ? const Color(0xFF00E5FF).withOpacity(_random.nextDouble() * 0.4 + 0.1)
            : const Color(0xFFFF5E00).withOpacity(_random.nextDouble() * 0.4 + 0.1),
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final accentColor = widget.isProgressRank ? const Color(0xFF00E5FF) : const Color(0xFFFF5E00);
    
    // Define ranks list data
    final List<RankItemData> ranks = widget.isProgressRank 
      ? [
          RankItemData(
            name: "IRON INITIATE",
            requirement: "0 completed exercises",
            milestone: 0,
            imagePath: "assets/images/iron_initiate.jpg",
          ),
          RankItemData(
            name: "BRONZE BEAST",
            requirement: "10 completed exercises",
            milestone: 10,
            imagePath: "assets/images/bronze_beast.jpg",
          ),
          RankItemData(
            name: "SILVER STRIDER",
            requirement: "30 completed exercises",
            milestone: 30,
            imagePath: "assets/images/silver_stryder.jpg",
          ),
          RankItemData(
            name: "GOLDEN UNIT",
            requirement: "60 completed exercises",
            milestone: 60,
            imagePath: "assets/images/golden_unit.jpg",
          ),
          RankItemData(
            name: "TITANIUM TANK",
            requirement: "100 completed exercises",
            milestone: 100,
            imagePath: "assets/images/titanium_tank.jpg",
          ),
          RankItemData(
            name: "DIAMOND OVERLORD",
            requirement: "200 completed exercises",
            milestone: 200,
            imagePath: "assets/images/diamond_overlord.jpg",
          ),
        ]
      : [
          RankItemData(
            name: "SPARK",
            requirement: "0 days streak",
            milestone: 0,
            imagePath: "assets/images/spark.jpg",
          ),
          RankItemData(
            name: "EMBER",
            requirement: "5 days streak",
            milestone: 5,
            imagePath: "assets/images/ember.jpg",
          ),
          RankItemData(
            name: "WILDFIRE",
            requirement: "15 days streak",
            milestone: 15,
            imagePath: "assets/images/wildfire.jpg",
          ),
          RankItemData(
            name: "SUPERNOVA",
            requirement: "30 days streak",
            milestone: 30,
            imagePath: "assets/images/supernova.jpg",
          ),
          RankItemData(
            name: "COSMIC SINGULARITY",
            requirement: "60 days streak",
            milestone: 60,
            imagePath: "assets/images/cosmic_singularity.jpg",
          ),
          RankItemData(
            name: "ZENITH ETERNAL",
            requirement: "90 days streak",
            milestone: 90,
            imagePath: "assets/images/zenith_eternal.jpg",
          ),
        ];

    final currentRankName = widget.isProgressRank ? provider.progressRank : provider.streakRank;
    final currentScore = widget.isProgressRank ? provider.completedExercisesCount : provider.streakCount;
    final progressVal = widget.isProgressRank ? provider.progressRankProgress : provider.streakRankProgress;
    final nextRankName = widget.isProgressRank ? provider.nextProgressRank : provider.nextStreakRank;

    return Center(
      child: Container(
        width: 320,
        height: 480,
        decoration: BoxDecoration(
          color: const Color(0xFF0C0D14),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 25,
              spreadRadius: 2,
            )
          ],
        ),
        child: Stack(
          children: [
            // Particle Canvas background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                for (var p in _particles) {
                  p.update();
                }
                return CustomPaint(
                  size: const Size(320, 480),
                  painter: ParticleBgPainter(particles: _particles),
                );
              },
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isProgressRank ? "PROGRESS PIPELINE" : "STREAK CHRONOLOGY",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(FontAwesomeIcons.xmark, color: Colors.grey, size: 16),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current Rank Highlight Panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "CURRENT TIER: ",
                              style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currentRankName,
                              style: GoogleFonts.orbitron(color: accentColor, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.isProgressRank 
                                  ? "$currentScore Completed"
                                  : "$currentScore Day Streak",
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              nextRankName == "MAX TIER" ? "MAX LEVEL" : "NEXT: $nextRankName",
                              style: GoogleFonts.orbitron(color: Colors.grey[400], fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressVal,
                            minHeight: 6,
                            backgroundColor: Colors.grey[900],
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tiers Progression List
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: ranks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rank = ranks[index];
                        final isCurrent = rank.name == currentRankName;
                        
                        // Check if unlocked
                        bool isUnlocked = false;
                        if (widget.isProgressRank) {
                          isUnlocked = currentScore >= rank.milestone;
                        } else {
                          isUnlocked = currentScore >= rank.milestone;
                        }

                        final itemOpacity = isUnlocked ? 1.0 : 0.45;

                        return Opacity(
                          opacity: itemOpacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCurrent 
                                  ? accentColor.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent 
                                    ? accentColor.withOpacity(0.5) 
                                    : (isUnlocked ? Colors.grey[850]! : Colors.transparent),
                                width: isCurrent ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Badge image
                                ClipOval(
                                  child: Image.asset(
                                    rank.imagePath,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 42,
                                      height: 42,
                                      color: Colors.grey[900],
                                      child: Icon(
                                        widget.isProgressRank ? FontAwesomeIcons.medal : FontAwesomeIcons.fire,
                                        color: accentColor,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title / Requirement
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rank.name,
                                        style: GoogleFonts.orbitron(
                                          color: isCurrent ? accentColor : Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        rank.requirement,
                                        style: GoogleFonts.outfit(
                                          color: Colors.grey[500],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Lock/Check Status Icon
                                Icon(
                                  isCurrent
                                      ? FontAwesomeIcons.circleDot
                                      : (isUnlocked ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.lock),
                                  color: isCurrent 
                                      ? accentColor 
                                      : (isUnlocked ? const Color(0xFF00E5FF) : Colors.grey[700]),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankItemData {
  final String name;
  final String requirement;
  final int milestone;
  final String imagePath;

  RankItemData({
    required this.name,
    required this.requirement,
    required this.milestone,
    required this.imagePath,
  });
}

class FloatingParticle {
  double x;
  double y;
  double speed;
  double radius;
  double angle;
  Color color;

  FloatingParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.angle,
    required this.color,
  });

  void update() {
    x += cos(angle) * speed;
    y += sin(angle) * speed;

    // Boundaries reset
    if (x < -10) x = 330;
    if (x > 330) x = -10;
    if (y < -10) y = 490;
    if (y > 490) y = -10;
  }
}

class ParticleBgPainter extends CustomPainter {
  final List<FloatingParticle> particles;

  ParticleBgPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      paint.color = p.color;
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
