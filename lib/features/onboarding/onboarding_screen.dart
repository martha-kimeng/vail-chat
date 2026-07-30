import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data model for each slide ───────────────────────────────────────────────
class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
}

const _slides = [
  _Slide(
    icon: Icons.masks_rounded,
    title: 'Meet without\nthe mask.',
    subtitle:
        'Everyone starts anonymous. No photos, no names — just words and personality. Who you are matters more than how you look.',
    accent: Color(0xFFE8516A),
  ),
  _Slide(
    icon: Icons.chat_bubble_outline_rounded,
    title: 'Talk.\nFeel the spark.',
    subtitle:
        'Conversations flow naturally. When both of you feel a genuine connection, you can signal the chemistry — together.',
    accent: Color(0xFF9B59B6),
  ),
  _Slide(
    icon: Icons.favorite_border_rounded,
    title: 'The reveal\nis the date.',
    subtitle:
        'Once chemistry is mutual, plan a blind date right inside the app. Meet for the first time — in real life.',
    accent: Color(0xFFE84393),
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/sign-up');
    }
  }

  void _skip() => context.go('/sign-in');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient that animates colour per slide
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E),
                  _slides[_currentPage].accent.withOpacity(0.55),
                ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: _DecorativeCircle(
              size: 260,
              color: _slides[_currentPage].accent.withOpacity(0.12),
            ),
          ),
          Positioned(
            bottom: 140,
            left: -80,
            child: _DecorativeCircle(
              size: 200,
              color: _slides[_currentPage].accent.withOpacity(0.08),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) => _SlidePage(slide: _slides[i]),
                  ),
                ),

                // Dots + CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Column(
                    children: [
                      // Page dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (i) => _Dot(active: i == _currentPage),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // CTA button
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _slides[_currentPage].accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage < _slides.length - 1
                              ? 'Continue'
                              : 'Get Started',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

// ─── Individual slide content ─────────────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in a frosted circle
          Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.accent.withOpacity(0.2),
                  border: Border.all(
                    color: slide.accent.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(slide.icon, size: 40, color: slide.accent),
              )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
              )
              .fadeIn(),
          const SizedBox(height: 36),
          Text(
                slide.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              )
              .animate()
              .slideX(
                begin: 0.15,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              )
              .fadeIn(),
          const SizedBox(height: 20),
          Text(
                slide.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.6,
                ),
              )
              .animate(delay: 100.ms)
              .slideX(
                begin: 0.1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              )
              .fadeIn(),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
