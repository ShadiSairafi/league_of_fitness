import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/fitness_data.dart';
import '../services/persistence_service.dart';
import '../services/ai_service.dart';
import '../config.dart';

class FitnessProvider with ChangeNotifier {
  UserProfile _userProfile = UserProfile(
    currentWeight: 115.0,
    targetWeight: 85.0,
    height: 178,
    wristCircumference: 20.0,
  );

  List<Map<String, dynamic>> _savedRecipes = [];
  List<Map<String, dynamic>> get savedRecipes => _savedRecipes;

  final AICoachService _aiService = AICoachService(geminiApiKey);

  List<Map<String, dynamic>> _weightHistory = [];
  List<Map<String, dynamic>> get weightHistory => _weightHistory;

  Set<String> _completedExercises = {};
  Set<String> get completedExercises => _completedExercises;

  String _aiRecommendation = "Tap 'REFRESH' to generate your personalized AI warnings and status report...";
  bool _isLoadingRecommendation = false;

  String get aiRecommendation => _aiRecommendation;
  bool get isLoadingRecommendation => _isLoadingRecommendation;

  // Streak & Missed Day variables
  int _completedTodayAnimationId = 0;
  int get completedTodayAnimationId => _completedTodayAnimationId;

  int _streakCount = 0;
  int get streakCount => _streakCount;

  int _consecutiveMissedDays = 0;
  int get consecutiveMissedDays => _consecutiveMissedDays;

  String _lastStreakDate = "";
  String _lastCheckedDate = "";

  bool _showMissedDayAlert = false;
  bool get showMissedDayAlert => _showMissedDayAlert;
  String _missedDayAlertMsg = "";
  String get missedDayAlertMsg => _missedDayAlertMsg;

  // Calorie Burn History Logging
  Map<String, int> _calorieBurnHistory = {};
  Map<String, int> get calorieBurnHistory => _calorieBurnHistory;

  double get bmr {
    final weight = _userProfile.currentWeight;
    final height = _userProfile.height;
    final age = _userProfile.age;
    return (10 * weight) + (6.25 * height) - (5 * age) + 5;
  }

