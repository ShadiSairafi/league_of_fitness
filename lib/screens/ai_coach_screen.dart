import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/ai_service.dart';
import '../providers/fitness_provider.dart';
import '../config.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  
  final String _apiKey = geminiApiKey; 
  late AICoachService _aiService;

  int? _pendingCalories;
  int? _pendingProtein;
  String? _pendingDescription;
  bool _hasPendingMeal = false;

  @override
  void initState() {
    super.initState();
    _aiService = AICoachService(_apiKey);
    _messages.add({
      'role': 'coach',
      'text': "Welcome, Tank. I'm your AI Coach. Ready to build that V-Taper? Send me a photo of your meal or ask me anything about your training."
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    
    if (image != null) {
      setState(() {
        _isLoading = true;
        _messages.add({'role': 'user', 'text': "[Photo sent for analysis]"});
      });
      _scrollToBottom();

      try {
        final bytes = await image.readAsBytes();
        final result = await _aiService.analyzeMeal(bytes, "Analyzing my meal");
        
        if (result.containsKey('calories') && !result.containsKey('error')) {
          if (mounted) {
            setState(() {
              _pendingCalories = (result['calories'] as num).toInt();
              _pendingProtein = (result['protein'] as num).toInt();
              _pendingDescription = result['description'] ?? "Meal analyzed";
              _hasPendingMeal = true;
              
              _messages.add({
                'role': 'coach',
                'text': "I've estimated your meal from the image:\n\n🔥 $_pendingCalories Calories\n💪 $_pendingProtein g Protein\n\nLet me know if you want to refine this (just chat with me), or click 'Log Meal' below to confirm!"
              });
              _isLoading = false;
            });
            _scrollToBottom();
          }
        } else {
          setState(() {
            _messages.add({
              'role': 'coach',
              'text': "Sorry, I couldn't parse the nutritional data from the photo. Error: ${result['error'] ?? 'Unknown'}"
            });
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } catch (e) {
        setState(() {
          _messages.add({
            'role': 'coach',
            'text': "Error loading image bytes: $e"
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    
    final userText = _chatController.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _chatController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // Check if we are refining a pending meal
    if (_hasPendingMeal) {
      try {
        final result = await _aiService.refineMealLog(
          previousDescription: _pendingDescription ?? "",
          previousCalories: _pendingCalories ?? 0,
          previousProtein: _pendingProtein ?? 0,
          userFeedback: userText,
        );

        if (result.containsKey('calories') && !result.containsKey('error')) {
          if (mounted) {
            setState(() {
              _pendingCalories = (result['calories'] as num).toInt();
              _pendingProtein = (result['protein'] as num).toInt();
              _pendingDescription = result['description'] ?? "";
              
              _messages.add({
                'role': 'coach',
                'text': "Understood. I've updated the pending log:\n\n\"$_pendingDescription\"\n🔥 $_pendingCalories kcal | 💪 $_pendingProtein g protein\n\nCheck the card below to confirm!"
              });
              _isLoading = false;
            });
            _scrollToBottom();
          }
        } else {
          if (mounted) {
            setState(() {
              _messages.add({
                'role': 'coach',
                'text': "I couldn't adjust the log. Error: ${result['error'] ?? 'Unknown'}"
              });
              _isLoading = false;
            });
            _scrollToBottom();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'coach',
              'text': "Could not connect to refine log: $e"
            });
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
      return;
    }

    // Classify if it's a food log request (keywords checklist)
    final lower = userText.toLowerCase();
    final isFoodLog = lower.startsWith("log") ||
        lower.startsWith("i ate") ||
        lower.startsWith("i had") ||
        lower.startsWith("breakfast") ||
        lower.startsWith("lunch") ||
        lower.startsWith("dinner") ||
        lower.startsWith("snack") ||
        lower.contains("grams of") ||
        lower.contains("calories") ||
        lower.contains("protein");

    if (isFoodLog) {
      try {
        final result = await _aiService.analyzeMealText(userText);
        if (result.containsKey('calories') && !result.containsKey('error')) {
          if (mounted) {
            setState(() {
              _pendingCalories = (result['calories'] as num).toInt();
              _pendingProtein = (result['protein'] as num).toInt();
              _pendingDescription = result['description'] ?? "Meal analyzed";
              _hasPendingMeal = true;

              _messages.add({
                'role': 'coach',
                'text': "I've estimated your meal from your text:\n\n🔥 $_pendingCalories Calories\n💪 $_pendingProtein g Protein\n\nLet me know if you want to adjust anything, or click 'Log Meal' below to confirm!"
              });
              _isLoading = false;
            });
            _scrollToBottom();
          }
        } else {
          if (mounted) {
            setState(() {
              _messages.add({
                'role': 'coach',
                'text': "I couldn't estimate nutritional values. Error: ${result['error'] ?? 'Unknown'}"
              });
              _isLoading = false;
            });
            _scrollToBottom();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'coach',
              'text': "Could not connect to analyze text: $e"
            });
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    } else {
      // Normal coaching conversation
      try {
        final fitnessProvider = context.read<FitnessProvider>();
        final List<String> exercisePBs = [];
        for (var workout in fitnessProvider.plan) {
          for (var exercise in workout.exercises) {
            if (exercise.highscoreWeight != null || exercise.highscoreTime != null) {
              final pbStr = exercise.highscoreWeight != null 
                  ? "${exercise.highscoreWeight} kg" 
                  : exercise.highscoreTime!;
              exercisePBs.add("${exercise.name}: PB is $pbStr");
            }
          }
        }

        final response = await _aiService.askCoach(
          question: userText,
          profile: fitnessProvider.userProfile,
          completedExercises: fitnessProvider.completedExercises.toList(),
          personalBests: exercisePBs,
          activeCaloriesBurned: fitnessProvider.activeCaloriesBurnedToday,
          bmr: fitnessProvider.bmr,
        );
        if (mounted) {
          setState(() {
            _messages.add({'role': 'coach', 'text': response});
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'coach',
              'text': "Coach encountered a communication timeout. Check your connection or API status."
            });
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      appBar: AppBar(
        title: Text(
          "TANK COACH AI",
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
      body: Column(
        children: [
          // Chat messages container
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isCoach = msg['role'] == 'coach';
                return _buildMessageRow(msg['text']!, isCoach);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SpinKitThreeBounce(color: Color(0xFFFF007F), size: 20),
            ),
          if (_hasPendingMeal) _buildPendingMealCard(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildPendingMealCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00E5FF).withOpacity(0.15), const Color(0xFF11121B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.circleQuestion, color: Color(0xFF00E5FF), size: 14),
              const SizedBox(width: 8),
              Text(
                "CONFIRM MEAL LOG",
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00E5FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _pendingDescription ?? "Analyzing...",
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF007F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "🔥 ${_pendingCalories ?? 0} kcal",
                      style: GoogleFonts.robotoMono(color: const Color(0xFFFF007F), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "💪 ${_pendingProtein ?? 0}g protein",
                      style: GoogleFonts.robotoMono(color: const Color(0xFFFF5E00), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _hasPendingMeal = false;
                        _pendingCalories = null;
                        _pendingProtein = null;
                        _pendingDescription = null;
                      });
                    },
                    child: Text(
                      "CANCEL",
                      style: GoogleFonts.orbitron(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      if (_pendingCalories != null) {
                        context.read<FitnessProvider>().addCalories(_pendingCalories!);
                      }
                      if (_pendingProtein != null) {
                        context.read<FitnessProvider>().addProtein(_pendingProtein!);
                      }
                      
                      setState(() {
                        _messages.add({
                          'role': 'coach',
                          'text': "Boom! Logged ${_pendingCalories} kcal and ${_pendingProtein}g protein to your stats. Fuel for the engine!"
                        });
                        _hasPendingMeal = false;
                        _pendingCalories = null;
                        _pendingProtein = null;
                        _pendingDescription = null;
                      });
                      _scrollToBottom();
                    },
                    child: Text(
                      "LOG MEAL",
                      style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(String text, bool isCoach) {
    return Align(
      alignment: isCoach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCoach) ...[
              Container(
                margin: const EdgeInsets.only(right: 10, top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                ),
                child: const Icon(FontAwesomeIcons.shieldHalved, color: Color(0xFF00E5FF), size: 14),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isCoach
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFF007F), Color(0xFFFF5E00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isCoach ? const Color(0xFF11121A) : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isCoach ? 0 : 20),
                    bottomRight: Radius.circular(isCoach ? 20 : 0),
                  ),
                  border: isCoach ? Border.all(color: const Color(0xFF232533)) : null,
                  boxShadow: isCoach
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFFFF007F).withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCoach) ...[
                      Text(
                        "THE TANK COACH",
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: isCoach ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isCoach) ...[
              Container(
                margin: const EdgeInsets.only(left: 10, top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5E00).withOpacity(0.3)),
                ),
                child: const Icon(FontAwesomeIcons.user, color: Color(0xFFFF5E00), size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D13),
        border: Border(top: BorderSide(color: Color(0xFF1E202C))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Gallery selection button
            InkWell(
              onTap: () => _pickAndAnalyzeImage(ImageSource.gallery),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                ),
                child: const Icon(FontAwesomeIcons.image, color: Color(0xFF00E5FF), size: 15),
              ),
            ),
            const SizedBox(width: 8),
            // Camera snap button
            InkWell(
              onTap: () => _pickAndAnalyzeImage(ImageSource.camera),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                ),
                child: const Icon(FontAwesomeIcons.camera, color: Color(0xFF00E5FF), size: 15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161824),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF232533)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _chatController,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  cursorColor: const Color(0xFFFF007F),
                  decoration: InputDecoration(
                    hintText: "Talk to coach...",
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF007F), Color(0xFFFF5E00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
