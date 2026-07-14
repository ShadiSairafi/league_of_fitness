import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 10, end: 32).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06070B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: GridPaper(
                color: const Color(0xFF00E5FF),
                divisions: 1,
                subdivisions: 1,
                interval: 28,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E00).withOpacity(0.45),
                              blurRadius: _glowAnim.value,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.35),
                              blurRadius: _glowAnim.value + 12,
                              spreadRadius: 4,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF00E5FF),
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/images/app_icon.jpg",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 35),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final flicker = 0.75 + 0.25 * sin(_controller.value * pi * 10);
                    return Opacity(
                      opacity: flicker.clamp(0.0, 1.0),
                      child: Text(
                        "LEAGUE OF FITNESS",
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFFFF5E00),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFF5E00).withOpacity(0.7),
                              blurRadius: 10,
                            ),
                            Shadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  "AI BIOMETRIC ENGINE v2.0",
                  style: GoogleFonts.robotoMono(
                    color: Colors.grey[600],
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