  double getCaloriesBurnedForExercise(Exercise exercise) {
    final weight = _userProfile.currentWeight;
    final sets = double.tryParse(exercise.sets) ?? 3.0;
    
    double reps = 10.0;
    final repStr = exercise.reps.toLowerCase();
    if (repStr.contains("sec")) {
      reps = (double.tryParse(repStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60.0) / 6.0;
    } else if (repStr.contains("laps")) {
      reps = 15.0;
    } else {
      reps = double.tryParse(repStr.split('-').first) ?? 10.0;
    }

    double met = 4.0;
    final focus = exercise.muscleFocus.toLowerCase();
    final name = exercise.name.toLowerCase();
    
    if (focus.contains("cardio") || name.contains("swimming") || name.contains("sprint")) {
      met = 8.0;
    } else if (focus.contains("quads") || focus.contains("legs") || focus.contains("hamstrings") || focus.contains("calves")) {
      met = 6.0;
    } else if (focus.contains("abs") || focus.contains("core")) {
      met = 3.5;
    }

    return weight * met * 0.0125 * sets * (reps / 10.0);
  }

  double get activeCaloriesBurnedToday {
    final String todayDay = _getTodayDayName();
    if (todayDay.isEmpty) return 0.0;
    final todayWorkout = _plan.firstWhere(
      (w) => w.day == todayDay,
      orElse: () => Workout(title: "", day: "", exercises: []),
    );
    double total = 0.0;
    for (final e in todayWorkout.exercises) {
      if (_completedExercises.contains(e.name)) {
        total += getCaloriesBurnedForExercise(e);
      }
    }
    return total;
  }

  int get completedExercisesCount => _completedExercises.length;

  String get progressRank {
    final count = completedExercisesCount;
    if (count < 10) return "IRON INITIATE";
    if (count < 30) return "BRONZE BEAST";
    if (count < 60) return "SILVER STRIDER";
    if (count < 100) return "GOLDEN UNIT";
    if (count < 200) return "TITANIUM TANK";
    return "DIAMOND OVERLORD";
  }

  String get streakRank {
    final count = _streakCount;
    if (count < 5) return "SPARK";
    if (count < 15) return "EMBER";
    if (count < 30) return "WILDFIRE";
    if (count < 60) return "SUPERNOVA";
    if (count < 90) return "COSMIC SINGULARITY";
    return "ZENITH ETERNAL";
  }

  String get progressBadgePath {
    final rank = progressRank;
    if (rank == "IRON INITIATE") return "assets/images/iron_initiate.jpg";
    if (rank == "BRONZE BEAST") return "assets/images/bronze_beast.jpg";
    if (rank == "SILVER STRIDER") return "assets/images/silver_stryder.jpg";
    if (rank == "GOLDEN UNIT") return "assets/images/golden_unit.jpg";
    if (rank == "TITANIUM TANK") return "assets/images/titanium_tank.jpg";
    return "assets/images/diamond_overlord.jpg";
  }

  String get streakBadgePath {
    final rank = streakRank;
    if (rank == "SPARK") return "assets/images/spark.jpg";
    if (rank == "EMBER") return "assets/images/ember.jpg";
    if (rank == "WILDFIRE") return "assets/images/wildfire.jpg";
    if (rank == "SUPERNOVA") return "assets/images/supernova.jpg";
    if (rank == "COSMIC SINGULARITY") return "assets/images/cosmic_singularity.jpg";
    return "assets/images/zenith_eternal.jpg";
  }

  double get progressRankProgress {
    final count = completedExercisesCount;
    if (count < 10) return count / 10.0;
    if (count < 30) return (count - 10) / 20.0;
    if (count < 60) return (count - 30) / 30.0;
    if (count < 100) return (count - 60) / 40.0;
    if (count < 200) return (count - 100) / 100.0;
    return 1.0;
  }

  double get streakRankProgress {
    final count = _streakCount;
    if (count < 5) return count / 5.0;
    if (count < 15) return (count - 5) / 10.0;
    if (count < 30) return (count - 15) / 15.0;
    if (count < 60) return (count - 30) / 30.0;
    if (count < 90) return (count - 60) / 30.0;
    return 1.0;
  }

  String get nextProgressRank {
    final count = completedExercisesCount;
    if (count < 10) return "BRONZE BEAST";
    if (count < 30) return "SILVER STRIDER";
    if (count < 60) return "GOLDEN UNIT";
    if (count < 100) return "TITANIUM TANK";
    if (count < 200) return "DIAMOND OVERLORD";
    return "MAX TIER";
  }

  String get nextStreakRank {
    final count = _streakCount;
    if (count < 5) return "EMBER";
    if (count < 15) return "WILDFIRE";
    if (count < 30) return "SUPERNOVA";
    if (count < 60) return "COSMIC SINGULARITY";
    if (count < 90) return "ZENITH ETERNAL";
    return "MAX TIER";
  }

  FitnessProvider() {
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserProfile();
    await _loadDailyStats();
    await _loadWeightHistory();
    await _loadCompletedExercises();
    await _loadCalorieBurnHistory();
    await _loadCustomWorkoutPlan();
    await _checkDailyStatus();
    await loadSavedRecipes();
    
    final prefs = await PersistenceService.instance.prefs;
    final cachedText = prefs.getString('ai_recommendation_text');
    final cachedDate = prefs.getString('ai_recommendation_date');
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (cachedText != null && cachedDate == todayStr) {
      _aiRecommendation = cachedText;
      notifyListeners();
    } else {
      await refreshRecommendation();
    }
  }

  Future<void> refreshStateOnForeground() async {
    await _checkDailyStatus();
    await _loadDailyStats();
    notifyListeners();
  }

  Future<void> _loadStreakData() async {
    final prefs = await PersistenceService.instance.prefs;
    _streakCount = prefs.getInt('streak_count') ?? 0;
    _consecutiveMissedDays = prefs.getInt('consecutive_missed') ?? 0;
    _lastStreakDate = prefs.getString('last_streak_date') ?? "";
    _lastCheckedDate = prefs.getString('last_checked_date') ?? "";
  }

  Future<void> _saveStreakData() async {
    final prefs = await PersistenceService.instance.prefs;
    await prefs.setInt('streak_count', _streakCount);
    await prefs.setInt('consecutive_missed', _consecutiveMissedDays);
    await prefs.setString('last_streak_date', _lastStreakDate);
    await prefs.setString('last_checked_date', _lastCheckedDate);
  }

  Future<void> _checkDailyStatus() async {
    await _loadStreakData();
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    if (_lastCheckedDate.isEmpty) {
      _lastCheckedDate = todayStr;
      await _saveStreakData();
      return;
    }

    if (_lastCheckedDate != todayStr) {
      final yesterday = now.subtract(const Duration(days: 1));
      final String yesterdayDayName = _getDayNameForDateTime(yesterday);

      if (yesterdayDayName.isNotEmpty) {
        final yesterdayWorkout = _plan.firstWhere(
          (w) => w.day == yesterdayDayName,
          orElse: () => Workout(title: "", day: "", exercises: []),
        );

        if (yesterdayWorkout.exercises.isNotEmpty) {
          final bool completedYesterday = yesterdayWorkout.exercises.every(
            (e) => _completedExercises.contains(e.name),
          );

          if (!completedYesterday) {
            _consecutiveMissedDays++;
            if (_consecutiveMissedDays >= 2) {
              _streakCount = 0;
            }
            _showMissedDayAlert = true;
            _missedDayAlertMsg = "WARNING: Missed yesterday's ($yesterdayDayName) training! The Tank Coach has adjusted your schedule.";
            await reshuffleWorkoutDay(yesterdayDayName);
          } else {
            _consecutiveMissedDays = 0;
          }
        }
      }
      _lastCheckedDate = todayStr;
      await _saveStreakData();
    }
  }

  String _getDayNameForDateTime(DateTime dt) {
    if (dt.weekday == DateTime.monday) return "Monday";
    if (dt.weekday == DateTime.tuesday) return "Tuesday";
    if (dt.weekday == DateTime.wednesday) return "Wednesday";
    if (dt.weekday == DateTime.thursday) return "Thursday";
    if (dt.weekday == DateTime.sunday) return "Sunday";
    return "";
  }

  void dismissMissedDayAlert() {
    _showMissedDayAlert = false;
    notifyListeners();
  }

  bool isTodayWorkoutCompleted() {
    final String todayDay = _getTodayDayName();
    if (todayDay.isEmpty) return false;
    final todayWorkout = _plan.firstWhere(
      (w) => w.day == todayDay,
      orElse: () => Workout(title: "", day: "", exercises: []),
    );
    if (todayWorkout.exercises.isEmpty) return false;
    return todayWorkout.exercises.every((e) => _completedExercises.contains(e.name));
  }

  String _getTodayDayName() {
    final weekday = DateTime.now().weekday;
    if (weekday == DateTime.monday) return "Monday";
    if (weekday == DateTime.tuesday) return "Tuesday";
    if (weekday == DateTime.wednesday) return "Wednesday";
    if (weekday == DateTime.thursday) return "Thursday";
    if (weekday == DateTime.sunday) return "Sunday";
    return "";
  }

  Future<void> _loadUserProfile() async {
    final prefs = await PersistenceService.instance.prefs;
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(profileJson);
        _userProfile = UserProfile.fromJson(decoded);
      } catch (e) {
        developer.log("Error loading user profile", error: e);
      }
    }
  }

  Future<void> saveUserProfile(UserProfile updated) async {
    _userProfile = updated;
    final prefs = await PersistenceService.instance.prefs;
    await prefs.setString('user_profile', jsonEncode(_userProfile.toJson()));
    notifyListeners();
  }

  Future<void> _loadCustomWorkoutPlan() async {
    final customPlan = await PersistenceService.instance.loadWorkoutPlan();
    _plan.clear();
    if (customPlan != null) {
      for (final workoutJson in customPlan) {
        _plan.add(Workout.fromJson(workoutJson));
      }
    } else {
      _plan.addAll(_copyDefaultPlan());
    }
    notifyListeners();
  }

  Future<void> _loadDailyStats() async {
    final calLogs = await PersistenceService.instance.getDailyLogs('calories');
    final protLogs = await PersistenceService.instance.getDailyLogs('protein');
    final waterLogs = await PersistenceService.instance.getDailyLogs('water');

    _userProfile.caloriesConsumed = calLogs.fold(0, (sum, item) => sum + (item['value'] as num).toInt());
    _userProfile.proteinConsumed = protLogs.fold(0, (sum, item) => sum + (item['value'] as num).toInt());
    _userProfile.waterDrankMl = waterLogs.fold(0, (sum, item) => sum + (item['value'] as num).toInt());
    
    notifyListeners();
  }

  Future<void> _loadWeightHistory() async {
    _weightHistory = await PersistenceService.instance.getWeightHistory();
    if (_weightHistory.isNotEmpty) {
      _userProfile.currentWeight = (_weightHistory.last['weight'] as num).toDouble();
    }
    notifyListeners();
  }

  Future<void> _loadCompletedExercises() async {
    final completed = await PersistenceService.instance.getCompletedExercises();
    _completedExercises = completed.toSet();
    notifyListeners();
  }

  Future<void> _loadCalorieBurnHistory() async {
    final prefs = await PersistenceService.instance.prefs;
    final historyJson = prefs.getString('calories_burned_history') ?? "{}";
    try {
      final Map<String, dynamic> decoded = jsonDecode(historyJson);
      _calorieBurnHistory = decoded.map((key, val) => MapEntry(key, val as int));
    } catch (_) {}
  }

  UserProfile get userProfile => _userProfile;

  Future<void> toggleExerciseCompletion(String exerciseName) async {
    final wasCompletedBefore = _completedExercises.contains(exerciseName);
    if (wasCompletedBefore) {
      _completedExercises.remove(exerciseName);
    } else {
      _completedExercises.add(exerciseName);
    }
    await PersistenceService.instance.saveCompletedExercises(_completedExercises.toList());
    
    if (!wasCompletedBefore && isTodayWorkoutCompleted()) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      if (_lastStreakDate != todayStr) {
        _streakCount++;
        _consecutiveMissedDays = 0;
        _lastStreakDate = todayStr;
        await _saveStreakData();
        _completedTodayAnimationId++;
      }
    }

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final activeBurn = activeCaloriesBurnedToday.toInt();
    _calorieBurnHistory[todayStr] = activeBurn;
    
    final prefs = await PersistenceService.instance.prefs;
    await prefs.setString('calories_burned_history', jsonEncode(_calorieBurnHistory));
    
    notifyListeners();
  }

  Future<void> updateExerciseHighScore(String exerciseName, double? weight, String? time) async {
    for (var workout in _plan) {
      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          exercise.highscoreWeight = weight;
          exercise.highscoreTime = time;
          break;
        }
      }
    }
    final jsonList = _plan.map((w) => w.toJson()).toList();
    await PersistenceService.instance.saveWorkoutPlan(jsonList);
    notifyListeners();
  }

  Future<void> refreshRecommendation() async {
    _isLoadingRecommendation = true;
    notifyListeners();
    try {
      final List<String> exercisePBs = [];
      for (var workout in _plan) {
        for (var exercise in workout.exercises) {
          if (exercise.highscoreWeight != null || exercise.highscoreTime != null) {
            final pbStr = exercise.highscoreWeight != null 
                ? "${exercise.highscoreWeight} kg" 
                : exercise.highscoreTime!;
            exercisePBs.add("${exercise.name}: PB is $pbStr");
          }
        }
      }

      final rec = await _aiService.getDailyRecommendation(
        profile: _userProfile,
        completedExercises: _completedExercises.toList(),
        personalBests: exercisePBs,
        activeCaloriesBurned: activeCaloriesBurnedToday,
        bmr: bmr,
      );
      _aiRecommendation = rec;

      final prefs = await PersistenceService.instance.prefs;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('ai_recommendation_text', rec);
      await prefs.setString('ai_recommendation_date', todayStr);
    } catch (e) {
      _aiRecommendation = "Failed to load recommendation. Make sure you are connected to the internet and click REFRESH to try again.";
    } finally {
      _isLoadingRecommendation = false;
      notifyListeners();
    }
  }

  Future<void> addCalories(int calories, {String? note}) async {
    await PersistenceService.instance.logActivity('calories', calories.toDouble(), note: note);
    _userProfile.caloriesConsumed += calories;
    notifyListeners();
  }

  Future<void> addProtein(int protein) async {
    await PersistenceService.instance.logActivity('protein', protein.toDouble());
    _userProfile.proteinConsumed += protein;
    notifyListeners();
  }

  Future<void> addWater(int ml) async {
    await PersistenceService.instance.logActivity('water', ml.toDouble());
    _userProfile.waterDrankMl += ml;
    notifyListeners();
  }

  Future<void> removeLastWater() async {
    await PersistenceService.instance.deleteLastLog('water');
    await _loadDailyStats();
  }

  Future<void> updateWeight(double weight) async {
    await PersistenceService.instance.logWeight(weight);
    _userProfile.currentWeight = weight;
    await _loadWeightHistory();
  }

  bool _isSwapping = false;
  bool get isSwapping => _isSwapping;

  // Pre-defined Workout Plan using Local Assets
  final List<Workout> _plan = [];

  List<Workout> _copyDefaultPlan() {
    return [
      Workout(
        day: "Monday",
        title: "Upper Body Push (Building the Armor)",
        notes: "This lifts and tightens the chest muscles underneath the fat.",
        exercises: [
          Exercise(
            name: "Incline Dumbbell Press",
            muscleFocus: "Upper Chest",
            description: "Lie on a bench at a 30-45 degree angle. Press dumbbells upwards.",
            sets: "4",
            reps: "8-12",
            why: "Crucial for the upper chest to create a masculine, squared look.",
            imageUrl: "assets/images/incline_dumbbell_press.jpg",
          ),
          Exercise(
            name: "Flat Machine Chest Press",
            muscleFocus: "Mid/Lower Chest",
            description: "Sit in the machine and press forward until arms are extended.",
            sets: "3",
            reps: "10",
            why: "Tightens the chest area as fat melts away.",
            imageUrl: "assets/images/flat_machine_chest_press.jpg",
          ),
          Exercise(
            name: "Seated Dumbbell Shoulder Press",
            muscleFocus: "Front Delts",
            description: "Sit with back supported, press dumbbells from shoulder height to overhead.",
            sets: "4",
            reps: "8-12",
            why: "Builds the vertical height of your frame.",
            imageUrl: "assets/images/seated_dumbbell_shoulder_press.jpg",
          ),
          Exercise(
            name: "Dumbbell Lateral Raises",
            muscleFocus: "Side Delts (Shoulders)",
            description: "Stand straight, lift dumbbells to your sides until arms are parallel to floor.",
            sets: "4",
            reps: "15",
            why: "This builds wide shoulders which makes your waist look smaller (V-Taper).",
            imageUrl: "assets/images/dumbbell_lateral_raises.jpg",
          ),
          Exercise(
            name: "Cable Tricep Pushdowns",
            muscleFocus: "Triceps",
            description: "Stand facing the cable station, push the bar down while keeping elbows tucked.",
            sets: "3",
            reps: "12-15",
            why: "Direct tricep training to build thick, powerful arms.",
            imageUrl: "assets/images/cable_tricep_pushdowns.jpg",
          ),
        ],
      ),
      Workout(
        day: "Tuesday",
        title: "Cardio Day (Fat Furnace)",
        notes: "Interval Cardio (HIIT) burns fat and boosts endurance.",
        exercises: [
          Exercise(
            name: "Sprint Laps",
            muscleFocus: "Full Body / Cardio",
            description: "Swim 1 or 2 laps as fast as possible.",
            sets: "10-15",
            reps: "Laps",
            why: "Zero-impact, incinerates calories without hurting joints.",
            imageUrl: "assets/images/sprint_laps.jpg",
          ),
        ],
      ),
      Workout(
        day: "Wednesday",
        title: "Upper Body Pull (Building the V-Taper)",
        notes: "A wide back pulls your posture upright and stretches your stomach flat.",
        exercises: [
          Exercise(
            name: "Lat Pulldowns (Wide Grip)",
            muscleFocus: "Lats (Back Width)",
            description: "Pull the bar down to your upper chest while leaning back slightly.",
            sets: "4",
            reps: "10",
            why: "The #1 exercise for creating that 'V' look.",
            imageUrl: "assets/images/lat_pulldowns.jpg",
          ),
          Exercise(
            name: "Seated Cable Rows",
            muscleFocus: "Mid-Back (Thickness)",
            description: "Pull the handle towards your waist while keeping your back straight.",
            sets: "4",
            reps: "10-12",
            why: "Builds a thick, powerful-looking back.",
            imageUrl: "assets/images/seated_cable_rows.jpg",
          ),
          Exercise(
            name: "Face Pulls",
            muscleFocus: "Rear Delts / Posture",
            description: "Pull the rope towards your forehead, pulling the ends apart.",
            sets: "3",
            reps: "15",
            why: "Crucial for fixing posture and pulling shoulders back.",
            imageUrl: "assets/images/face_pulls.jpg",
          ),
          Exercise(
            name: "Incline Dumbbell Curls",
            muscleFocus: "Biceps (Long Head)",
            description: "Sit on an incline bench, let arms hang, and curl dumbbells up.",
            sets: "3",
            reps: "10-12",
            why: "Places bicep under deep stretch for a massive peak.",
            imageUrl: "assets/images/incline_bicep_curls.jpg",
          ),
        ],
      ),
      Workout(
        day: "Thursday",
        title: "Hardcore Leg & Calf Destroyer",
        notes: "Power day for the lower unit to burn fat and build density.",
        exercises: [
          Exercise(
            name: "Goblet Squats",
            muscleFocus: "Quads / Glutes",
            description: "Hold a heavy dumbbell at chest height and squat deep.",
            sets: "4",
            reps: "10-12",
            why: "Heavy compound load to stimulate total body fat burn and quad size.",
            imageUrl: "assets/images/goblet_squats.jpg",
          ),
          Exercise(
            name: "Romanian Deadlifts",
            muscleFocus: "Hamstrings / Glutes",
            description: "Hold dumbbells, hinge at hips while keeping back straight, and lower weights down legs.",
            sets: "3",
            reps: "10-12",
            why: "Builds a powerful posterior chain to protect the lower back and knees.",
            imageUrl: "assets/images/romanian_deadlifts.jpg",
          ),
          Exercise(
            name: "Standing Calf Raises",
            muscleFocus: "Calves",
            description: "Stand on a ledge, lower heels, then push up through the balls of your feet.",
            sets: "4",
            reps: "15-20",
            why: "Builds dense lower legs to complete your lower body frame.",
            imageUrl: "assets/images/standing_calf_raises.jpg",
          ),
          Exercise(
            name: "Hanging Knee Raises",
            muscleFocus: "Lower Abs",
            description: "Hang from a bar and raise knees to chest, contracting the abs.",
            sets: "3",
            reps: "15",
            why: "Strengthens lower abs and hip flexors for better posture.",
            imageUrl: "assets/images/hanging_knee_raises.jpg",
          ),
        ],
      ),
      Workout(
        day: "Sunday",
        title: "Wildcard Training (Active Recovery)",
        notes: "Sunday is your flexibility day for catch-up sessions or extra recovery.",
        exercises: [],
      ),
    ];
  }

  final List<Exercise> _exercisePool = [
    // Chest / Push
    Exercise(
      name: "Incline Dumbbell Press",
      muscleFocus: "Upper Chest",
      description: "Lie on a bench at a 30-45 degree angle. Press dumbbells upwards.",
      sets: "4",
      reps: "8-12",
      why: "Crucial for the upper chest to create a masculine, squared look.",
      imageUrl: "assets/images/incline_dumbbell_press.jpg",
    ),
    Exercise(
      name: "Flat Machine Chest Press",
      muscleFocus: "Mid/Lower Chest",
      description: "Sit in the machine and press forward until arms are extended.",
      sets: "3",
      reps: "10",
      why: "Tightens the chest area as fat melts away.",
      imageUrl: "assets/images/flat_machine_chest_press.jpg",
    ),
    Exercise(
      name: "Cable Tricep Pushdowns",
      muscleFocus: "Triceps",
      description: "Stand facing the cable station, push the bar down while keeping elbows tucked.",
      sets: "3",
      reps: "12-15",
      why: "Direct tricep training to build thick, powerful arms.",
      imageUrl: "assets/images/cable_tricep_pushdowns.jpg",
    ),
    Exercise(
      name: "Pushups",
      muscleFocus: "Chest / Triceps",
      description: "Keep body in a straight line, lower chest to floor, and push back up.",
      sets: "3",
      reps: "Max reps",
      why: "Classic bodyweight builder for overall upper body control.",
      imageUrl: "assets/images/pushups.jpg",
    ),
    Exercise(
      name: "Dips",
      muscleFocus: "Lower Chest / Triceps",
      description: "Suspend body on parallel bars, lower down until elbows are at 90 degrees, push up.",
      sets: "3",
      reps: "8-10",
      why: "Unmatched builder for lower chest sweep and tricep power.",
      imageUrl: "assets/images/dips.jpg",
    ),
    Exercise(
      name: "Seated Dumbbell Shoulder Press",
      muscleFocus: "Front Delts",
      description: "Sit with back supported, press dumbbells from shoulder height to overhead.",
      sets: "4",
      reps: "8-12",
      why: "Builds the vertical height of your frame.",
      imageUrl: "assets/images/seated_dumbbell_shoulder_press.jpg",
    ),
    Exercise(
      name: "Dumbbell Lateral Raises",
      muscleFocus: "Side Delts (Shoulders)",
      description: "Stand straight, lift dumbbells to your sides until arms are parallel to floor.",
      sets: "4",
      reps: "15",
      why: "This builds wide shoulders which makes your waist look smaller (V-Taper).",
      imageUrl: "assets/images/dumbbell_lateral_raises.jpg",
    ),
    Exercise(
      name: "Overhead Tricep Extension",
      muscleFocus: "Triceps (Long Head)",
      description: "Hold a dumbbell overhead with both hands, lower it behind your head, and extend up.",
      sets: "3",
      reps: "12",
      why: "Targets the long head of the triceps for maximum arm thickness.",
      imageUrl: "assets/images/tricep_overhead.jpg",
    ),

    // Back / Pull
    Exercise(
      name: "Lat Pulldowns (Wide Grip)",
      muscleFocus: "Lats (Back Width)",
      description: "Pull the bar down to your upper chest while leaning back slightly.",
      sets: "4",
      reps: "10",
      why: "The #1 exercise for creating that 'V' look.",
      imageUrl: "assets/images/lat_pulldowns.jpg",
    ),
    Exercise(
      name: "Seated Cable Rows",
      muscleFocus: "Mid-Back (Thickness)",
      description: "Pull the handle towards your waist while keeping your back straight.",
      sets: "4",
      reps: "10-12",
      why: "Builds a thick, powerful-looking back.",
      imageUrl: "assets/images/seated_cable_rows.jpg",
    ),
    Exercise(
      name: "Face Pulls",
      muscleFocus: "Rear Delts / Posture",
      description: "Pull the rope towards your forehead, pulling the ends apart.",
      sets: "3",
      reps: "15",
      why: "Crucial for fixing posture and pulling shoulders back.",
      imageUrl: "assets/images/face_pulls.jpg",
    ),
    Exercise(
      name: "Incline Dumbbell Curls",
      muscleFocus: "Biceps (Long Head)",
      description: "Sit on an incline bench, let arms hang, and curl dumbbells up.",
      sets: "3",
      reps: "10-12",
      why: "Places bicep under deep stretch for a massive peak.",
      imageUrl: "assets/images/incline_bicep_curls.jpg",
    ),
    Exercise(
      name: "Standing Dumbbell Curls",
      muscleFocus: "Biceps",
      description: "Stand straight, curl dumbbells up while supinating wrists.",
      sets: "3",
      reps: "12",
      why: "Core bicep builder for front arm thickness.",
      imageUrl: "assets/images/dumbbell_curls.jpg",
    ),
    Exercise(
      name: "Pullups",
      muscleFocus: "Lats / Back",
      description: "Hang from a bar with palms facing away, pull chest to bar.",
      sets: "3",
      reps: "Max reps",
      why: "The ultimate test of upper body relative strength.",
      imageUrl: "assets/images/pullups.jpg",
    ),
    Exercise(
      name: "One-Arm Dumbbell Rows",
      muscleFocus: "Lats / Mid-Back",
      description: "Support knee and hand on bench, pull dumbbell to hip.",
      sets: "3",
      reps: "10",
      why: "Allows unilateral focus to correct back strength imbalances.",
      imageUrl: "assets/images/dumbbell_row.jpg",
    ),
    Exercise(
      name: "Hammer Curls",
      muscleFocus: "Brachialis (Arm Width)",
      description: "Stand and curl dumbbells with palms facing each other (neutral grip).",
      sets: "3",
      reps: "12",
      why: "Builds the side-arm muscle that pushes biceps out for width.",
      imageUrl: "assets/images/hammer_curls.jpg",
    ),

    // Legs / Core
    Exercise(
      name: "Goblet Squats",
      muscleFocus: "Quads / Glutes",
      description: "Hold a dumbbell at chest height and squat down deep.",
      sets: "3",
      reps: "12-15",
      why: "Keeps your 'tree trunk' legs powerful but conditioned.",
      imageUrl: "assets/images/goblet_squats.jpg",
    ),
    Exercise(
      name: "Hanging Knee Raises",
      muscleFocus: "Lower Abs",
      description: "Hang from a bar and pull your knees to your chest.",
      sets: "3",
      reps: "15",
      why: "Starts building the ab wall as belly fat disappears.",
      imageUrl: "assets/images/hanging_knee_raises.jpg",
    ),
    Exercise(
      name: "Romanian Deadlifts",
      muscleFocus: "Hamstrings / Glutes",
      description: "Hinge at hips, lower dumbbells down shins, feel stretch in hamstrings, return upright.",
      sets: "3",
      reps: "10-12",
      why: "Builds posterior chain strength without spinal compression.",
      imageUrl: "assets/images/romanian_deadlifts.jpg",
    ),
    Exercise(
      name: "Plank",
      muscleFocus: "Core Stability",
      description: "Hold body straight on forearms and toes, squeezing glutes and abs.",
      sets: "3",
      reps: "60 sec",
      why: "Isometric core builder to tighten abdominal wall.",
      imageUrl: "assets/images/plank.jpg",
    ),
    Exercise(
      name: "Lying Leg Raises",
      muscleFocus: "Lower Abs",
      description: "Lie flat, raise legs straight up to 90 degrees, lower slowly without touching floor.",
      sets: "3",
      reps: "15",
      why: "Direct lower ab activation, easy on back when hips supported.",
      imageUrl: "assets/images/leg_raises.jpg",
    ),
    Exercise(
      name: "Sprint Laps",
      muscleFocus: "Full Body / Cardio",
      description: "Swim 1 or 2 laps as fast as possible.",
      sets: "10-15",
      reps: "Laps",
      why: "Zero-impact, incinerates calories without hurting joints.",
      imageUrl: "assets/images/sprint_laps.jpg",
    ),
    Exercise(
      name: "Standing Calf Raises",
      muscleFocus: "Calves",
      description: "Stand on a ledge, lower heels, then push up through the balls of your feet.",
      sets: "4",
      reps: "15-20",
      why: "Builds dense lower legs to complete your lower body frame.",
      imageUrl: "assets/images/standing_calf_raises.jpg",
    ),
    // New Legs Backups
    Exercise(
      name: "Leg Press",
      muscleFocus: "Quads / Glutes",
      description: "Sit in the leg press machine, place feet on platform, lower it slowly, and press back up.",
      sets: "3",
      reps: "10-12",
      why: "Safely compounds quadriceps and glutes load without spinal compression.",
      imageUrl: "assets/images/leg_press.jpg",
    ),
    Exercise(
      name: "Leg Extensions",
      muscleFocus: "Quads / Glutes",
      description: "Sit on the machine, slide ankles under rollers, and extend legs fully.",
      sets: "3",
      reps: "12-15",
      why: "Isolates the quadriceps for muscle definition.",
      imageUrl: "assets/images/leg_extensions.jpg",
    ),
    Exercise(
      name: "Lying Leg Curls",
      muscleFocus: "Hamstrings / Glutes",
      description: "Lie face down, place back of ankles under pad, and curl heels to glutes.",
      sets: "3",
      reps: "12-15",
      why: "Direct hamstring builder to balance knee joint integrity.",
      imageUrl: "assets/images/leg_curls.jpg",
    ),

    // New Cardio Backups
    Exercise(
      name: "Stationary Cycling",
      muscleFocus: "Full Body / Cardio",
      description: "Pedal at a moderate to high intensity on a stationary bike.",
      sets: "20-30 mins",
      reps: "Cardio",
      why: "Improves cardiovascular recovery with zero impact.",
      imageUrl: "assets/images/cycling.jpg",
    ),
    Exercise(
      name: "Rowing Machine",
      muscleFocus: "Full Body / Cardio",
      description: "Pull the handle to chest while pushing off with legs in a fluid stroke.",
      sets: "10-15 mins",
      reps: "Cardio",
      why: "High-intensity cardio that builds back pulling power.",
      imageUrl: "assets/images/rowing.jpg",
    ),
    Exercise(
      name: "Elliptical Trainer",
      muscleFocus: "Full Body / Cardio",
      description: "Stand on foot pedals, grip handles, and stride in a smooth running motion.",
      sets: "20 mins",
      reps: "Cardio",
      why: "Great calorie burner that keeps joints safe.",
      imageUrl: "assets/images/elliptical.jpg",
    ),
    Exercise(
      name: "Shadow Boxing",
      muscleFocus: "Full Body / Cardio",
      description: "Throw boxing punches in the air while constantly moving on your feet.",
      sets: "5 rounds",
      reps: "3 mins",
      why: "Engaging cardio that builds speed, shoulders, and core agility.",
      imageUrl: "assets/images/shadow_boxing.jpg",
    ),

    // New Abs/Core Backups
    Exercise(
      name: "Ab Wheel Rollouts",
      muscleFocus: "Core Stability",
      description: "Kneel on the floor, roll the ab wheel forward slowly, and squeeze core to return.",
      sets: "3",
      reps: "8-12",
      why: "Advanced core builder that tightens the entire abdominal wall.",
      imageUrl: "assets/images/ab_wheel.jpg",
    ),
    Exercise(
      name: "Russian Twists",
      muscleFocus: "Lower Abs",
      description: "Sit on floor, lean back slightly with knees bent, and rotate torso side to side.",
      sets: "3",
      reps: "20",
      why: "Activates obliques and strengthens abdominal rotation control.",
      imageUrl: "assets/images/russian_twists.jpg",
    ),
  ];

  List<Workout> get plan => _plan;
  List<Exercise> get exercisePool => _exercisePool;

  Future<void> replaceExerciseManually(String dayName, String oldExerciseName, Exercise newExercise) async {
    try {
      final workout = _plan.firstWhere((w) => w.day == dayName);
      final idx = workout.exercises.indexWhere((e) => e.name == oldExerciseName);
      if (idx != -1) {
        workout.exercises[idx] = newExercise;
        await PersistenceService.instance.saveWorkoutPlan(
          _plan.map((w) => w.toJson()).toList()
        );
        if (_completedExercises.contains(oldExerciseName)) {
          _completedExercises.remove(oldExerciseName);
          await PersistenceService.instance.saveCompletedExercises(_completedExercises.toList());
        }
        notifyListeners();
        refreshRecommendation();
      }
    } catch (e) {
      debugPrint("Error replacing exercise manually: $e");
    }
  }

  Future<void> swapExerciseWithAI(String dayName, String oldExerciseName) async {
    _isSwapping = true;
    notifyListeners();

    try {
      final workout = _plan.firstWhere((w) => w.day == dayName);
      final oldExerciseIndex = workout.exercises.indexWhere((e) => e.name == oldExerciseName);
      if (oldExerciseIndex == -1) return;

      final oldExercise = workout.exercises[oldExerciseIndex];

      final isPush = ["Upper Chest", "Mid/Lower Chest", "Front Delts", "Side Delts (Shoulders)", "Triceps", "Chest / Triceps", "Lower Chest / Triceps", "Triceps (Long Head)"].contains(oldExercise.muscleFocus);
      final isPull = ["Lats (Back Width)", "Mid-Back (Thickness)", "Rear Delts / Posture", "Biceps (Long Head)", "Biceps", "Lats / Back", "Lats / Mid-Back", "Brachialis (Arm Width)"].contains(oldExercise.muscleFocus);

      final List<Exercise> candidates = _exercisePool.where((candidate) {
        if (candidate.name == oldExerciseName) return false;
        if (workout.exercises.any((e) => e.name == candidate.name)) return false;
        
        if (isPush) {
          return ["Upper Chest", "Mid/Lower Chest", "Front Delts", "Side Delts (Shoulders)", "Triceps", "Chest / Triceps", "Lower Chest / Triceps", "Triceps (Long Head)"].contains(candidate.muscleFocus);
        } else if (isPull) {
          return ["Lats (Back Width)", "Mid-Back (Thickness)", "Rear Delts / Posture", "Biceps (Long Head)", "Biceps", "Lats / Back", "Lats / Mid-Back", "Brachialis (Arm Width)"].contains(candidate.muscleFocus);
        } else {
          return ["Quads / Glutes", "Lower Abs", "Full Body / Cardio", "Hamstrings / Glutes", "Core Stability"].contains(candidate.muscleFocus);
        }
      }).toList();

      if (candidates.isEmpty) return;

      final candidateNames = candidates.map((c) => c.name).toList();

      final String chosenName = await _aiService.chooseReplacementExercise(
        currentExerciseName: oldExerciseName,
        muscleFocus: oldExercise.muscleFocus,
        availableOptions: candidateNames,
      );

      final replacement = _exercisePool.firstWhere(
        (c) => c.name.toLowerCase() == chosenName.toLowerCase(),
        orElse: () => candidates.first, 
      );

      workout.exercises[oldExerciseIndex] = replacement;
      
      // Save custom plan to local storage
      await PersistenceService.instance.saveWorkoutPlan(
        _plan.map((w) => w.toJson()).toList()
      );

      if (_completedExercises.contains(oldExerciseName)) {
        _completedExercises.remove(oldExerciseName);
        await PersistenceService.instance.saveCompletedExercises(_completedExercises.toList());
      }
      
      notifyListeners();
      refreshRecommendation();
    } catch (e) {
      // Fail silently
    } finally {
      _isSwapping = false;
      notifyListeners();
    }
  }

  Future<void> reshuffleWorkoutDay(String dayName) async {
    _isSwapping = true;
    notifyListeners();

    try {
      final planJsonList = _plan.map((w) => w.toJson()).toList();
      final planJsonString = jsonEncode(planJsonList);

      final String reshuffledString = await _aiService.reshuffleWorkoutPlan(
        missedDay: dayName,
        planJsonString: planJsonString,
      );

      var cleanJson = reshuffledString.trim();
      if (cleanJson.startsWith("```")) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```json\s*'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'^```\s*'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'\s*```$'), '');
      }

      final List<dynamic> decodedList = jsonDecode(cleanJson) as List<dynamic>;
      
      _plan.clear();
      for (final workoutJson in decodedList) {
        _plan.add(Workout.fromJson(workoutJson as Map<String, dynamic>));
      }

      // Save customized plan
      await PersistenceService.instance.saveWorkoutPlan(
        _plan.map((w) => w.toJson()).toList()
      );

      // Reset today's completions
      _completedExercises.clear();
      await PersistenceService.instance.saveCompletedExercises([]);

      notifyListeners();
      refreshRecommendation();
    } catch (e) {
      developer.log("Error in reshuffleWorkoutDay", error: e);
    } finally {
      _isSwapping = false;
      notifyListeners();
    }
  }

  Future<void> resetWorkoutPlan() async {
    _isSwapping = true;
    notifyListeners();
    try {
      final p = await PersistenceService.instance.prefs;
      await p.remove('custom_workout_plan');

      _plan.clear();
      _plan.addAll(_copyDefaultPlan());

      _completedExercises.clear();
      await PersistenceService.instance.saveCompletedExercises([]);

      notifyListeners();
      refreshRecommendation();
    } catch (e) {
      // Fail silently
    } finally {
      _isSwapping = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedRecipes() async {
    _savedRecipes = await PersistenceService.instance.loadSavedRecipes();
    notifyListeners();
  }

  Future<void> saveRecipe(Map<String, dynamic> recipe) async {
    await PersistenceService.instance.saveRecipe(recipe);
    await loadSavedRecipes();
  }

  Future<void> deleteRecipe(String title) async {
    await PersistenceService.instance.deleteRecipe(title);
    await loadSavedRecipes();
  }

  Future<void> quickLogRecipeMacros(int calories, int protein, String title) async {
    await addCalories(calories, note: title);
    await addProtein(protein);
    notifyListeners();
  }

  Future<Map<String, dynamic>> refineSavedRecipe(Map<String, dynamic> previousRecipe, String feedback) async {
    final service = AICoachService(geminiApiKey);
    final responseText = await service.refineChefRecipe(
      previousRecipe: previousRecipe,
      userFeedback: feedback,
      profile: _userProfile,
    );
    final Map<String, dynamic> parsed = jsonDecode(responseText);
    if (!parsed.containsKey('error')) {
      await deleteRecipe(previousRecipe['title']);
      await saveRecipe(parsed);
    }
    return parsed;
  }
}
