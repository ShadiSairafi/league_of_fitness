import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static final PersistenceService instance = PersistenceService._init();
  static SharedPreferences? _prefs;

  PersistenceService._init();

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Activity Logs
  Future<void> logActivity(String type, double value, {String? note}) async {
    final p = await prefs;
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String key = 'logs_${type}_$today';
    
    List<String> logs = p.getStringList(key) ?? [];
    logs.add(jsonEncode({
      'value': value,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    await p.setStringList(key, logs);
  }

  Future<List<Map<String, dynamic>>> getDailyLogs(String type) async {
    final p = await prefs;
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String key = 'logs_${type}_$today';
    
    List<String> logs = p.getStringList(key) ?? [];
    return logs.map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
  }

  Future<void> deleteLastLog(String type) async {
    final p = await prefs;
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String key = 'logs_${type}_$today';
    
    List<String> logs = p.getStringList(key) ?? [];
    if (logs.isNotEmpty) {
      logs.removeLast();
      await p.setStringList(key, logs);
    }
  }

  // Weight History
  Future<void> logWeight(double weight) async {
    final p = await prefs;
    List<String> history = p.getStringList('weight_history') ?? [];
    history.add(jsonEncode({
      'weight': weight,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    await p.setStringList('weight_history', history);
  }

  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    final p = await prefs;
    List<String> history = p.getStringList('weight_history') ?? [];
    return history.map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
  }

  // Completed Exercises
  Future<void> saveCompletedExercises(List<String> completed) async {
    final p = await prefs;
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String key = 'completed_exercises_$today';
    await p.setStringList(key, completed);
  }

  Future<List<String>> getCompletedExercises() async {
    final p = await prefs;
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String key = 'completed_exercises_$today';
    return p.getStringList(key) ?? [];
  }

  // Workout Plan Persistence
  Future<void> saveWorkoutPlan(List<Map<String, dynamic>> planJsonList) async {
    final p = await prefs;
    await p.setString('custom_workout_plan', jsonEncode(planJsonList));
  }

  Future<List<Map<String, dynamic>>?> loadWorkoutPlan() async {
    final p = await prefs;
    final data = p.getString('custom_workout_plan');
    if (data == null) return null;
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return null;
    }
  }

  // Saved Recipes
  Future<void> saveRecipe(Map<String, dynamic> recipeJson) async {
    final p = await prefs;
    final String? rawList = p.getString('saved_recipes');
    List<dynamic> list = [];
    if (rawList != null) {
      try {
        list = jsonDecode(rawList) as List<dynamic>;
      } catch (e) {
        list = [];
      }
    }
    // Avoid duplicates by title
    list.removeWhere((item) => item['title'] == recipeJson['title']);
    list.add(recipeJson);
    await p.setString('saved_recipes', jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> loadSavedRecipes() async {
    final p = await prefs;
    final String? rawList = p.getString('saved_recipes');
    if (rawList == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(rawList);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteRecipe(String title) async {
    final p = await prefs;
    final String? rawList = p.getString('saved_recipes');
    if (rawList == null) return;
    try {
      List<dynamic> list = jsonDecode(rawList);
      list.removeWhere((item) => item['title'] == title);
      await p.setString('saved_recipes', jsonEncode(list));
    } catch (e) {
      // Ignored
    }
  }
}
