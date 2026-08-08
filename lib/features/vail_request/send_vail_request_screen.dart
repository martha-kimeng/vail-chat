import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'vail_request_models.dart';

// ─── Send Vail Request Screen ─────────────────────────────────────────────────
// Shown when the current user taps a person from the ActiveUsersScreen.
// They see the styled Vail Request card, can tap hearts to "insist", and
// finally tap "Send Vail Request" to dispatch it.

class SendVailRequestScreen extends StatefulWidget {
  const SendVailRequestScreen({super.key, required this.userId});
  final String userId;

  @override
  State<SendVailRequestScreen> createState() => _SendVailRequestScreenState();
}

class _SendVailRequestScreenState extends State<SendVailRequestScreen>
    with TickerProviderStateMixin {
  late final ActiveUser _user;
  int _heartCount = 0; // starts at 0; first tap = 1 heart (the minimum send)
  bool _sent = false;

  late final AnimationController _heartPulse;

  @override
  void initState() {
    super.initState();
    _user = mockActiveUsers.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => mockActiveUsers.first,
    );
    _heartPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _heartPulse.dispose();
    super.dispose();
  }

  void _addHeart() {
    HapticFeedback.lightImpact();
    setState(() => _heartCount = (_heartCount + 1).clamp(0, 12));
    _heartPulse.forward(from: 0);
  }

  void _send() {
    HapticFeedback.mediumImpact();
    // In a real app: send to backend here.
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const VailGradientBackground(child: SizedBox.expand()),

          // Decorative blobs
          Positioned(
            top: 80,
            left: -70,
            child: _Blob(color: VailColors.rose.withOpacity(0.13), size: 220),
          ),
          Positioned(
            bottom: 120,
            right: -60,
            child: _Blob(
              color: const Color(0xFF9B59B6).withOpacity(0.10),
              size: 190,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
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
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: 500.ms,
                    child: _sent
                        ? _SentView(user: _user)
                        : _ComposeView(
                            key: const ValueKey('compose'),
                            user: _user,
                            heartCount: _heartCount,
                            heartPulse: _heartPulse,
                            onAddHeart: _addHeart,
                            onSend: _send,
                          ),
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

// ─── Compose view ─────────────────────────────────────────────────────────────

class _ComposeView extends StatelessWidget {
  const _ComposeView({
    super.key,
    required this.user,
    required this.heartCount,
    required this.heartPulse,
    required this.onAddHeart,
    required this.onSend,
  });

  final ActiveUser user;
  final int heartCount;
  final AnimationController heartPulse;
  final VoidCallback onAddHeart;
  final VoidCallback onSend;

  // Generates the display hearts row
  Widget _hearts() {
    if (heartCount == 0) return const SizedBox.shrink();
    final show = heartCount.clamp(1, 9);
    final overflow = heartCount > 9 ? heartCount - 9 : 0;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      children: [
        for (int i = 0; i < show; i++)
          AnimatedBuilder(
            animation: heartPulse,
            builder: (_, child) {
              final scale = i == show - 1
                  ? (1.0 + heartPulse.value * 0.4)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: VailColors.rose,
                  size: 18,
                ),
              );
            },
          ),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: VailColors.rose,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = VailRequest(
      id: 'preview',
      senderId: 'me',
      senderAlias: 'You',
      senderAvatarColor: VailColors.rose,
      receiverId: user.id,
      sentAt: DateTime.now(),
      heartCount: heartCount == 0 ? 1 : heartCount,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Title
          Text(
            'Vail Request',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

          const SizedBox(height: 6),

          Text(
            'Lift the veil — start something real.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 28),

          // ── Request card ──────────────────────────────────────────────────
          _RequestCard(
                user: user,
                heartCount: heartCount == 0 ? 1 : heartCount,
                insistenceLabel: req.insistenceLabel,
                message: req.vailMessage,
                heartsWidget: _hearts(),
              )
              .animate(delay: 150.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),

          const SizedBox(height: 28),

          // ── Insistence hint ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap the heart below to show how much you\'d love to connect. Each tap adds a heart that ${user.alias} will see.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 250.ms).fadeIn(),

          const SizedBox(height: 24),

          // ── Heart tap button ───────────────────────────────────────────────
          GestureDetector(
                onTap: onAddHeart,
                child: AnimatedBuilder(
                  animation: heartPulse,
                  builder: (_, child) {
                    final scale = 1.0 + heartPulse.value * 0.25;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [VailColors.rose, VailColors.roseDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VailColors.rose.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              )
              .animate(delay: 300.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

          const SizedBox(height: 8),

          Text(
            heartCount == 0
                ? 'Tap to add hearts'
                : heartCount == 1
                ? '1 heart'
                : '$heartCount hearts',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: heartCount > 0 ? VailColors.rose : Colors.white38,
            ),
          ),

          const SizedBox(height: 32),

          // ── Send button ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: VailColors.rose,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Send Vail Request',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.08),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── The stylised request card (also reused in IncomingVailRequestsScreen) ───

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.user,
    required this.heartCount,
    required this.insistenceLabel,
    required this.message,
    required this.heartsWidget,
  });

  final ActiveUser user;
  final int heartCount;
  final String insistenceLabel;
  final String message;
  final Widget heartsWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          // Avatar + name
          Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user.avatarColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.avatarColor.withOpacity(0.18),
                    ),
                    child: Center(
                      child: Text(
                        user.alias[0],
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: user.avatarColor,
                        ),
                      ),
                    ),
                  ),
                ],
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.04, 1.04),
                duration: 1800.ms,
                curve: Curves.easeInOut,
              ),

          const SizedBox(height: 14),

          Text(
            user.alias,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          // Metadata tags
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CardTag(label: user.location, icon: Icons.location_on_outlined),
              if (user.genderLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                _CardTag(
                  label: user.genderLabel,
                  icon: Icons.person_outline_rounded,
                ),
              ],
              if (user.ageGroupLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                _CardTag(label: user.ageGroupLabel, icon: Icons.cake_outlined),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: Colors.white12),

          const SizedBox(height: 20),

          // Message
          Text(
            '"${VailRequest(id: '', senderId: '', senderAlias: '', senderAvatarColor: Colors.transparent, receiverId: '', sentAt: DateTime.now()).vailMessage}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.white70,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 18),

          // Hearts row
          if (heartCount > 0) ...[heartsWidget, const SizedBox(height: 10)],

          // Insistence label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: VailColors.rose.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VailColors.rose.withOpacity(0.25)),
            ),
            child: Text(
              insistenceLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: VailColors.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTag extends StatelessWidget {
  const _CardTag({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: Colors.white38),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
        ),
      ],
    );
  }
}

// ─── Sent confirmation view ───────────────────────────────────────────────────

class _SentView extends StatelessWidget {
  const _SentView({required this.user});
  final ActiveUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated check / heart
          Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VailColors.rose.withOpacity(0.15),
                  border: Border.all(
                    color: VailColors.rose.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: VailColors.rose,
                  size: 50,
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                curve: Curves.easeOutBack,
                duration: 600.ms,
              )
              .fadeIn(),

          const SizedBox(height: 32),

          Text(
            'Vail Request Sent',
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.08),

          const SizedBox(height: 14),

          Text(
            'Your request drifts through the veil to ${user.alias}. When they choose to unveil, you\'ll both be connected.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white70,
              height: 1.6,
            ),
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 48),

          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Back to home',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.08),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Meet someone else',
              style: GoogleFonts.inter(fontSize: 15),
            ),
          ).animate(delay: 450.ms).fadeIn(),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
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
          begin: const Offset(0.94, 0.94),
          end: const Offset(1.06, 1.06),
          duration: 2800.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ─── Public re-export of _RequestCard for the incoming screen ─────────────────
// We expose a thin wrapper so IncomingVailRequestsScreen can render request cards
// without circular imports.

class VailRequestCard extends StatelessWidget {
  const VailRequestCard({
    super.key,
    required this.request,
    required this.user,
    required this.heartsWidget,
  });

  final VailRequest request;
  final ActiveUser user;
  final Widget heartsWidget;

  @override
  Widget build(BuildContext context) {
    return _RequestCard(
      user: user,
      heartCount: request.heartCount,
      insistenceLabel: request.insistenceLabel,
      message: request.vailMessage,
      heartsWidget: heartsWidget,
    );
  }
}
