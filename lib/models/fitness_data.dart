class Exercise {
  final String name;
  final String muscleFocus;
  final String description;
  final String sets;
  final String reps;
  final String why;
  final String? imageUrl;
  
  // High scores/Personal records
  double? highscoreWeight; // e.g. 85.5 kg
  String? highscoreTime;   // e.g. "12:45" or "30s"

  Exercise({
    required this.name,
    required this.muscleFocus,
    required this.description,
    required this.sets,
    required this.reps,
    required this.why,
    this.imageUrl,
    this.highscoreWeight,
    this.highscoreTime,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'muscleFocus': muscleFocus,
    'description': description,
    'sets': sets,
    'reps': reps,
    'why': why,
    'imageUrl': imageUrl,
    'highscoreWeight': highscoreWeight,
    'highscoreTime': highscoreTime,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    name: json['name'] as String,
    muscleFocus: json['muscleFocus'] as String,
    description: json['description'] as String,
    sets: json['sets'] as String,
    reps: json['reps'] as String,
    why: json['why'] as String,
    imageUrl: json['imageUrl'] as String?,
    highscoreWeight: json['highscoreWeight'] != null ? (json['highscoreWeight'] as num).toDouble() : null,
    highscoreTime: json['highscoreTime'] as String?,
  );
}

class Workout {
  final String title;
  final String day;
  final List<Exercise> exercises;
  final String? notes;

  Workout({
    required this.title,
    required this.day,
    required this.exercises,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'day': day,
    'notes': notes,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    title: json['title'] as String,
    day: json['day'] as String,
    notes: json['notes'] as String?,
    exercises: (json['exercises'] as List<dynamic>)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class UserProfile {
  double currentWeight;
  double targetWeight;
  int height;
  double wristCircumference;
  int age;
  double? waistSize;
  String bodyType;
  String boneDensity;
  String foodBio;

  int caloriesConsumed;
  int proteinConsumed;
  int waterDrankMl;

  UserProfile({
    required this.currentWeight,
    required this.targetWeight,
    required this.height,
    required this.wristCircumference,
    this.age = 30,
    this.waistSize,
    this.bodyType = "Mesomorph",
    this.boneDensity = "Normal",
    this.caloriesConsumed = 0,
    this.proteinConsumed = 0,
    this.waterDrankMl = 0,
    this.foodBio = "",
  });

  Map<String, dynamic> toJson() => {
    'currentWeight': currentWeight,
    'targetWeight': targetWeight,
    'height': height,
    'wristCircumference': wristCircumference,
    'age': age,
    'waistSize': waistSize,
    'bodyType': bodyType,
    'boneDensity': boneDensity,
    'caloriesConsumed': caloriesConsumed,
    'proteinConsumed': proteinConsumed,
    'waterDrankMl': waterDrankMl,
    'foodBio': foodBio,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    currentWeight: (json['currentWeight'] as num).toDouble(),
    targetWeight: (json['targetWeight'] as num).toDouble(),
    height: (json['height'] as num).toInt(),
    wristCircumference: (json['wristCircumference'] as num).toDouble(),
    age: json['age'] != null ? (json['age'] as num).toInt() : 30,
    waistSize: json['waistSize'] != null ? (json['waistSize'] as num).toDouble() : null,
    bodyType: json['bodyType'] as String? ?? "Mesomorph",
    boneDensity: json['boneDensity'] as String? ?? "Normal",
    caloriesConsumed: json['caloriesConsumed'] != null ? (json['caloriesConsumed'] as num).toInt() : 0,
    proteinConsumed: json['proteinConsumed'] != null ? (json['proteinConsumed'] as num).toInt() : 0,
    waterDrankMl: json['waterDrankMl'] != null ? (json['waterDrankMl'] as num).toInt() : 0,
    foodBio: json['foodBio'] as String? ?? "",
  );

  int get calorieGoal => 2250;
  int get proteinGoal => 175;
  int get waterGoal => 4000; // 4 Liters

  double get bmi => currentWeight / ((height / 100) * (height / 100));

  bool get isJumpRopeUnlocked => currentWeight < 98;

  String get cardioStatus {
    if (currentWeight >= 110) {
      return "CRITICAL LOAD: Joints at risk. SWIMMING ONLY. Zero jumping.";
    }
    if (!isJumpRopeUnlocked) {
      return "JOINT PROTECTION ACTIVE: Focus on Swimming/Incline Walk. 3-min Jump Rope limit.";
    }
    return "JUMP ROPE UNLOCKED: High-intensity sessions permitted.";
  }
}
