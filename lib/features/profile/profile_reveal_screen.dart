import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

/// Shown after both users signal chemistry.
/// Streams the conversation document — as soon as mutualChemistry flips
/// to true the screen advances automatically from waiting → confirmed.
class ProfileRevealScreen extends StatefulWidget {
  const ProfileRevealScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  State<ProfileRevealScreen> createState() => _ProfileRevealScreenState();
}

class _ProfileRevealScreenState extends State<ProfileRevealScreen> {
  _RevealState _state = _RevealState.waiting;

  // Other participant's display info (loaded from Firestore).
  String _otherFirstName = '';
  int _otherAge = 0;
  bool _loadingProfile = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _convoSub;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadOtherProfile();
    _subscribeToConversation();
  }

  // ── Load the other participant's name + age ─────────────────────────────

  Future<void> _loadOtherProfile() async {
    try {
      final convoSnap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (!convoSnap.exists || convoSnap.data() == null) return;
      final data = convoSnap.data()!;

      // If mutualChemistry is already true when we arrive, skip straight
      // to confirmed (user navigated back here after both already sparked).
      final alreadyMutual = (data['mutualChemistry'] as bool?) ?? false;

      final participants = List<String>.from(
        (data['participants'] as List?) ?? [],
      );
      final otherId = participants.firstWhere(
        (p) => p != _uid,
        orElse: () => '',
      );

      if (otherId.isEmpty) return;

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherId)
          .get();

      if (!mounted) return;

      final ud = userSnap.data() ?? {};
      final fullNickname = (ud['nickname'] as String?) ?? 'Stranger';
      // Show only the first "word" of the nickname as a first-name teaser.
      final firstName = fullNickname.split(' ').first;
      final age = (ud['age'] as int?) ?? 0;

      setState(() {
        _otherFirstName = firstName;
        _otherAge = age;
        _loadingProfile = false;
        if (alreadyMutual) _state = _RevealState.confirmed;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  // ── Stream conversation for live mutualChemistry updates ────────────────

  void _subscribeToConversation() {
    _convoSub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .snapshots()
        .listen((snap) {
          if (!mounted || snap.data() == null) return;
          final mutual = (snap.data()!['mutualChemistry'] as bool?) ?? false;
          if (mutual && _state == _RevealState.waiting) {
            setState(() => _state = _RevealState.confirmed);
          }
        });
  }

  @override
  void dispose() {
    _convoSub?.cancel();
    super.dispose();
  }

  void _reveal() => setState(() => _state = _RevealState.revealed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const VailGradientBackground(child: SizedBox.expand()),

          Positioned(
            top: 100,
            left: -60,
            child: _PulseCircle(
              color: VailColors.rose.withOpacity(0.15),
              size: 240,
            ),
          ),
          Positioned(
            bottom: 160,
            right: -80,
            child: _PulseCircle(
              color: const Color(0xFF9B59B6).withOpacity(0.12),
              size: 200,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () =>
                          context.go('/chat/${widget.conversationId}'),
                    ),
                  ),
                ),
                Expanded(
                  child: _loadingProfile
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: switch (_state) {
                            _RevealState.waiting => _WaitingView(
                              key: const ValueKey('waiting'),
                            ),
                            _RevealState.confirmed => _ConfirmedView(
                              key: const ValueKey('confirmed'),
                              onReveal: _reveal,
                            ),
                            _RevealState.revealed => _RevealedView(
                              key: const ValueKey('revealed'),
                              conversationId: widget.conversationId,
                              firstName: _otherFirstName,
                              age: _otherAge,
                            ),
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

// ─── Waiting: "You signalled — waiting for them" ──────────────────────────────
class _WaitingView extends StatelessWidget {
  const _WaitingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            "We've let them know anonymously. This page will update the moment they feel it too.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white70,
              height: 1.6,
            ),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 40),
          // Live pulse indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: VailColors.online,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms),
              const SizedBox(width: 8),
              Text(
                'Waiting for their signal…',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              ),
            ],
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ─── Confirmed: mutual — ready to plan a date ─────────────────────────────────
class _ConfirmedView extends StatelessWidget {
  const _ConfirmedView({super.key, required this.onReveal});
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
                  border: Border.all(
                    color: VailColors.rose.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: VailColors.rose,
                  size: 50,
                ),
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
              fontSize: 15,
              color: Colors.white70,
              height: 1.6,
            ),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onReveal,
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Plan the blind date 💫',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }
}

// ─── Revealed: first-name teaser + date CTA ───────────────────────────────────
class _RevealedView extends StatelessWidget {
  const _RevealedView({
    super.key,
    required this.conversationId,
    required this.firstName,
    required this.age,
  });
  final String conversationId;
  final String firstName;
  final int age;

  @override
  Widget build(BuildContext context) {
    final displayName = age > 0 ? '$firstName, $age' : firstName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
      child: Column(
        children: [
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [VailColors.rose, Color(0xFF9B59B6)],
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: VailColors.rose,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '✨ Revealed',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
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
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
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
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Set up the blind date',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
                borderRadius: BorderRadius.circular(14),
              ),
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
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white60,
                size: 36,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9B59B6).withOpacity(0.2),
                border: Border.all(color: Colors.white12, width: 2),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white60,
                size: 36,
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.favorite_rounded,
                color: VailColors.rose,
                size: 22,
              ),
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
