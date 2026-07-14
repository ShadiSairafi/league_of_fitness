import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/fitness_provider.dart';
import '../services/ai_service.dart';
import '../config.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _promptController = TextEditingController();
  
  final List<XFile> _pickedImagesList = [];
  final List<Uint8List> _imageBytesList = [];
  bool _isLoading = false;
  
  Map<String, dynamic>? _generatedRecipe;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageBytesList.length >= 4) {
      setState(() {
        _errorMessage = "Maximum of 4 ingredient specimen images allowed.";
      });
      return;
    }
    
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImagesList.add(image);
          _imageBytesList.add(bytes);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load specimen image: $e";
      });
    }
  }

  Future<void> _engageChef() async {
    final provider = context.read<FitnessProvider>();
    setState(() {
      _isLoading = true;
      _generatedRecipe = null;
      _errorMessage = null;
    });

    final service = AICoachService(geminiApiKey);
    
    try {
      final responseText = await service.askChiefTank(
        userPrompt: _promptController.text.trim().isEmpty 
            ? "Create the best low-calorie, high-protein recipe possible with these ingredients." 
            : _promptController.text.trim(),
        imagesBytes: _imageBytesList.isNotEmpty ? _imageBytesList : null,
        profile: provider.userProfile,
      );

      final Map<String, dynamic> parsed = jsonDecode(responseText);
      if (parsed.containsKey('error')) {
        setState(() {
          _errorMessage = parsed['error'];
        });
      } else {
        setState(() {
          _generatedRecipe = parsed;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Chef Tank failed to parse instructions. Please verify your internet connection or key.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchYouTube(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse("https://www.youtube.com/results?search_query=$encodedQuery");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      developer.log("Could not launch YouTube link", error: e);
    }
  }

  void _showRefineDialog(BuildContext context, FitnessProvider provider, Map<String, dynamic> recipe) {
    final TextEditingController feedbackController = TextEditingController();
    bool dialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0E111A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFFFF5E00).withOpacity(0.5), width: 1.5),
              ),
              title: Text(
                "REFINE RECIPE",
                style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: dialogLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00E5FF))),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Tell Chief Tank what adjustments to make (e.g. double the protein, make it vegan, scale to 3 portions):",
                          style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: feedbackController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Refinement protocols...",
                            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                            fillColor: const Color(0xFF08090C),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1A2130)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFFF5E00)),
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: dialogLoading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final text = feedbackController.text.trim();
                          if (text.isEmpty) return;
                          setDialogState(() {
                            dialogLoading = true;
                          });
                          try {
                            await provider.refineSavedRecipe(recipe, text);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0E1A1A),
                                  content: Text(
                                    "RECIPE REFINE PROTOCOL COMPLETE!",
                                    style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              dialogLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5E00),
                        ),
                        child: Text(
                          "REFINE",
                          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showPreArchiveRefineDialog(BuildContext context, FitnessProvider provider, Map<String, dynamic> recipe) {
    final TextEditingController feedbackController = TextEditingController();
    bool dialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0E111A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFFFF5E00).withOpacity(0.5), width: 1.5),
              ),
              title: Text(
                "REFINE PENDING RECIPE",
                style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: dialogLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00E5FF))),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Request changes for this pending recipe (e.g. swap ingredients, make it faster):",
                          style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: feedbackController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Refinement protocols...",
                            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                            fillColor: const Color(0xFF08090C),
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1A2130)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFFF5E00)),
                            ),
                          ),
                        ),
                      ],
                    ),
              actions: dialogLoading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.orbitron(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final text = feedbackController.text.trim();
                          if (text.isEmpty) return;
                          setDialogState(() {
                            dialogLoading = true;
                          });
                          try {
                            final service = AICoachService(geminiApiKey);
                            final responseText = await service.refineChefRecipe(
                              previousRecipe: recipe,
                              userFeedback: text,
                              profile: provider.userProfile,
                            );
                            final Map<String, dynamic> parsed = jsonDecode(responseText);
                            if (mounted) {
                              Navigator.of(context).pop();
                              if (parsed.containsKey('error')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(parsed['error'])),
                                );
                              } else {
                                setState(() {
                                  _generatedRecipe = parsed;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF0E1A1A),
                                    content: Text(
                                      "PENDING FUEL PROTOCOL UPDATED!",
                                      style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              dialogLoading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5E00),
                        ),
                        child: Text(
                          "REFINE",
                          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showImagePreviewDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitnessProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "THE FUEL ENGINE",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
            color: const Color(0xFFFF5E00),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.grey[500],
          labelStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1.5),
          tabs: const [
            Tab(text: "CHIEF TANK"),
            Tab(text: "SAVED FUELS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChiefTankTab(provider),
          _buildSavedRecipesTab(provider),
        ],
      ),
    );
  }

  Widget _buildChiefTankTab(FitnessProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cyberpunk Grid Specimen Container
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0E111A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: GridPaper(
                      color: const Color(0xFF00E5FF),
                      divisions: 1,
                      subdivisions: 1,
                      interval: 20,
                    ),
                  ),
                ),
                if (_imageBytesList.isNotEmpty)
                  Positioned.fill(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      itemCount: _imageBytesList.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePreviewDialog(context, _imageBytesList[index]),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 140,
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    _imageBytesList[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 18,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _pickedImagesList.removeAt(index);
                                    _imageBytesList.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, color: Colors.redAccent, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.robot, color: Colors.grey[600], size: 40),
                        const SizedBox(height: 12),
                        Text(
                          "INGREDIENT SPECIMEN SCANNER",
                          style: GoogleFonts.orbitron(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Load image(s) of ingredients to analyze (Max 4)",
                          style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 11),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text("CAMERA SCAN", style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: const Color(0xFFFF5E00),
                    side: const BorderSide(color: Color(0xFFFF5E00), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text("UPLOAD PIX", style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            "CHEF PROTOCOL PROTOCOL DETAILS (OPTIONAL)",
            style: GoogleFonts.orbitron(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _promptController,
            maxLines: 2,
            style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "e.g., Low carb, extreme protein, fast 10-min prep, use garlic...",
              hintStyle: GoogleFonts.roboto(color: Colors.grey[700], fontSize: 13),
              fillColor: const Color(0xFF0F111E),
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1A2130)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFF5E00)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (_isLoading)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00E5FF))),
                  const SizedBox(height: 12),
                  Text(
                    "CHIEF TANK IS COOKING... INGREDIENTS SCAN IN PROGRESS",
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: _engageChef,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 6,
                shadowColor: const Color(0xFFFF5E00).withOpacity(0.5),
              ),
              child: Text(
                "ENGAGE CHIEF TANK",
                style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C0A0E),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.roboto(color: Colors.red[100], fontSize: 13),
                    ),
                  )
                ],
              ),
            )
          ],
          
          if (_generatedRecipe != null) ...[
            const SizedBox(height: 24),
            _buildRecipeResultCard(provider, _generatedRecipe!),
          ]
        ],
      ),
    );
  }

  Widget _buildRecipeResultCard(FitnessProvider provider, Map<String, dynamic> recipe) {
    final title = recipe['title'] ?? "Chef Specimen Recipe";
    final calories = (recipe['calories'] as num?)?.toInt() ?? 0;
    final protein = (recipe['protein'] as num?)?.toInt() ?? 0;
    final desc = recipe['description'] ?? "";
    final List<dynamic> ingredients = recipe['ingredients'] ?? [];
    final List<dynamic> instructions = recipe['instructions'] ?? [];
    final youtube = recipe['youtubeSearch'] ?? "";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF5E00).withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CHIEF TANK PROTOCOL",
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFF5E00),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Icon(Icons.restaurant_menu, color: Color(0xFFFF5E00), size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title.toString().toUpperCase(),
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E140F),
                  border: Border.all(color: const Color(0xFFFF5E00), width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.fire, color: Color(0xFFFF5E00), size: 12),
                    const SizedBox(width: 6),
                    Text(
                      "$calories KCAL",
                      style: GoogleFonts.robotoMono(color: const Color(0xFFFF5E00), fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1A1A),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.dumbbell, color: Color(0xFF00E5FF), size: 12),
                    const SizedBox(width: 6),
                    Text(
                      "$protein g PRO",
                      style: GoogleFonts.robotoMono(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          Text(
            desc,
            style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 13, height: 1.4),
          ),
          const Divider(color: Color(0xFF1A2130), height: 24),
          
          Text(
            "REQUIRED INGREDIENTS:",
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ...ingredients.map((ing) => Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("⚡ ", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10)),
                Expanded(
                  child: Text(
                    ing.toString(),
                    style: GoogleFonts.robotoMono(color: Colors.grey[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
          const Divider(color: Color(0xFF1A2130), height: 24),
          
          Text(
            "PREPARATION PROTOCOL:",
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ...instructions.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2130),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${entry.key + 1}",
                    style: GoogleFonts.robotoMono(color: const Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: GoogleFonts.roboto(color: Colors.grey[300], fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
          
          if (youtube.toString().isNotEmpty) ...[
            const Divider(color: Color(0xFF1A2130), height: 24),
            ElevatedButton.icon(
              onPressed: () => _launchYouTube(youtube.toString()),
              icon: const Icon(FontAwesomeIcons.youtube, size: 14),
              label: Text("LAUNCH YOUTUBE TUTORIAL", style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C0A0E),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                side: const BorderSide(color: Colors.redAccent, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
          
          const Divider(color: Color(0xFF1A2130), height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await provider.quickLogRecipeMacros(calories, protein, title);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0E1A1A),
                          content: Text(
                            "FUEL LOADED! +$calories kcal and +$protein g protein added.",
                            style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(FontAwesomeIcons.circleCheck, size: 14),
                  label: Text("CONSUME", style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showPreArchiveRefineDialog(context, provider, recipe),
                icon: const Icon(Icons.edit_note, size: 14, color: Colors.white),
                label: Text("REFINE", style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: const Color(0xFFFF5E00).withOpacity(0.5), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.saveRecipe(recipe);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF1E140F),
                          content: Text(
                            "RECIPE PERSISTED IN THE ARCHIVE!",
                            style: GoogleFonts.orbitron(color: const Color(0xFFFF5E00), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.archive_outlined, size: 14),
                  label: Text("ARCHIVE", style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5E00),
                    side: const BorderSide(color: Color(0xFFFF5E00), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRecipesTab(FitnessProvider provider) {
    final recipes = provider.savedRecipes;
    
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, color: Colors.grey[700], size: 48),
            const SizedBox(height: 12),
            Text(
              "ARCHIVE IS VACANT",
              style: GoogleFonts.orbitron(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Save recipes from Chief Tank to view them here.",
              style: GoogleFonts.roboto(color: Colors.grey[700], fontSize: 12),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final title = recipe['title'] ?? "Saved Recipe";
        final calories = (recipe['calories'] as num?)?.toInt() ?? 0;
        final protein = (recipe['protein'] as num?)?.toInt() ?? 0;
        final desc = recipe['description'] ?? "";
        final youtube = recipe['youtubeSearch'] ?? "";

        return Card(
          color: const Color(0xFF0F111E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: const Color(0xFF1A2130), width: 1),
          ),
          child: ExpansionTile(
            title: Text(
              title.toString().toUpperCase(),
              style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  Text(
                    "$calories kcal",
                    style: GoogleFonts.robotoMono(color: const Color(0xFFFF5E00), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "$protein g protein",
                    style: GoogleFonts.robotoMono(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            iconColor: const Color(0xFF00E5FF),
            collapsedIconColor: Colors.grey[600],
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      desc,
                      style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      "INGREDIENTS:",
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...(recipe['ingredients'] as List<dynamic>? ?? []).map((ing) => Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Text("• $ing", style: GoogleFonts.robotoMono(color: Colors.grey[300], fontSize: 12)),
                    )),
                    const SizedBox(height: 12),
                    
                    Text(
                      "INSTRUCTIONS:",
                      style: GoogleFonts.orbitron(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...(recipe['instructions'] as List<dynamic>? ?? []).asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        "${entry.key + 1}. ${entry.value}",
                        style: GoogleFonts.roboto(color: Colors.grey[300], fontSize: 12, height: 1.3),
                      ),
                    )),
                    
                    if (youtube.toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _launchYouTube(youtube.toString()),
                        icon: const Icon(FontAwesomeIcons.youtube, size: 14),
                        label: Text("LAUNCH YOUTUBE TUTORIAL", style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C0A0E),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                    
                    const Divider(color: Color(0xFF1A2130), height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await provider.quickLogRecipeMacros(calories, protein, title);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF0E1A1A),
                                    content: Text(
                                      "FUEL LOADED! +$calories kcal and +$protein g protein added.",
                                      style: GoogleFonts.orbitron(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(FontAwesomeIcons.bolt, size: 12, color: Colors.black),
                            label: Text("QUICK LOG", style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showRefineDialog(context, provider, recipe),
                          icon: const Icon(Icons.edit_note, size: 14, color: Colors.white),
                          label: Text("REFINE", style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E1E),
                            foregroundColor: Colors.white,
                            side: BorderSide(color: const Color(0xFFFF5E00).withOpacity(0.5), width: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => provider.deleteRecipe(title),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2C0A0E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
