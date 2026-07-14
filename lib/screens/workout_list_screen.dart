import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/fitness_provider.dart';
import '../models/fitness_data.dart';

class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  void _showMissedDayConfirmation(BuildContext context, String day) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF007F), width: 1.2),
        ),
        title: Text(
          "MISSED $day'S TRAINING?",
          style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          "Confirming this will trigger the Tank Coach AI to distribute $day's training volume into your remaining training days this week. This resets your completions for the week.",
          style: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            child: Text("CANCEL", style: GoogleFonts.orbitron(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(
              "YES, RESHUFFLE",
              style: GoogleFonts.orbitron(color: const Color(0xFFFF007F), fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<FitnessProvider>().reshuffleWorkoutDay(day);
            },
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: Text(
          "RESET WORKOUT PLAN?",
          style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          "Do you want to reset your weekly workout plan to its default configuration? All customized exercises and AI volume reshuffles will be cleared.",
          style: GoogleFonts.outfit(color: Colors.grey[300], fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            child: Text("CANCEL", style: GoogleFonts.orbitron(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(
              "RESET PLAN",
              style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<FitnessProvider>().resetWorkoutPlan();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    final workouts = provider.plan;
    final isSwapping = provider.isSwapping;

    // Detect today's day of the week to rotate and highlight
    final int todayWeekday = DateTime.now().weekday;
    String todayDayName = "";
    int activeIndex = 0; // Monday default to top on rest days/Monday

    if (todayWeekday == DateTime.tuesday) {
      todayDayName = "Tuesday";
      activeIndex = 1;
    } else if (todayWeekday == DateTime.wednesday) {
      todayDayName = "Wednesday";
      activeIndex = 2;
    } else if (todayWeekday == DateTime.thursday) {
      todayDayName = "Thursday";
      activeIndex = 3;
    } else if (todayWeekday == DateTime.sunday) {
      todayDayName = "Sunday";
      activeIndex = 4;
    } else if (todayWeekday == DateTime.monday) {
      todayDayName = "Monday";
      activeIndex = 0;
    }

    // Dynamic rotation: loads today first, tomorrow next, etc.
    List<Workout> rotatedPlan = [];
    if (workouts.isNotEmpty) {
      rotatedPlan = [
        ...workouts.sublist(activeIndex % workouts.length),
        ...workouts.sublist(0, activeIndex % workouts.length),
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      appBar: AppBar(
        title: Text(
          "MASTER BLUEPRINT",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 22,
            color: const Color(0xFFFF5E00),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.rotateLeft, size: 16, color: Colors.grey),
            tooltip: "Reset to Default Plan",
            onPressed: () => _showResetConfirmation(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: rotatedPlan.length,
            itemBuilder: (context, index) {
              final workout = rotatedPlan[index];
              return _buildWorkoutSection(context, workout, todayDayName);
            },
          ),
          if (isSwapping)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF007F)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "RESTRUCTURING BLUEPRINT...",
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFF007F),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "The Tank Coach is recalculating and distributing your weekly volume split...",
                        style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13, height: 1.4),
                        textAlign: TextAlign.center,
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

  Widget _buildWorkoutSection(BuildContext context, Workout workout, String todayDayName) {
    final isToday = workout.day == todayDayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? const [Color(0xFF00E5FF), Color(0xFF0083B0)] // Cyan for today
                        : const [Color(0xFFFF007F), Color(0xFFFF5E00)], // Pink/orange otherwise
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  workout.day.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                  ),
                  child: Text(
                    "TODAY",
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00E5FF),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isToday ? const Color(0xFF00E5FF) : const Color(0xFFFF5E00),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
              if (workout.exercises.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(FontAwesomeIcons.calendarMinus, size: 11),
                  label: Text(
                    "MISSED",
                    style: GoogleFonts.orbitron(fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showMissedDayConfirmation(context, workout.day),
                ),
            ],
          ),
        ),
        Text(
          workout.title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (workout.notes != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Text(
              workout.notes!,
              style: GoogleFonts.outfit(
                color: Colors.grey[500],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ...workout.exercises.map((e) => ExerciseCard(exercise: e, dayName: workout.day)),
        const SizedBox(height: 14),
      ],
    );
  }
}

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final String dayName;

  const ExerciseCard({super.key, required this.exercise, required this.dayName});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _localSwapping = false;

  Future<void> _launchYouTubeSearch(String exerciseName) async {
    final query = Uri.encodeComponent("how to do $exerciseName perfect form");
    final url = Uri.parse("https://www.youtube.com/results?search_query=$query");
    try {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (e) {
      debugPrint("Error launching YouTube search: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final isCompleted = context.select<FitnessProvider, bool>(
      (provider) => provider.completedExercises.contains(exercise.name),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF11121A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00E5FF).withOpacity(0.4) // cyan border when completed
              : _isExpanded
                  ? const Color(0xFFFF007F).withOpacity(0.5) // pink border when expanded
                  : const Color(0xFF232533),
          width: (_isExpanded || isCompleted) ? 1.5 : 1.0,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: (isCompleted ? const Color(0xFF00E5FF) : const Color(0xFFFF007F)).withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header (Always Visible)
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Completion Check Button
                    GestureDetector(
                      onTap: () {
                        context.read<FitnessProvider>().toggleExerciseCompletion(exercise.name);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFF00E5FF).withOpacity(0.12) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? const Color(0xFF00E5FF) : const Color(0xFF232533),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          FontAwesomeIcons.check,
                          color: isCompleted ? const Color(0xFF00E5FF) : Colors.transparent,
                          size: 10,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name.toUpperCase(),
                            style: GoogleFonts.orbitron(
                              color: isCompleted ? Colors.grey[500] : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(FontAwesomeIcons.bullseye, color: Color(0xFFFF5E00), size: 10),
                              const SizedBox(width: 6),
                              Text(
                                exercise.muscleFocus.toUpperCase(),
                                style: GoogleFonts.orbitron(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (isCompleted) ...[
                            const SizedBox(height: 6),
                            Text(
                              "🔥 ${context.read<FitnessProvider>().getCaloriesBurnedForExercise(exercise).toStringAsFixed(0)} KCAL BURNED",
                              style: GoogleFonts.orbitron(
                                color: const Color(0xFF00E5FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF00E5FF).withOpacity(0.04)
                                : const Color(0xFFFF007F).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF00E5FF).withOpacity(0.2)
                                  : const Color(0xFFFF007F).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            isCompleted ? "DONE" : "${exercise.sets} × ${exercise.reps}",
                            style: GoogleFonts.robotoMono(
                              color: isCompleted ? const Color(0xFF00E5FF) : const Color(0xFFFF007F),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                          color: _isExpanded ? const Color(0xFFFF007F) : Colors.grey[600],
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expandable details with AnimatedCrossFade for smooth transitions
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Display
                  if (exercise.imageUrl != null)
                    Stack(
                      children: [
                        exercise.imageUrl!.startsWith('assets/')
                            ? Image.asset(
                                exercise.imageUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                cacheWidth: 500,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: const Color(0xFF1B1D2A),
                                  child: const Center(
                                    child: Icon(FontAwesomeIcons.dumbbell, color: Colors.grey, size: 40),
                                  ),
                                ),
                              )
                            : Image.network(
                                exercise.imageUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                cacheWidth: 500,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 180,
                                    color: const Color(0xFF1B1D2A),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF007F)),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: const Color(0xFF1B1D2A),
                                  child: const Center(
                                    child: Icon(FontAwesomeIcons.dumbbell, color: Colors.grey, size: 40),
                                  ),
                                ),
                              ),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "INSTRUCTIONS",
                          style: GoogleFonts.orbitron(
                            color: Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          exercise.description,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[300],
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF007F).withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF007F).withOpacity(0.2),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(FontAwesomeIcons.lightbulb, color: Color(0xFFFF007F), size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "THE WHY: ${exercise.why}",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF007F).withOpacity(0.9),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildHighScoreSection(context, exercise),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: const Color(0xFF00E5FF),
                                ),
                                icon: const Icon(FontAwesomeIcons.circlePlay, size: 14),
                                label: Text(
                                  "WATCH FORM",
                                  style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                onPressed: () => _launchYouTubeSearch(exercise.name),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _localSwapping
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF007F)),
                                        ),
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: const Color(0xFFFF007F).withOpacity(0.4), width: 1.2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        foregroundColor: const Color(0xFFFF007F),
                                      ),
                                      icon: const Icon(FontAwesomeIcons.wandMagicSparkles, size: 14),
                                      label: Text(
                                        "AI SWAP",
                                        style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                                      onPressed: () async {
                                        setState(() => _localSwapping = true);
                                        await context.read<FitnessProvider>().swapExerciseWithAI(widget.dayName, exercise.name);
                                        if (mounted) setState(() => _localSwapping = false);
                                      },
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: const Color(0xFFFF5E00).withOpacity(0.4), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: const Color(0xFFFF5E00),
                                ),
                                icon: const Icon(FontAwesomeIcons.listCheck, size: 14),
                                label: Text(
                                  "MANUAL SWAP",
                                  style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                onPressed: () => _showManualSwapDialog(context, exercise),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighScoreSection(BuildContext context, Exercise exercise) {
    final isTimeBased = exercise.muscleFocus.toLowerCase().contains("cardio") || 
                        exercise.name.toLowerCase().contains("swimming") || 
                        exercise.name.toLowerCase().contains("sprint") || 
                        exercise.reps.contains("min");

    final String recordText = isTimeBased
        ? (exercise.highscoreTime ?? "No time set")
        : (exercise.highscoreWeight != null ? "${exercise.highscoreWeight} kg" : "No weight set");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.trophy, color: Color(0xFF00E5FF), size: 14),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTimeBased ? "BEST TIME RECORD" : "PERSONAL RECORD (PR)",
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00E5FF).withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recordText,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.12),
              foregroundColor: const Color(0xFF00E5FF),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
            ),
            onPressed: () => _showUpdateHighScoreDialog(context, exercise, isTimeBased),
            child: Text(
              "UPDATE",
              style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateHighScoreDialog(BuildContext context, Exercise exercise, bool isTimeBased) {
    final controller = TextEditingController(
      text: isTimeBased
          ? (exercise.highscoreTime ?? "")
          : (exercise.highscoreWeight?.toString() ?? ""),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: Text(
          isTimeBased ? "UPDATE BEST TIME" : "UPDATE PR WEIGHT",
          style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTimeBased
                  ? "Enter your best time duration (e.g. 12 mins, 45s, or 02:15):"
                  : "Enter your heaviest weight lifted in kg:",
              style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: isTimeBased ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(color: Colors.white),
              cursorColor: const Color(0xFF00E5FF),
              decoration: InputDecoration(
                hintText: isTimeBased ? "e.g. 10:15" : "e.g. 85.0",
                hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("CANCEL", style: GoogleFonts.orbitron(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(
              "SAVE",
              style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (isTimeBased) {
                context.read<FitnessProvider>().updateExerciseHighScore(
                  exercise.name,
                  null,
                  val.isEmpty ? null : val,
                );
              } else {
                final weight = double.tryParse(val);
                context.read<FitnessProvider>().updateExerciseHighScore(
                  exercise.name,
                  weight,
                  null,
                );
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showManualSwapDialog(BuildContext context, Exercise oldExercise) {
    final provider = context.read<FitnessProvider>();
    final pool = provider.exercisePool;

    final isPush = ["Upper Chest", "Mid/Lower Chest", "Front Delts", "Side Delts (Shoulders)", "Triceps", "Chest / Triceps", "Lower Chest / Triceps", "Triceps (Long Head)"].contains(oldExercise.muscleFocus);
    final isPull = ["Lats (Back Width)", "Mid-Back (Thickness)", "Rear Delts / Posture", "Biceps (Long Head)", "Biceps", "Lats / Back", "Lats / Mid-Back", "Brachialis (Arm Width)"].contains(oldExercise.muscleFocus);
    final isLegs = ["Quads / Glutes", "Hamstrings / Glutes", "Calves"].contains(oldExercise.muscleFocus);
    final isCardio = ["Full Body / Cardio"].contains(oldExercise.muscleFocus);
    final isCoreAbs = ["Lower Abs", "Core Stability"].contains(oldExercise.muscleFocus);

    final List<Exercise> candidates = pool.where((candidate) {
      if (candidate.name == oldExercise.name) return false;
      
      final workout = provider.plan.firstWhere((w) => w.day == widget.dayName);
      if (workout.exercises.any((e) => e.name == candidate.name)) return false;

      if (isPush) {
        return ["Upper Chest", "Mid/Lower Chest", "Front Delts", "Side Delts (Shoulders)", "Triceps", "Chest / Triceps", "Lower Chest / Triceps", "Triceps (Long Head)"].contains(candidate.muscleFocus);
      } else if (isPull) {
        return ["Lats (Back Width)", "Mid-Back (Thickness)", "Rear Delts / Posture", "Biceps (Long Head)", "Biceps", "Lats / Back", "Lats / Mid-Back", "Brachialis (Arm Width)"].contains(candidate.muscleFocus);
      } else if (isLegs) {
        return ["Quads / Glutes", "Hamstrings / Glutes", "Calves"].contains(candidate.muscleFocus);
      } else if (isCardio) {
        return ["Full Body / Cardio"].contains(candidate.muscleFocus);
      } else if (isCoreAbs) {
        return ["Lower Abs", "Core Stability"].contains(candidate.muscleFocus);
      }
      return false;
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFF5E00), width: 1.2),
        ),
        title: Text(
          "SELECT REPLACEMENT",
          style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: candidates.isEmpty
              ? Text("No alternative exercises available.", style: GoogleFonts.outfit(color: Colors.grey))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: candidates.length,
                  separatorBuilder: (c, idx) => Divider(color: Colors.grey[850], height: 1),
                  itemBuilder: (context, index) {
                    final item = candidates[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item.imageUrl ?? "",
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey[900],
                            child: const Icon(Icons.fitness_center, color: Colors.grey, size: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item.muscleFocus,
                        style: GoogleFonts.outfit(color: const Color(0xFF00E5FF), fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                      onTap: () {
                        provider.replaceExerciseManually(widget.dayName, oldExercise.name, item);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            child: Text("CANCEL", style: GoogleFonts.orbitron(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
