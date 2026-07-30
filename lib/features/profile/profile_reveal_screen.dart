import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

/// Shown after both users signal chemistry.
/// The "chemistry check" step — both must confirm before any reveal.
class ProfileRevealScreen extends StatefulWidget {
  const ProfileRevealScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  State<ProfileRevealScreen> createState() => _ProfileRevealScreenState();
}

class _ProfileRevealScreenState extends State<ProfileRevealScreen> {
  // Simulated states: waiting → confirmed → revealed
  _RevealState _state = _RevealState.waiting;

  void _confirm() => setState(() => _state = _RevealState.confirmed);
  void _reveal() => setState(() => _state = _RevealState.revealed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const VailGradientBackground(child: SizedBox.expand()),

          // Decorative pulses
          Positioned(
            top: 100,
            left: -60,
            child: _PulseCircle(color: VailColors.rose.withOpacity(0.15), size: 240),
          ),
          Positioned(
            bottom: 160,
            right: -80,
            child: _PulseCircle(color: Color(0xFF9B59B6).withOpacity(0.12), size: 200),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => context.go('/chat/${widget.conversationId}'),
                    ),
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: switch (_state) {
                      _RevealState.waiting => _WaitingView(onConfirm: _confirm),
                      _RevealState.confirmed => _ConfirmedView(onReveal: _reveal),
                      _RevealState.revealed => _RevealedView(
                          conversationId: widget.conversationId),
                    },
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

enum _RevealState { waiting, confirmed, revealed }

// ─── Waiting: "You signalled chemistry. Waiting for them." ─────────────────────
class _WaitingView extends StatelessWidget {
  const _WaitingView({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Two overlapping anonymous avatars
          _DoubleAvatar()
              .animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(),
          const SizedBox(height: 36),
          Text(
            'You felt the spark.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 14),
          Text(
            "We've let them know anonymously. If they feel it too, chemistry is confirmed and you can plan your date.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 15, color: Colors.white70, height: 1.6),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 48),

          // Simulate "they confirmed too" for demo purposes
          OutlinedButton(
            onPressed: onConfirm,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              '✨ Simulate: They confirmed too',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '(Demo only — in real app this happens automatically)',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

// ─── Confirmed: mutual chemistry — ready for reveal ───────────────────────────
class _ConfirmedView extends StatelessWidget {
  const _ConfirmedView({required this.onReveal});
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VailColors.rose.withOpacity(0.2),
              border: Border.all(color: VailColors.rose.withOpacity(0.5), width: 2),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: VailColors.rose, size: 50),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 32),
          Text(
            'It\'s mutual! 🎉',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 14),
          Text(
            'Both of you felt the connection. The next step? A blind date — where you finally see each other for the first time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 15, color: Colors.white70, height: 1.6),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onReveal,
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              'Plan the blind date 💫',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }
}

// ─── Revealed: partial profile shown, date CTA ────────────────────────────────
class _RevealedView extends StatelessWidget {
  const _RevealedView({required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
      child: Column(
        children: [
          // Profile card — still anonymous, just a first-name teaser
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                // Blurred avatar circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [VailColors.rose, Color(0xFF9B59B6)],
                        ),
                      ),
                    ),
                    const Icon(Icons.person_rounded,
                        color: Colors.white, size: 48),
                    // "Revealed" badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: VailColors.rose,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '✨ Revealed',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Alex, 27',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Their first name — that\'s all for now.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.95, 0.95),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/date/$conversationId'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              'Set up the blind date',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/chat/$conversationId'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Keep chatting first',
              style: GoogleFonts.inter(fontSize: 15),
            ),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _DoubleAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 80,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VailColors.rose.withOpacity(0.2),
                border: Border.all(color: Colors.white12, width: 2),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: Colors.white60, size: 36),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF9B59B6).withOpacity(0.2),
                border: Border.all(color: Colors.white12, width: 2),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: Colors.white60, size: 36),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.favorite_rounded, color: VailColors.rose, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseCircle extends StatelessWidget {
  const _PulseCircle({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
          duration: 2400.ms,
          curve: Curves.easeInOut,
        );
  }
}
