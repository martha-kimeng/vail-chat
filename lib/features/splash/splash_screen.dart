import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth_service.dart';
import '../../core/onboarding_service.dart';
import '../../core/theme.dart';

// ─── Splash Screen ────────────────────────────────────────────────────────────
// Shown once on every launch while Firebase initialises.
// After the animation completes it routes to:
//   • /onboarding  — first launch
//   • /home        — signed-in returning user
//   • /sign-in     — returning user not signed in

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Navigate after the splash animation finishes (≈2.4 s).
    Future.delayed(const Duration(milliseconds: 2600), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final onboardingDone = await OnboardingService.instance.isComplete();
    if (!mounted) return;

    if (!onboardingDone) {
      context.go('/onboarding');
    } else if (AuthService.instance.currentUser != null) {
      context.go('/home');
    } else {
      context.go('/sign-in');
    }
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Deep gradient background ──────────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0D1A),
                  Color(0xFF1A1A2E),
                  Color(0xFF2D1B3D),
                  Color(0xFF3D0A1E),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── Floating particle hearts ──────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, child) =>
                CustomPaint(painter: _ParticlePainter(_particleCtrl.value)),
          ),

          // ── Soft radial glow behind the logo ─────────────────────────────
          Center(
            child:
                Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            VailColors.rose.withOpacity(0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.15, 1.15),
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    ),
          ),

          // ── Logo + wordmark ───────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heart logo mark
                _LogoMark()
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 28),

                // "Vail" wordmark
                Text(
                      'Vail',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),

                const SizedBox(height: 10),

                // Tagline
                Text(
                      'Love behind the veil',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: Colors.white54,
                        letterSpacing: 3,
                      ),
                    )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOut),
              ],
            ),
          ),

          // ── Bottom pulse dots (loading indicator) ─────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: _PulseDots()
                  .animate(delay: 1000.ms)
                  .fadeIn(duration: 400.ms),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo mark ────────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B8A), Color(0xFFE8516A), Color(0xFFC43150)],
        ),
        boxShadow: [
          BoxShadow(
            color: VailColors.rose.withOpacity(0.5),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
    );
  }
}

// ─── Pulsing loading dots ─────────────────────────────────────────────────────
class _PulseDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
            )
            .animate(
              delay: (i * 160).ms,
              onPlay: (c) => c.repeat(reverse: true),
            )
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}

// ─── Floating particle painter ────────────────────────────────────────────────
// Draws small hearts and dots drifting upward in the background.

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.isHeart,
    required this.phase,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final bool isHeart;
  final double phase; // offset so particles start at different positions
}

final _rng = math.Random(42);

final _particles = List.generate(28, (i) {
  return _Particle(
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    size: 4 + _rng.nextDouble() * 10,
    speed: 0.06 + _rng.nextDouble() * 0.12,
    opacity: 0.06 + _rng.nextDouble() * 0.18,
    isHeart: _rng.nextBool(),
    phase: _rng.nextDouble(),
  );
});

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      // Each particle drifts upward, looping back from the bottom.
      final yProgress = (p.phase + progress * p.speed) % 1.0;
      final y = size.height * (1.0 - yProgress);
      final x =
          size.width * p.x +
          math.sin(yProgress * math.pi * 2 + p.phase * 10) * 18;

      final paint = Paint()
        ..color = VailColors.rose.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      if (p.isHeart) {
        _drawHeart(canvas, Offset(x, y), p.size, paint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size / 2, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final s = size * 0.5;
    path.moveTo(center.dx, center.dy + s * 0.7);
    path.cubicTo(
      center.dx - s * 2,
      center.dy - s * 0.5,
      center.dx - s * 2,
      center.dy - s * 1.8,
      center.dx,
      center.dy - s * 0.8,
    );
    path.cubicTo(
      center.dx + s * 2,
      center.dy - s * 1.8,
      center.dx + s * 2,
      center.dy - s * 0.5,
      center.dx,
      center.dy + s * 0.7,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
