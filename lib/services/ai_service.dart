import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/fitness_data.dart';

class AICoachService {
  final String _apiKey;

  AICoachService(this._apiKey);

  Future<GenerateContentResponse> _generateWithFallback(List<Content> content) async {
    final List<String> models = [
      'gemini-3.1-flash-lite',
      'gemini-1.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-pro',
    ];
    
    Object? lastError;
    for (final modelName in models) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: _apiKey);
        final response = await model.generateContent(content);
        if (response.text != null) {
          return response;
        }
      } catch (e) {
        lastError = e;
        developer.log("Model $modelName failed, trying fallback...", error: e);
      }
    }
    throw lastError ?? Exception("All fallback generative models failed.");
  }

  Future<String> askGeneralPrompt(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ?? "";
    } catch (e) {
      developer.log("Error in askGeneralPrompt", error: e);
      return "";
    }
  }

  Future<Map<String, dynamic>> analyzeMeal(Uint8List imageBytes, String userNote) async {
    final prompt = """
Analyze this meal. User says: '$userNote'.
Estimate calories and protein (in grams). 
Provide a very brief description of what you see.
Respond ONLY in JSON format like this:
{
  "calories": 450,
  "protein": 35,
  "description": "Grilled chicken breast with steamed broccoli and brown rice."
}
""";

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      final response = await _generateWithFallback(content);
      final text = response.text;
      if (text == null) throw Exception("Empty response from AI");
      
      // Clean up JSON if AI adds markdown blocks
      final jsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(jsonString);
    } catch (e) {
      developer.log("Error analyzing meal", error: e);
      return {"error": "Could not analyze meal: $e"};
    }
  }

  Future<Map<String, dynamic>> analyzeMealText(String userPrompt) async {
    final prompt = """
You are an expert nutritionist. Analyze the food described by the user.
User description: "$userPrompt"
Estimate the nutritional values.
Return a JSON object containing:
- "calories": Estimated calories (integer)
- "protein": Estimated protein in grams (integer)
- "description": Brief description of the food (string)

Response must be valid JSON only. Do not include markdown code block syntax.
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      final text = response.text;
      if (text == null) throw Exception("Empty response from AI");
      final jsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(jsonString);
    } catch (e) {
      developer.log("Error analyzing meal text", error: e);
      return {"error": "Could not analyze text: $e"};
    }
  }

  Future<Map<String, dynamic>> refineMealLog({
    required String previousDescription,
    required int previousCalories,
    required int previousProtein,
    required String userFeedback,
  }) async {
    final prompt = """
You are an expert nutritionist. The user is refining a pending meal log.
Previously estimated meal:
- Description: "$previousDescription"
- Calories: $previousCalories kcal
- Protein: $previousProtein g

User feedback/corrections: "$userFeedback"

Recalculate and adjust the calories, protein, and description based on their feedback.
Return a JSON object containing the updated values:
- "calories": Updated calories (integer)
- "protein": Updated protein in grams (integer)
- "description": Updated description of the meal (string)

Response must be valid JSON only. Do not include markdown code block syntax.
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      final text = response.text;
      if (text == null) throw Exception("Empty response from AI");
      final jsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(jsonString);
    } catch (e) {
      developer.log("Error refining meal log", error: e);
      return {"error": "Could not refine meal: $e"};
    }
  }

  Future<String> askCoach({
    required String question,
    required UserProfile profile,
    required List<String> completedExercises,
    required List<String> personalBests,
    required double activeCaloriesBurned,
    required double bmr,
  }) async {
    final Map<String, dynamic> metrics = {
      "userSpecs": {
        "age": profile.age,
        "heightCm": profile.height,
        "weightKg": profile.currentWeight,
        "goalWeightKg": profile.targetWeight,
        "wristCircumferenceCm": profile.wristCircumference,
        "waistCircumferenceCm": profile.waistSize ?? 0,
        "bodyType": profile.bodyType,
        "boneDensity": profile.boneDensity
      },
      "biometricsToday": {
        "caloriesConsumedKcal": profile.caloriesConsumed,
        "calorieGoalKcal": profile.calorieGoal,
        "proteinConsumedGrams": profile.proteinConsumed,
        "proteinGoalGrams": profile.proteinGoal,
        "waterDrankMl": profile.waterDrankMl,
        "waterGoalMl": profile.waterGoal,
        "activeCaloriesBurnedKcal": activeCaloriesBurned.toInt(),
        "naturalBmrKcal": bmr.toInt()
      },
      "workoutHistory": {
        "completedExercisesToday": completedExercises,
        "exercisePersonalRecords": personalBests
      }
    };

    final prompt = """
You are 'The Tank Coach', a down-to-earth, funny, and direct gym coach who treats the user like an absolute unit.
You use casual gym slang (e.g. "grind", "beast", "unit", "heavy weight", "grunting", "V-Taper"), crack jokes, but you are ruthlessly helpful and practical.
Keep your answers brief, funny, and direct.

Here are the user metrics in a dense JSON payload:
${jsonEncode(metrics)}

Guidelines:
1. Provide advice that respects their body frame, height, age, bone density, and joints. Recommend modifications or callouts if they are pushing weights that are unsafe for their frame/wrist or joint safety limits.
2. Keep it funny, down-to-earth, and casual.

Answer the user's question, keeping the above stats and your persona in mind:
Question: $question
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ?? "Let's keep crushing it!";
    } catch (e) {
      developer.log("Error in askCoach", error: e);
      return "Coach is busy right now, but you should keep grinding!";
    }
  }

  Future<String> getDailyRecommendation({
    required UserProfile profile,
    required List<String> completedExercises,
    required List<String> personalBests,
    required double activeCaloriesBurned,
    required double bmr,
  }) async {
    final Map<String, dynamic> metrics = {
      "userSpecs": {
        "age": profile.age,
        "heightCm": profile.height,
        "weightKg": profile.currentWeight,
        "goalWeightKg": profile.targetWeight,
        "wristCircumferenceCm": profile.wristCircumference,
        "waistCircumferenceCm": profile.waistSize ?? 0,
        "bodyType": profile.bodyType,
        "boneDensity": profile.boneDensity
      },
      "biometricsToday": {
        "caloriesConsumedKcal": profile.caloriesConsumed,
        "calorieGoalKcal": profile.calorieGoal,
        "proteinConsumedGrams": profile.proteinConsumed,
        "proteinGoalGrams": profile.proteinGoal,
        "waterDrankMl": profile.waterDrankMl,
        "waterGoalMl": profile.waterGoal,
        "activeCaloriesBurnedKcal": activeCaloriesBurned.toInt(),
        "naturalBmrKcal": bmr.toInt()
      },
      "workoutHistory": {
        "completedExercisesToday": completedExercises,
        "exercisePersonalRecords": personalBests
      }
    };

    final prompt = """
You are 'The Tank Coach', a down-to-earth, funny, and direct gym coach.
Provide a highly personalized joint warning and recommendation of 2-3 sentences based on these user metrics in JSON:
${jsonEncode(metrics)}

Guidelines:
1. Joint warning: Since weight is ${profile.currentWeight} kg and height is ${profile.height} cm, emphasize joint safety (e.g. swimming/walking, avoiding high-impact jumping if weight is over 100kg or if bone density/joints are sensitive).
2. Look at their wrist size and body type when suggesting warning considerations for heavy lifts.
3. Under-hydrated? Call them out in a funny way if water is low.
4. Keep it funny, down-to-earth, and casual. Under no circumstances mention green colors or UI elements. Max 3 sentences total.
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ?? "Keep grinding. Stay hydrated and hit your macros!";
    } catch (e) {
      developer.log("Error in getDailyRecommendation", error: e);
      return "Keep grinding. Focus on joint-safe cardio and hit that protein goal!";
    }
  }

  Future<String> chooseReplacementExercise({
    required String currentExerciseName,
    required String muscleFocus,
    required List<String> availableOptions,
  }) async {
    final prompt = """
You are 'The Tank Coach', an elite gym trainer.
The user wants to replace the exercise '$currentExerciseName' (which targets '$muscleFocus').
Select the absolute best replacement exercise from this exact list of available options:
${availableOptions.join(', ')}

Your selection MUST be an exact match of one of the options in the list above. Respond ONLY with the name of the chosen exercise. Do not add any punctuation, intro, outro, or explanation.

Chosen exercise:
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      final selection = response.text?.trim() ?? "";
      return selection;
    } catch (e) {
      developer.log("Error in chooseReplacementExercise", error: e);
      return "";
    }
  }

  Future<String> reshuffleWorkoutPlan({
    required String missedDay,
    required String planJsonString,
  }) async {
    final prompt = """
You are 'The Tank Coach', a legendary gym trainer.
The user missed their workout on '$missedDay'.
Reshuffle the exercises from '$missedDay' and distribute them logically into the remaining days of this week's workout plan.
Here is the current workout plan in JSON format:
$planJsonString

Instructions:
1. The user's allowed training days are: Monday, Tuesday, Wednesday, Thursday, and Sunday.
2. Friday and Saturday are STRICT REST DAYS. Friday is strictly forbidden—do NOT place any exercises on Friday.
3. Sunday is a wildcard/emergency day: if a workout is missed, you should prefer shifting the missed day's exercises to Sunday or distribute them among Tuesday, Wednesday, Thursday, and Sunday.
4. Distribute the exercises from '$missedDay' to other appropriate days based on muscle focus (e.g. push to push, pull to pull, or distribute them evenly so no day is overloaded). The missed day itself ('$missedDay') should have its `exercises` array empty in the output.
5. You must maintain the exact same JSON format structure.
6. Output ONLY the resulting JSON array. Do not include markdown code block syntax (like ```json), and do not include any intro, outro, or explanations. Respond with just the raw JSON text.
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text?.trim() ?? "";
    } catch (e) {
      developer.log("Error in reshuffleWorkoutPlan", error: e);
      return "";
    }
  }

  Future<String> askChiefTank({
    required String userPrompt,
    List<Uint8List>? imagesBytes,
    required UserProfile profile,
  }) async {
    final metricsJson = {
      "weightKg": profile.currentWeight,
      "goalWeightKg": profile.targetWeight,
      "calorieGoal": profile.calorieGoal,
      "proteinGoal": profile.proteinGoal,
      "foodPreferencesAndDislikes": profile.foodBio
    };

    final prompt = """
You are 'Chief Tank', a specialized, down-to-earth, and legendary gym chef.
Your sole purpose is to take the ingredients sent in the photos (if provided) and the text instructions from the user, and design a recipe optimized for their diet.

User Specifications:
${jsonEncode(metricsJson)}

User inputs: "$userPrompt"

Instructions:
1. Design a recipe that is as LOW-CALORIE as possible, while being extremely TASTY, HIGH-PROTEIN, healthy, and easy to make.
2. Provide suggestions on how to substitute high-fat ingredients with low-calorie hacks.
3. CRITICAL: The user has specified their food likes/dislikes/allergies in 'foodPreferencesAndDislikes'. You MUST strictly respect this bio. Never include ingredients they dislike/hate or are allergic to, and incorporate their food preferences.
4. You must respond ONLY with a JSON object. Do not include markdown code block syntax (like ```json), and do not include any intro, outro, or explanations. Respond with just the raw JSON text.

The JSON format MUST be exactly:
{
  "title": "Recipe Name",
  "calories": 320,
  "protein": 42,
  "description": "Short description of why it fits their diet.",
  "ingredients": ["item 1", "item 2"],
  "instructions": ["step 1", "step 2"],
  "youtubeSearch": "search query for video guide"
}
""";

    final content = [
      Content.multi([
        TextPart(prompt),
        if (imagesBytes != null) ...imagesBytes.map((bytes) => DataPart('image/jpeg', bytes)),
      ])
    ];

    try {
      final response = await _generateWithFallback(content);
      final text = response.text;
      if (text == null) throw Exception("Empty response from Chef");
      return text.replaceAll('```json', '').replaceAll('```', '').trim();
    } catch (e) {
      developer.log("Error in askChiefTank", error: e);
      return "{\"error\": \"Chef Tank is busy preparing another meal. Please try again!\"}";
    }
  }

  Future<String> refineChefRecipe({
    required Map<String, dynamic> previousRecipe,
    required String userFeedback,
    required UserProfile profile,
  }) async {
    final metricsJson = {
      "weightKg": profile.currentWeight,
      "goalWeightKg": profile.targetWeight,
      "calorieGoal": profile.calorieGoal,
      "proteinGoal": profile.proteinGoal,
      "foodPreferencesAndDislikes": profile.foodBio
    };

    final prompt = """
You are 'Chief Tank', a specialized gym chef.
The user wants to edit/refine a previously generated recipe.

User Specifications:
${jsonEncode(metricsJson)}

Original Recipe Details:
${jsonEncode(previousRecipe)}

User refinement feedback: "$userFeedback"

Instructions:
1. Modify the recipe based on their feedback, making sure it stays as low-calorie, high-protein, delicious, and easy to make as possible.
2. If they request portion scaling or macro adjustments, recalculate the calories and protein accurately.
3. CRITICAL: The user has specified their food likes/dislikes/allergies in 'foodPreferencesAndDislikes'. You MUST strictly respect this bio. Never include ingredients they dislike/hate or are allergic to, and incorporate their food preferences.
4. You must respond ONLY with a JSON object. Do not include markdown code block syntax (like ```json), and do not include any intro, outro, or explanations. Respond with just the raw JSON text.

The JSON format MUST be exactly:
{
  "title": "Recipe Name",
  "calories": 320,
  "protein": 42,
  "description": "Short description of the adjustments.",
  "ingredients": ["item 1", "item 2"],
  "instructions": ["step 1", "step 2"],
  "youtubeSearch": "search query for video guide"
}
""";

    final content = [Content.text(prompt)];

    try {
      final response = await _generateWithFallback(content);
      final text = response.text;
      if (text == null) throw Exception("Empty response from Chef");
      return text.replaceAll('```json', '').replaceAll('```', '').trim();
    } catch (e) {
      developer.log("Error in refineChefRecipe", error: e);
      return "{\"error\": \"Chef Tank is busy refining your recipe. Please try again!\"}";
    }
  }
}
