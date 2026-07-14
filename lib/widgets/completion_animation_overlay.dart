import 'dart:math';
import 'package:flutter/material.dart';

class CompletionAnimationOverlay extends StatefulWidget {
  final int animationType;
  final VoidCallback onFinished;

  const CompletionAnimationOverlay({
    super.key,
    required this.animationType,
    required this.onFinished,
  });

  @override
  State<CompletionAnimationOverlay> createState() => _CompletionAnimationOverlayState();
}

class _CompletionAnimationOverlayState extends State<CompletionAnimationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _controller.addListener(() {
      setState(() {});
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });

    _initializeAnimation();
    _controller.forward();
  }

  void _initializeAnimation() {
    if (widget.animationType == 1) {
      // Neon Particle Explosion
      for (int i = 0; i < 80; i++) {
        _particles.add(Particle(
          x: 200,
          y: 400,
          vx: (_random.nextDouble() - 0.5) * 15,
          vy: (_random.nextDouble() - 0.5) * 15 - 5,
          color: _random.nextBool() ? const Color(0xFF00E5FF) : const Color(0xFFFF007F),
          size: _random.nextDouble() * 6 + 2,
        ));
      }
    } else if (widget.animationType == 4) {
      // Cyber-Confetti Rain
      for (int i = 0; i < 100; i++) {
        _particles.add(Particle(
          x: _random.nextDouble() * 400,
          y: -50,
          vx: (_random.nextDouble() - 0.5) * 3,
          vy: _random.nextDouble() * 5 + 3,
          color: _random.nextBool() ? const Color(0xFF00E5FF) : const Color(0xFFFF5E00),
          size: _random.nextDouble() * 8 + 4,
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: AnimationPainter(
            animationType: widget.animationType,
            progress: _controller.value,
            particles: _particles,
          ),
        ),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.15; // gravity
  }
}

class AnimationPainter extends CustomPainter {
  final int animationType;
  final double progress;
  final List<Particle> particles;
  final Random _random = Random();

  AnimationPainter({
    required this.animationType,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    if (animationType == 0) {
      // 1. Neon Pulse Concentric Rings
      final pulseRadius = progress * (size.width * 0.8);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * (1.0 - progress);

      // Pink ring
      paint.color = const Color(0xFFFF007F).withOpacity(1.0 - progress);
      canvas.drawCircle(center, pulseRadius, paint);

      // Cyan ring delayed
      if (progress > 0.2) {
        paint.color = const Color(0xFF00E5FF).withOpacity(1.0 - progress);
        canvas.drawCircle(center, pulseRadius * 0.8, paint);
      }
    } else if (animationType == 1) {
      // 2. Neon Particle Explosion
      for (var p in particles) {
        // center coordinates dynamically updated to size
        if (p.x == 200 && p.y == 400) {
          p.x = size.width / 2;
          p.y = size.height / 2;
        }
        p.update();
        paint.color = p.color.withOpacity(1.0 - progress);
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      }
    } else if (animationType == 2) {
      // 3. Sweeping Laser Beams
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final beamCount = 8;
      for (int i = 0; i < beamCount; i++) {
        final angle = (i * (2 * pi / beamCount)) + (progress * pi);
        final length = size.width * progress;
        final start = center;
        final end = center + Offset(cos(angle) * length, sin(angle) * length);

        paint.color = (i % 2 == 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF007F))
            .withOpacity(1.0 - progress);
        canvas.drawLine(start, end, paint);
      }
    } else if (animationType == 3) {
      // 4. Glitch Shockwave
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0 * (1.0 - progress);

      // Glitch ring (distorted circle)
      final radius = progress * (size.width * 0.7);
      final path = Path();
      const points = 16;
      for (int i = 0; i < points; i++) {
        final angle = i * (2 * pi / points);
        final jitter = (1.0 - progress) * 12.0 * (_random.nextDouble() - 0.5);
        final r = radius + jitter;
        final x = size.width / 2 + cos(angle) * r;
        final y = size.height / 2 + sin(angle) * r;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      
      paint.color = const Color(0xFFFF5E00).withOpacity(1.0 - progress);
      canvas.drawPath(path, paint);

      // Double offset cyan glitch path
      final pathCyan = Path();
      for (int i = 0; i < points; i++) {
        final angle = i * (2 * pi / points);
        final jitter = (1.0 - progress) * 16.0 * (_random.nextDouble() - 0.5);
        final r = (radius * 0.95) + jitter;
        final x = (size.width / 2 + 5) + cos(angle) * r;
        final y = (size.height / 2 - 3) + sin(angle) * r;
        if (i == 0) {
          pathCyan.moveTo(x, y);
        } else {
          pathCyan.lineTo(x, y);
        }
      }
      pathCyan.close();

      paint.color = const Color(0xFF00E5FF).withOpacity(1.0 - progress);
      canvas.drawPath(pathCyan, paint);
    } else {
      // 5. Confetti Drop
      for (var p in particles) {
        p.y += p.vy;
        p.x += sin(progress * 10 + p.size) * 1.5;
        paint.color = p.color.withOpacity(1.0 - progress);
        canvas.drawRect(
          Rect.fromLTWH(p.x, p.y, p.size, p.size * 1.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
