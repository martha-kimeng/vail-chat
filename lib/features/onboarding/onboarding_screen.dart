import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/onboarding_service.dart';

// ─── Slide data ───────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.accent,
    required this.accentLight,
    required this.icon,
    required this.illustrationIcons,
    required this.title,
    required this.subtitle,
    required this.tag,
  });

  final Color accent;
  final Color accentLight;
  final IconData icon;
  final List<_FloatingIcon> illustrationIcons;
  final String title;
  final String subtitle;
  final String tag; // short ALL-CAPS label above the title
}

class _FloatingIcon {
  const _FloatingIcon({
    required this.icon,
    required this.x, // 0–1 relative to illustration box
    required this.y,
    required this.size,
    required this.opacity,
    required this.phase,
  });

  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double phase;
}

const _slides = [
  _Slide(
    accent: Color(0xFFE8516A),
    accentLight: Color(0xFFFF8FA3),
    icon: Icons.masks_rounded,
    illustrationIcons: [
      _FloatingIcon(
        icon: Icons.person_outline_rounded,
        x: 0.15,
        y: 0.20,
        size: 28,
        opacity: 0.25,
        phase: 0.0,
      ),
      _FloatingIcon(
        icon: Icons.person_outline_rounded,
        x: 0.75,
        y: 0.15,
        size: 22,
        opacity: 0.18,
        phase: 0.4,
      ),
      _FloatingIcon(
        icon: Icons.chat_bubble_outline_rounded,
        x: 0.55,
        y: 0.70,
        size: 20,
        opacity: 0.20,
        phase: 0.7,
      ),
      _FloatingIcon(
        icon: Icons.lock_outline_rounded,
        x: 0.82,
        y: 0.55,
        size: 18,
        opacity: 0.22,
        phase: 0.2,
      ),
      _FloatingIcon(
        icon: Icons.star_outline_rounded,
        x: 0.25,
        y: 0.75,
        size: 16,
        opacity: 0.16,
        phase: 0.9,
      ),
    ],
    title: 'No names.\nNo photos.\nJust you.',
    subtitle:
        'Everyone starts anonymous. Your words and personality do the talking — no judgements, no filters.',
    tag: 'ANONYMOUS FIRST',
  ),
  _Slide(
    accent: Color(0xFF9B59B6),
    accentLight: Color(0xFFCC88E8),
    icon: Icons.favorite_border_rounded,
    illustrationIcons: [
      _FloatingIcon(
        icon: Icons.favorite_border_rounded,
        x: 0.18,
        y: 0.18,
        size: 26,
        opacity: 0.22,
        phase: 0.1,
      ),
      _FloatingIcon(
        icon: Icons.favorite_rounded,
        x: 0.72,
        y: 0.22,
        size: 18,
        opacity: 0.30,
        phase: 0.5,
      ),
      _FloatingIcon(
        icon: Icons.bolt_rounded,
        x: 0.60,
        y: 0.68,
        size: 22,
        opacity: 0.20,
        phase: 0.3,
      ),
      _FloatingIcon(
        icon: Icons.auto_awesome_rounded,
        x: 0.80,
        y: 0.58,
        size: 20,
        opacity: 0.18,
        phase: 0.8,
      ),
      _FloatingIcon(
        icon: Icons.chat_rounded,
        x: 0.22,
        y: 0.72,
        size: 17,
        opacity: 0.16,
        phase: 0.6,
      ),
    ],
    title: 'Talk.\nFeel the\nspark.',
    subtitle:
        'When the conversation clicks, signal your chemistry. If both of you feel it — the universe knows.',
    tag: 'MUTUAL CHEMISTRY',
  ),
  _Slide(
    accent: Color(0xFFE84393),
    accentLight: Color(0xFFFF80C0),
    icon: Icons.card_giftcard_rounded,
    illustrationIcons: [
      _FloatingIcon(
        icon: Icons.location_on_outlined,
        x: 0.20,
        y: 0.20,
        size: 24,
        opacity: 0.22,
        phase: 0.2,
      ),
      _FloatingIcon(
        icon: Icons.restaurant_outlined,
        x: 0.73,
        y: 0.18,
        size: 20,
        opacity: 0.18,
        phase: 0.6,
      ),
      _FloatingIcon(
        icon: Icons.local_cafe_outlined,
        x: 0.62,
        y: 0.65,
        size: 22,
        opacity: 0.20,
        phase: 0.4,
      ),
      _FloatingIcon(
        icon: Icons.auto_awesome_rounded,
        x: 0.15,
        y: 0.65,
        size: 17,
        opacity: 0.24,
        phase: 0.9,
      ),
      _FloatingIcon(
        icon: Icons.favorite_rounded,
        x: 0.82,
        y: 0.55,
        size: 18,
        opacity: 0.28,
        phase: 0.1,
      ),
    ],
    title: 'The reveal\nis the\ndate.',
    subtitle:
        'Once the spark is mutual, plan a real blind date — right inside Vail. Meet for the very first time, in real life.',
    tag: 'BLIND DATE',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingService.instance.markComplete();
    if (mounted) context.go('/sign-in');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0D0D1A), slide.accent.withOpacity(0.45)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step counter
                    Text(
                      '${_page + 1} / ${_slides.length}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Skip / Sign in link
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SegmentedProgress(
                  total: _slides.length,
                  current: _page,
                  color: slide.accent,
                ),
              ),

              const SizedBox(height: 8),

              // ── Page view ────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) =>
                      _SlidePage(slide: _slides[i], floatCtrl: _floatCtrl),
                ),
              ),

              // ── Bottom CTA area ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => _Dot(active: i == _page, color: slide.accent),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // CTA button
                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [slide.accentLight, slide.accent],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: slide.accent.withOpacity(0.40),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _page < _slides.length - 1
                                    ? 'Continue'
                                    : 'Get Started',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _page < _slides.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.favorite_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Individual slide page ────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide, required this.floatCtrl});
  final _Slide slide;
  final AnimationController floatCtrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ── Illustration panel ─────────────────────────────────────────
          Center(
            child: _IllustrationPanel(slide: slide, floatCtrl: floatCtrl),
          ),

          const SizedBox(height: 36),

          // Tag
          Text(
                slide.tag,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: slide.accentLight,
                  letterSpacing: 2.5,
                ),
              )
              .animate(key: ValueKey('tag-${slide.tag}'))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.08, curve: Curves.easeOut),

          const SizedBox(height: 12),

          // Title
          Text(
                slide.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              )
              .animate(key: ValueKey('title-${slide.title}'), delay: 60.ms)
              .fadeIn(duration: 450.ms)
              .slideX(begin: 0.1, curve: Curves.easeOut),

          const SizedBox(height: 16),

          // Subtitle
          Text(
                slide.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white60,
                  height: 1.65,
                ),
              )
              .animate(key: ValueKey('sub-${slide.subtitle}'), delay: 120.ms)
              .fadeIn(duration: 450.ms)
              .slideX(begin: 0.08, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

// ─── Illustration panel ───────────────────────────────────────────────────────

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.slide, required this.floatCtrl});
  final _Slide slide;
  final AnimationController floatCtrl;

  @override
  Widget build(BuildContext context) {
    const boxH = 200.0;
    const boxW = 280.0;

    return SizedBox(
      width: boxW,
      height: boxH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer glow ring
          Center(
            child: AnimatedBuilder(
              animation: floatCtrl,
              builder: (context, child) {
                final scale = 1.0 + math.sin(floatCtrl.value * math.pi) * 0.06;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slide.accent.withOpacity(0.20),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Inner glow ring
          Center(
            child: AnimatedBuilder(
              animation: floatCtrl,
              builder: (context, child) {
                final scale =
                    1.0 + math.sin(floatCtrl.value * math.pi + 0.5) * 0.08;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slide.accent.withOpacity(0.10),
                      border: Border.all(
                        color: slide.accent.withOpacity(0.30),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Central icon
          Center(
            child:
                Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [slide.accentLight, slide.accent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: slide.accent.withOpacity(0.45),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(slide.icon, color: Colors.white, size: 38),
                    )
                    .animate(key: ValueKey('icon-${slide.icon.codePoint}'))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 550.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms),
          ),

          // Floating ambient icons
          ...slide.illustrationIcons.map((fi) {
            return AnimatedBuilder(
              animation: floatCtrl,
              builder: (context, child) {
                final offsetY =
                    math.sin(
                      floatCtrl.value * math.pi * 2 + fi.phase * math.pi * 2,
                    ) *
                    6.0;
                return Positioned(
                  left: fi.x * boxW - fi.size / 2,
                  top: fi.y * boxH - fi.size / 2 + offsetY,
                  child: Icon(
                    fi.icon,
                    size: fi.size,
                    color: slide.accentLight.withOpacity(fi.opacity),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─── Segmented progress bar ───────────────────────────────────────────────────

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.total,
    required this.current,
    required this.color,
  });
  final int total;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: i <= current ? color : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Dot indicator ────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.color});
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? color : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
