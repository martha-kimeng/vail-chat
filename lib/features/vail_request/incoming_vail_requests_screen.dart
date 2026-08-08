import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'vail_request_models.dart';

// ─── Incoming Vail Requests Screen ───────────────────────────────────────────
// The receiver sees all pending Vail Requests here.
// Each card shows: sender alias, heart count, insistence label, and the
// automated vail message.  They can "Unveil" (accept) or "Stay Veiled" (decline).

class IncomingVailRequestsScreen extends StatefulWidget {
  const IncomingVailRequestsScreen({super.key});

  @override
  State<IncomingVailRequestsScreen> createState() =>
      _IncomingVailRequestsScreenState();
}

class _IncomingVailRequestsScreenState
    extends State<IncomingVailRequestsScreen> {
  // Local copy so we can mutate without touching the global list in a demo
  final List<VailRequest> _requests = List.from(mockIncomingRequests);

  void _unveil(VailRequest req) {
    HapticFeedback.mediumImpact();
    setState(() => req.status = VailRequestStatus.unveiled);
    Future.delayed(1200.ms, () {
      if (!mounted) return;
      // In a real app this would navigate to the newly created chat thread.
      // For the demo we use a fixed conversation ID.
      context.push('/chat/new-${req.id}');
    });
  }

  void _decline(VailRequest req) {
    HapticFeedback.lightImpact();
    setState(() => req.status = VailRequestStatus.declined);
  }

  List<VailRequest> get _pending =>
      _requests.where((r) => r.status == VailRequestStatus.pending).toList();

  List<VailRequest> get _resolved => _requests
      .where((r) => r.status != VailRequestStatus.pending)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const VailGradientBackground(child: SizedBox.expand()),

          Positioned(
            top: 60,
            left: -80,
            child: _PulseBlob(
                color: VailColors.rose.withOpacity(0.10), size: 260),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: _PulseBlob(
                color: const Color(0xFF9B59B6).withOpacity(0.09), size: 200),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: _requests.every(
                          (r) => r.status != VailRequestStatus.pending)
                      ? _buildAllDone()
                      : _buildList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vail Requests',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Someone stands behind the veil…',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const Spacer(),
          if (_pending.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: VailColors.rose.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: VailColors.rose.withOpacity(0.4)),
              ),
              child: Text(
                '${_pending.length} pending',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VailColors.rose,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── list ─────────────────────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Pending section
        if (_pending.isNotEmpty) ...[
          _sectionLabel('Waiting for you'),
          const SizedBox(height: 12),
          ..._pending.asMap().entries.map((e) {
            final i = e.key;
            final req = e.value;
            return _IncomingRequestCard(
              request: req,
              onUnveil: () => _unveil(req),
              onDecline: () => _decline(req),
            )
                .animate(delay: (i * 80).ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.06, curve: Curves.easeOut);
          }),
        ],

        // Resolved section
        if (_resolved.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Resolved'),
          const SizedBox(height: 12),
          ..._resolved.map((req) => _ResolvedChip(request: req)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white38,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildAllDone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white38, size: 56),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending Vail Requests right now.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// ─── Individual incoming request card ────────────────────────────────────────

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.request,
    required this.onUnveil,
    required this.onDecline,
  });

  final VailRequest request;
  final VoidCallback onUnveil;
  final VoidCallback onDecline;

  // Build the hearts row
  Widget _buildHearts() {
    final count = request.heartCount.clamp(1, 9);
    final overflow = request.heartCount > 9 ? request.heartCount - 9 : 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 2,
          children: [
            for (int i = 0; i < count; i++)
              Icon(
                Icons.favorite_rounded,
                color: VailColors.rose,
                size: _heartSize(i, count),
              )
                  .animate(delay: (i * 60).ms)
                  .scale(
                      begin: const Offset(0.3, 0.3),
                      curve: Curves.easeOutBack,
                      duration: 400.ms)
                  .fadeIn(duration: 300.ms),
          ],
        ),
        if (overflow > 0) ...[
          const SizedBox(width: 4),
          Text(
            '+$overflow',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: VailColors.rose,
            ),
          ),
        ],
      ],
    );
  }

  // Make the first heart slightly bigger for visual weight
  double _heartSize(int index, int total) {
    if (total == 1) return 22;
    if (index == 0) return 20;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
      ),
      child: Column(
        children: [
          // Top: sender info + hearts
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: request.senderAvatarColor.withOpacity(0.3),
                            width: 2),
                      ),
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: request.senderAvatarColor.withOpacity(0.16),
                      ),
                      child: Center(
                        child: Text(
                          request.senderAlias[0],
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: request.senderAvatarColor,
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
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 12),

                // Alias + time ago
                Text(
                  request.senderAlias,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(request.sentAt),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white38),
                ),

                const SizedBox(height: 16),

                // Divider
                Container(height: 1, color: Colors.white10),

                const SizedBox(height: 16),

                // Vail message
                Text(
                  '"${request.vailMessage}"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white60,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 16),

                // Hearts
                _buildHearts(),

                const SizedBox(height: 10),

                // Insistence badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: VailColors.rose.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: VailColors.rose.withOpacity(0.25)),
                  ),
                  child: Text(
                    request.insistenceLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: VailColors.rose,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom: action buttons
          Container(
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: Colors.white.withOpacity(0.09))),
            ),
            child: Row(
              children: [
                // Decline
                Expanded(
                  child: TextButton(
                    onPressed: onDecline,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24)),
                      ),
                    ),
                    child: Text(
                      'Stay Veiled',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),

                // Divider
                Container(
                    width: 1,
                    height: 48,
                    color: Colors.white.withOpacity(0.09)),

                // Unveil
                Expanded(
                  child: TextButton(
                    onPressed: onUnveil,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(24)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: VailColors.rose, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Unveil',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: VailColors.rose,
                          ),
                        ),
                      ],
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Resolved chip (compact) ──────────────────────────────────────────────────

class _ResolvedChip extends StatelessWidget {
  const _ResolvedChip({required this.request});
  final VailRequest request;

  @override
  Widget build(BuildContext context) {
    final isUnveiled = request.status == VailRequestStatus.unveiled;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: request.senderAvatarColor.withOpacity(0.14),
            ),
            child: Center(
              child: Text(
                request.senderAlias[0],
                style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: request.senderAvatarColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              request.senderAlias,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUnveiled
                  ? VailColors.online.withOpacity(0.12)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isUnveiled
                      ? Icons.favorite_rounded
                      : Icons.visibility_off_outlined,
                  size: 12,
                  color: isUnveiled ? VailColors.online : Colors.white38,
                ),
                const SizedBox(width: 4),
                Text(
                  isUnveiled ? 'Unveiled' : 'Declined',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUnveiled ? VailColors.online : Colors.white38,
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

// ─── Blob helper ─────────────────────────────────────────────────────────────

class _PulseBlob extends StatelessWidget {
  const _PulseBlob({required this.color, required this.size});
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
          begin: const Offset(0.93, 0.93),
          end: const Offset(1.07, 1.07),
          duration: 3000.ms,
          curve: Curves.easeInOut,
        );
  }
}
