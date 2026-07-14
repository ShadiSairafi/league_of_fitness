import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/fitness_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_list_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/fuel_screen.dart';
import 'widgets/completion_animation_overlay.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FitnessProvider()),
      ],
      child: const MacroMindApp(),
    ),
  );
}

class MacroMindApp extends StatelessWidget {
  const MacroMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'League of Fitness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _lastAnimationId = 0;
  OverlayEntry? _animationOverlay;
  final Random _random = Random();

  static const List<Widget> _screens = [
    DashboardScreen(),
    WorkoutListScreen(),
    FuelScreen(),
    AICoachScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FitnessProvider>();
      _lastAnimationId = provider.completedTodayAnimationId;
      provider.addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<FitnessProvider>().removeListener(_onProviderChange);
    _removeAnimationOverlay();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-sync dates, stats, and streaks automatically when app wakes up
      context.read<FitnessProvider>().refreshStateOnForeground();
    }
  }

  void _onProviderChange() {
    final provider = context.read<FitnessProvider>();
    if (provider.completedTodayAnimationId > _lastAnimationId) {
      _lastAnimationId = provider.completedTodayAnimationId;
      _triggerCompletionAnimation();
    }
  }

  void _removeAnimationOverlay() {
    _animationOverlay?.remove();
    _animationOverlay = null;
  }

  void _triggerCompletionAnimation() {
    _removeAnimationOverlay();
    final randomType = _random.nextInt(5);

    _animationOverlay = OverlayEntry(
      builder: (context) => CompletionAnimationOverlay(
        animationType: randomType,
        onFinished: () {
          _removeAnimationOverlay();
        },
      ),
    );

    Overlay.of(context).insert(_animationOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF0C0D13),
        selectedItemColor: const Color(0xFFFF5E00),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), activeIcon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), activeIcon: Icon(Icons.restaurant_menu), label: 'Fuel'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), activeIcon: Icon(Icons.psychology), label: 'Coach'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
