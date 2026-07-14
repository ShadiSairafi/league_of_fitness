import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/fitness_provider.dart';
import '../models/fitness_data.dart';
import '../widgets/rank_progression_dialog.dart';
import '../services/ai_service.dart';
import '../config.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      appBar: AppBar(
        title: Text(
          "LEAGUE OF FITNESS",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 20,
            color: const Color(0xFFFF5E00),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.bolt, color: Color(0xFFFF007F), size: 18),
            onPressed: () => _showQuickActionsSheet(context, context.read<FitnessProvider>()),
          )
        ],
      ),
      body: Consumer<FitnessProvider>(
        builder: (context, provider, child) {
          final profile = provider.userProfile;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.showMissedDayAlert) ...[
                  _buildMissedDayWarning(context, provider),
                ],
                _buildUnitStats(context, provider),
                const SizedBox(height: 16),
                _buildRanksPanel(context, provider),
                const SizedBox(height: 24),
                _buildSectionTitle("NUTRITION METRICS"),
                const SizedBox(height: 12),
                _buildProgressRings(profile),
                const SizedBox(height: 24),
                _buildSectionTitle("METABOLIC ENGINE"),
                const SizedBox(height: 12),
                _buildMetabolicEngineCard(context, provider),
                const SizedBox(height: 24),
                _buildAIRecommendationCard(provider),
                const SizedBox(height: 24),
                _buildSectionTitle("WEIGHT TIMELINE"),
                const SizedBox(height: 12),
                _buildWeightChart(provider.weightHistory, profile.currentWeight),
                const SizedBox(height: 24),
                _buildWaterTracker(provider),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMissedDayWarning(BuildContext context, FitnessProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF007F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF007F).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(FontAwesomeIcons.triangleExclamation, color: Color(0xFFFF007F), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SCHEDULE ADJUSTED",
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFFF007F),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.missedDayAlertMsg,
                  style: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(FontAwesomeIcons.xmark, color: Colors.grey, size: 14),
            onPressed: () => provider.dismissMissedDayAlert(),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFFF007F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitStats(BuildContext context, FitnessProvider provider) {
    final profile = provider.userProfile;
    final isTodayCompleted = provider.isTodayWorkoutCompleted();
    final Color streakColor = isTodayCompleted ? const Color(0xFFFF5E00) : Colors.grey[600]!;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () => _showWeightUpdateDialog(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF161823), Color(0xFF0F1016)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2C2F3F), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF007F).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _statItem("CURRENT", "${profile.currentWeight}", "kg", const Color(0xFFFF5E00))),
                  Container(width: 1, height: 35, color: const Color(0xFF2C2F3F)),
                  Expanded(child: _statItem("GOAL", "${profile.targetWeight}", "kg", const Color(0xFFFF007F))),
                  Container(width: 1, height: 35, color: const Color(0xFF2C2F3F)),
                  Expanded(child: _statItem("BMI", profile.bmi.toStringAsFixed(1), "", const Color(0xFF00E5FF))),
                  Container(width: 1, height: 35, color: const Color(0xFF2C2F3F)),
                  Expanded(
                    child: _statItem(
                      "STREAK", 
                      "${provider.streakCount}", 
                      "🔥", 
                      streakColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWeightUpdateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12131C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFF007F), width: 1.5),
        ),
        title: Text(
          "UPDATE LOGS",
          style: GoogleFonts.orbitron(color: const Color(0xFFFF007F), fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter your current weight. Heavy weights build character.",
              style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Weight in kg",
                hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1B1D2A),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF5E00), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2C2F3F)),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.orbitron(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null && weight > 0) {
                context.read<FitnessProvider>().updateWeight(weight);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF007F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text("UPDATE", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: GoogleFonts.orbitron(color: color.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProgressRings(UserProfile profile) {
    double calPercent = (profile.caloriesConsumed / profile.calorieGoal).clamp(0.0, 1.0);
    double protPercent = (profile.proteinConsumed / profile.proteinGoal).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: _ringCard(
            "CALORIES",
            "${profile.caloriesConsumed}",
            "${profile.calorieGoal}",
            calPercent,
            const Color(0xFFFF5E00),
            FontAwesomeIcons.fire,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ringCard(
            "PROTEIN",
            "${profile.proteinConsumed}g",
            "${profile.proteinGoal}g",
            protPercent,
            const Color(0xFFFF007F), // pink color (no green)
            FontAwesomeIcons.dna,
          ),
        ),
      ],
    );
  }

  Widget _ringCard(String label, String value, String goal, double percent, Color color, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: percent),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      builder: (context, animPercent, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF11121A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF232533)),
          ),
          child: Column(
            children: [
              CircularPercentIndicator(
                radius: 46.0,
                lineWidth: 7.0,
                percent: animPercent,
                center: NeonAnimatedIcon(
                  icon: icon,
                  color: color,
                  shouldRotate: label == "PROTEIN",
                ),
                progressColor: color,
                backgroundColor: const Color(0xFF1E202C),
                circularStrokeCap: CircularStrokeCap.round,
                animation: false,
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: GoogleFonts.orbitron(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                "Target: $goal",
                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIRecommendationCard(FitnessProvider provider) {
    final profile = provider.userProfile;
    // Glow color (neon pink or neon blue depending on joint safety)
    final color = profile.isJumpRopeUnlocked ? const Color(0xFF00E5FF) : const Color(0xFFFF007F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), const Color(0xFF11121B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(FontAwesomeIcons.robot, color: color, size: 16),
                  const SizedBox(width: 12),
                  Text(
                    "AI RECOMMENDATION",
                    style: GoogleFonts.orbitron(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (provider.isLoadingRecommendation)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF007F)),
                  ),
                )
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(FontAwesomeIcons.arrowsRotate, color: color.withOpacity(0.8), size: 14),
                  onPressed: () => provider.refreshRecommendation(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: provider.isLoadingRecommendation
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF007F)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Analyzing metrics and generating advice...",
                          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  )
                : Text(
                    provider.aiRecommendation,
                    style: GoogleFonts.outfit(
                      color: Colors.grey[300],
                      height: 1.5,
                      fontSize: 13.2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> weightHistory, double currentWeight) {
    List<FlSpot> spots = [];
    List<String> dates = [];
    
    if (weightHistory.isEmpty) {
      spots = [FlSpot(0, currentWeight)];
      dates = [DateTime.now().toIso8601String().substring(5, 10).replaceAll('-', '/')];
    } else {
      final startIdx = max(0, weightHistory.length - 7);
      for (int i = startIdx; i < weightHistory.length; i++) {
        final w = weightHistory[i]['weight'];
        final dateStr = weightHistory[i]['date'] as String? ?? "";
        final displayDate = dateStr.length >= 10 ? dateStr.substring(5, 10).replaceAll('-', '/') : "";
        
        spots.add(FlSpot((i - startIdx).toDouble(), (w is num) ? w.toDouble() : currentWeight));
        dates.add(displayDate);
      }
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 24, right: 20, bottom: 10, left: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF11121B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF232533)),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF0C0D14),
              tooltipBorder: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((barSpot) {
                  return LineTooltipItem(
                    "${barSpot.y.toStringAsFixed(1)} kg",
                    GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF1F2233).withOpacity(0.4),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "${value.toInt()}",
                    style: GoogleFonts.robotoMono(color: Colors.grey[600], fontSize: 9),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < dates.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dates[idx],
                        style: GoogleFonts.robotoMono(color: Colors.grey[500], fontSize: 8.5),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF00E5FF),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, xPercent, bar, index) => FlDotCirclePainter(
                  radius: 5,
                  color: const Color(0xFF00E5FF),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.18),
                    const Color(0xFF00E5FF).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static FlDotPainter _getDotPainter(FlSpot spot, double xPercent, LineChartBarData bar, int index) {
    return FlDotCirclePainter(
      radius: 6,
      color: const Color(0xFFFF007F),
      strokeWidth: 2,
      strokeColor: Colors.white,
    );
  }

  Widget _buildWaterTracker(FitnessProvider provider) {
    final profile = provider.userProfile;
    final percent = (profile.waterDrankMl / profile.waterGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11121A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF232533)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HYDRATION",
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                "${profile.waterDrankMl} / ${profile.waterGoal}ml",
                style: GoogleFonts.robotoMono(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutQuad,
            builder: (context, animPercent, child) {
              return LinearPercentIndicator(
                padding: EdgeInsets.zero,
                percent: animPercent,
                progressColor: const Color(0xFF00E5FF),
                backgroundColor: const Color(0xFF1E202C),
                lineHeight: 12,
                barRadius: const Radius.circular(6),
                animation: false,
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _waterButton(provider, 250, "Glass", const Color(0xFF00E5FF)),
              const SizedBox(width: 12),
              _waterButton(provider, 500, "Bottle", const Color(0xFFFF007F)),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => provider.removeLastWater(),
                icon: const Icon(FontAwesomeIcons.rotateLeft, color: Colors.white, size: 14),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2F3F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _waterButton(FitnessProvider provider, int amount, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => provider.addWater(amount),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.plus, size: 11, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetabolicEngineCard(BuildContext context, FitnessProvider provider) {
    final activeBurn = provider.activeCaloriesBurnedToday;
    final naturalBurn = provider.bmr;
    final totalBurn = naturalBurn + activeBurn;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11121B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF232533)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metabolicItem("ACTIVE BURN", "${activeBurn.toStringAsFixed(0)}", "kcal", const Color(0xFFFF5E00)),
              Container(width: 1, height: 40, color: const Color(0xFF2C2F3F)),
              _metabolicItem("NATURAL BURN", "${naturalBurn.toStringAsFixed(0)}", "kcal", const Color(0xFF00E5FF)),
              Container(width: 1, height: 40, color: const Color(0xFF2C2F3F)),
              _metabolicItem("TOTAL EXPENDITURE", "${totalBurn.toStringAsFixed(0)}", "kcal", const Color(0xFFFF007F)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[850], thickness: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: const Color(0xFF00E5FF),
              ),
              icon: const Icon(FontAwesomeIcons.calendarDays, size: 14),
              label: Text(
                "VIEW BURN LOG HISTORY",
                style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              onPressed: () => _showBurnHistoryDialog(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metabolicItem(String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label, 
            style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(width: 2),
              Text(unit, style: GoogleFonts.orbitron(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showBurnHistoryDialog(BuildContext context, FitnessProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _BurnHistoryDialog(provider: provider),
    );
  }

  static const List<String> _hardcoreQuotes = [
    "SWEAT IS JUST COWARDICE LEAVING THE SYSTEM. GET UP AND LIFT.",
    "THE ONLY BAD WORKOUT IS THE ONE THAT EXISTED ONLY IN YOUR HEAD.",
    "DO NOT PRAY FOR AN EASY PROTOCOL. DEVELOP A STRONGER CHASSIS.",
    "IN THE TANK ENGINE, WE DO NOT LIFT EXPECTATIONS. WE LIFT IRON.",
    "NO ONE EVER DROWNED IN THEIR OWN SWEAT. COMMENCE THE REPS.",
    "LIMITS ARE MENTAL CONSTRUCTS. DESTROY THE HARDWARE BARRIER.",
    "PAIN IS PROGRESSIVE DATA INPUT. UPLOAD THE REPS.",
    "YOUR BODY IS A MACHINE. FEED IT FUEL AND CRUSH THE METRICS.",
    "STOP WISHING. START SYNCHRONIZING YOUR TRAINING SYSTEM."
  ];

  void _showQuickActionsSheet(BuildContext context, FitnessProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F111E),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(
              color: const Color(0xFFFF007F).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SUPERCHARGE ENGINE",
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFF007F),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                    const Icon(FontAwesomeIcons.bolt, color: Color(0xFFFF007F), size: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Execute instantaneous energy and nutrient logging protocols:",
                  style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 20),
                
                _buildSheetAction(
                  icon: FontAwesomeIcons.glassWater,
                  color: const Color(0xFF00E5FF),
                  title: "HYDRATE (+500ML WATER)",
                  subtitle: "Add water to active hydration metrics",
                  onTap: () async {
                    await provider.addWater(500);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildNeonSnackBar("HYDRATION DATA LOADED (+500ML)", const Color(0xFF00E5FF)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSheetAction(
                  icon: FontAwesomeIcons.wineBottle,
                  color: const Color(0xFFFF5E00),
                  title: "WHEY SHAKE (+120 KCAL | +25G PRO)",
                  subtitle: "Fast protein synthesis recovery infusion",
                  onTap: () async {
                    await provider.quickLogRecipeMacros(120, 25, "Whey Protein Shake");
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildNeonSnackBar("PROTEIN SHAKE LOGGED (+25g Pro)", const Color(0xFFFF5E00)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSheetAction(
                  icon: FontAwesomeIcons.mugHot,
                  color: const Color(0xFFFFD700),
                  title: "PRE-WORKOUT ENERGY (+100 KCAL)",
                  subtitle: "Boost focus and energy before lifting",
                  onTap: () async {
                    await provider.addCalories(100, note: "Pre-Workout Coffee");
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildNeonSnackBar("PRE-WORKOUT STIM LOGGED (+100 Kcal)", const Color(0xFFFFD700)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSheetAction(
                  icon: FontAwesomeIcons.appleWhole,
                  color: const Color(0xFF55DD33),
                  title: "FRUIT SNACK (+80 KCAL | +200ML H2O)",
                  subtitle: "Hydrating whole foods natural energy",
                  onTap: () async {
                    await provider.addCalories(80, note: "Fruit Snack");
                    await provider.addWater(200);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildNeonSnackBar("FRUIT SNACK LOGGED (+80 Kcal, +200ml H2O)", const Color(0xFF55DD33)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSheetAction(
                  icon: FontAwesomeIcons.candyCane,
                  color: const Color(0xFFFF4444),
                  title: "CHEAT SNACK (+350 KCAL)",
                  subtitle: "High-density sugar/salty cheat snack",
                  onTap: () async {
                    await provider.addCalories(350, note: "Cheat Snack");
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildNeonSnackBar("CHEAT SNACK LOGGED (+350 Kcal)", const Color(0xFFFF4444)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSheetAction(
                  icon: FontAwesomeIcons.brain,
                  color: const Color(0xFFFF007F),
                  title: "AI MOTIVATION PEP TALK",
                  subtitle: "Access The Tank Coach hardcore quote engine",
                  onTap: () {
                    Navigator.of(context).pop();
                    _showPepTalkDialog(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.roboto(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withOpacity(0.7), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SnackBar _buildNeonSnackBar(String text, Color color) {
    return SnackBar(
      backgroundColor: const Color(0xFF0F111E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      content: Text(
        text,
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _showPepTalkDialog(BuildContext context) {
    bool apiLoading = true;
    String quote = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (apiLoading && quote.isEmpty) {
              Future.microtask(() async {
                try {
                  final service = AICoachService(geminiApiKey);
                  final response = await service.askGeneralPrompt(
                    "Give the user a short, hardcore, cyberpunk-style 1-sentence motivation quote. Start with 'TANK ENGINE STATUS:' or similar. Keep it under 15 words.",
                  );
                  if (context.mounted) {
                    setDialogState(() {
                      quote = response.trim().toUpperCase();
                      apiLoading = false;
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() {
                      quote = _hardcoreQuotes[Random().nextInt(_hardcoreQuotes.length)];
                      apiLoading = false;
                    });
                  }
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0E111A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: const Color(0xFFFF007F).withOpacity(0.5), width: 1.5),
              ),
              title: Row(
                children: [
                  const Icon(FontAwesomeIcons.brain, color: Color(0xFFFF007F), size: 16),
                  const SizedBox(width: 10),
                  Text(
                    "MOTIVATION PROTOCOLS",
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              content: apiLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF007F))),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF08090C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.2)),
                          ),
                          child: Text(
                            quote,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFFFF007F),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "COACH TANK PROTOCOLS: ACTIVE",
                          style: GoogleFonts.robotoMono(color: Colors.grey[500], fontSize: 10),
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "ACKNOWLEDGED",
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BurnHistoryDialog extends StatefulWidget {
  final FitnessProvider provider;
  const _BurnHistoryDialog({required this.provider});

  @override
  State<_BurnHistoryDialog> createState() => _BurnHistoryDialogState();
}

class _BurnHistoryDialogState extends State<_BurnHistoryDialog> {
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int displayMonth = now.month + _monthOffset;
    int displayYear = now.year;
    while (displayMonth <= 0) {
      displayMonth += 12;
      displayYear -= 1;
    }
    
    final displayDate = DateTime(displayYear, displayMonth, 1);
    final List<String> monthNames = [
      "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
      "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ];
    final monthName = monthNames[displayMonth - 1];

    final daysInMonth = DateUtils.getDaysInMonth(displayYear, displayMonth);
    final firstDayOffset = DateTime(displayYear, displayMonth, 1).weekday % 7;
    final totalGridItems = firstDayOffset + daysInMonth;

    return AlertDialog(
      backgroundColor: const Color(0xFF0C0D14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _monthOffset > -2
                ? () => setState(() => _monthOffset--)
                : null,
          ),
          Column(
            children: [
              Text(
                monthName,
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              Text(
                "$displayYear",
                style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _monthOffset < 0
                ? () => setState(() => _monthOffset++)
                : null,
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        height: 330,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["S", "M", "T", "W", "T", "F", "S"]
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.orbitron(
                                color: const Color(0xFFFF5E00), fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: totalGridItems,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index < firstDayOffset) {
                    return const SizedBox.shrink();
                  }
                  
                  final dayNum = index - firstDayOffset + 1;
                  final mStr = displayMonth < 10 ? "0$displayMonth" : "$displayMonth";
                  final dStr = dayNum < 10 ? "0$dayNum" : "$dayNum";
                  final dateKey = "$displayYear-$mStr-$dStr";

                  final burnKcal = widget.provider.calorieBurnHistory[dateKey] ?? 0;
                  final hasBurned = burnKcal > 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: hasBurned
                          ? const Color(0xFF00E5FF).withOpacity(0.12)
                          : Colors.grey[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasBurned
                            ? const Color(0xFF00E5FF).withOpacity(0.4)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$dayNum",
                          style: GoogleFonts.outfit(
                            color: hasBurned ? Colors.white : Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasBurned) ...[
                          const SizedBox(height: 1),
                          Text(
                            "$burnKcal",
                            style: GoogleFonts.robotoMono(
                              color: const Color(0xFF00E5FF),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text("DISMISS", style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class NeonAnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool shouldRotate; // Kept for interface compatibility but maps to pulse

  const NeonAnimatedIcon({
    super.key,
    required this.icon,
    required this.color,
    this.shouldRotate = false,
  });

  @override
  State<NeonAnimatedIcon> createState() => _NeonAnimatedIconState();
}

class _NeonAnimatedIconState extends State<NeonAnimatedIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        final result = Transform.scale(
          scale: _scaleAnim.value,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 24,
          ),
        );

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.18 + 0.08 * sin(_controller.value * pi)),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: result,
        );
      },
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
