import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth_service.dart';
import '../../core/theme.dart';
import '../../core/user_profile_service.dart';
import '../../core/vail_request_service.dart';
import '../profile/user_profile.dart';

// ─── Mock data ────────────────────────────────────────────────────────────────
class _Conversation {
  const _Conversation({
    required this.id,
    required this.alias,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.hasChemistry,
    required this.avatarColor,
  });

  final String id;
  final String alias; // Anonymous nickname
  final String lastMessage;
  final String time;
  final int unread;
  final bool hasChemistry; // mutual spark signalled
  final Color avatarColor;
}

final _mockConversations = [
  const _Conversation(
    id: 'c1',
    alias: 'NightOwl42',
    lastMessage: 'That playlist you mentioned — I listened all night.',
    time: '11:42 PM',
    unread: 2,
    hasChemistry: true,
    avatarColor: Color(0xFF9B59B6),
  ),
  const _Conversation(
    id: 'c2',
    alias: 'DesertSage',
    lastMessage: 'Honestly? I think you\'re right about that.',
    time: '9:15 PM',
    unread: 0,
    hasChemistry: false,
    avatarColor: Color(0xFF4A90D9),
  ),
  const _Conversation(
    id: 'c3',
    alias: 'VelvetEcho',
    lastMessage: '😂 ok that was actually hilarious',
    time: 'Yesterday',
    unread: 1,
    hasChemistry: false,
    avatarColor: Color(0xFF27AE60),
  ),
  const _Conversation(
    id: 'c4',
    alias: 'CrimsonWave',
    lastMessage: 'Same time tomorrow?',
    time: 'Yesterday',
    unread: 0,
    hasChemistry: true,
    avatarColor: Color(0xFFE8516A),
  ),
  const _Conversation(
    id: 'c5',
    alias: 'FrostedPine',
    lastMessage: 'You\'ve got a really interesting perspective on this.',
    time: 'Mon',
    unread: 0,
    hasChemistry: false,
    avatarColor: Color(0xFF16A085),
  ),
];

// ─── Avatar menu actions ──────────────────────────────────────────────────────
enum _AvatarAction { profile, signOut }

// ─── Screen ───────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  // Live profile stream — keeps the avatar in sync with Firestore.
  UserProfile? _profile;

  // Live pending Vail Request count — drives the tab badge.
  int _pendingVailCount = 0;

  @override
  void initState() {
    super.initState();
    _subscribeToProfile();
    _subscribeToPendingCount();
  }

  void _subscribeToProfile() {
    try {
      final uid = UserProfileService.instance.currentUid;
      UserProfileService.instance
          .profileStream(uid)
          .listen(
            (profile) {
              if (mounted) setState(() => _profile = profile);
            },
            onError: (_) {
              /* silently ignore stream errors on home */
            },
          );
    } catch (_) {
      // No signed-in user yet — auth redirect will handle navigation.
    }
  }

  void _subscribeToPendingCount() {
    try {
      VailRequestService.instance.pendingCountStream().listen(
        (count) {
          if (mounted) setState(() => _pendingVailCount = count);
        },
        onError: (_) {
          /* keep showing 0 on error */
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VailColors.mist,
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(
              tabIndex: _tabIndex,
              pendingVailCount: _pendingVailCount,
              onTabChanged: (i) => setState(() => _tabIndex = i),
              profile: _profile,
            ),
            Expanded(
              child: _tabIndex == 0
                  ? _ConversationList(conversations: _mockConversations)
                  : _tabIndex == 1
                  ? const _MatchesTab()
                  : const _VailRequestsTab(),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/active-users'),
              backgroundColor: VailColors.rose,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(
                Icons.favorite_border_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                'New Chat',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}

// ─── Header + tab bar ─────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.tabIndex,
    required this.onTabChanged,
    required this.pendingVailCount,
    required this.profile,
  });
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final int pendingVailCount;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vail',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: VailColors.ink,
                    ),
                  ),
                  Text(
                    'Your anonymous conversations',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VailColors.inkLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Avatar — taps to profile or sign out
              PopupMenuButton<_AvatarAction>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (action) async {
                  if (action == _AvatarAction.profile) {
                    context.push('/profile');
                  } else {
                    await AuthService.instance.signOut();
                    if (context.mounted) context.go('/sign-in');
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _AvatarAction.profile,
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text('Profile', style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _AvatarAction.signOut,
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: VailColors.rose,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sign out',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: VailColors.rose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VailColors.rose.withOpacity(0.4),
                      width: 2,
                    ),
                    color: VailColors.roseSoft,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: profile != null
                      ? SvgPicture.network(
                          profile!.avatarUrl,
                          fit: BoxFit.cover,
                          placeholderBuilder: (_) => const Icon(
                            Icons.person_outline_rounded,
                            color: VailColors.rose,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline_rounded,
                          color: VailColors.rose,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tab pills
          Row(
            children: [
              _TabPill(
                label: 'Chats',
                active: tabIndex == 0,
                onTap: () => onTabChanged(0),
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: 'Chemistry ✨',
                active: tabIndex == 1,
                onTap: () => onTabChanged(1),
              ),
              const SizedBox(width: 8),
              _TabPill(
                label: 'Vail Requests',
                active: tabIndex == 2,
                onTap: () => onTabChanged(2),
                badge: pendingVailCount,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: active ? VailColors.rose : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : VailColors.inkLight,
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white : VailColors.rose,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: active ? VailColors.rose : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Conversations list ────────────────────────────────────────────────────────
class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.conversations});
  final List<_Conversation> conversations;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, i) {
        final c = conversations[i];
        return _ConversationTile(conversation: c)
            .animate(delay: (i * 60).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.05);
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});
  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/chat/${conversation.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: VailColors.ink.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Anonymous avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conversation.avatarColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: conversation.avatarColor,
                    size: 26,
                  ),
                ),
                if (conversation.hasChemistry)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: VailColors.rose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        conversation.alias,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: VailColors.ink,
                        ),
                      ),
                      if (conversation.hasChemistry) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VailColors.roseSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Spark',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: VailColors.rose,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        conversation.time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: VailColors.inkLight.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: conversation.unread > 0
                                ? VailColors.ink
                                : VailColors.inkLight.withOpacity(0.7),
                            fontWeight: conversation.unread > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: VailColors.rose,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${conversation.unread}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chemistry / Matches tab ──────────────────────────────────────────────────
class _MatchesTab extends StatelessWidget {
  const _MatchesTab();

  @override
  Widget build(BuildContext context) {
    final sparks = _mockConversations.where((c) => c.hasChemistry).toList();

    return sparks.isEmpty
        ? const _EmptyMatches()
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Mutual chemistry',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: VailColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Both of you felt the spark. Time to take the next step.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: VailColors.inkLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ...sparks.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return _SparkCard(conversation: c)
                    .animate(delay: (i * 80).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.06);
              }),
            ],
          );
  }
}

class _SparkCard extends StatelessWidget {
  const _SparkCard({required this.conversation});
  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VailColors.rose.withOpacity(0.08),
            VailColors.roseDark.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VailColors.rose.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: conversation.avatarColor.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: conversation.avatarColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.alias,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VailColors.ink,
                    ),
                  ),
                  Text(
                    'Mutual spark detected ✨',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VailColors.rose,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/chat/${conversation.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VailColors.rose,
                    side: const BorderSide(color: VailColors.rose),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Chat',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/date/${conversation.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VailColors.rose,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    'Plan Date 💫',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: VailColors.rose.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No sparks yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VailColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'When both of you feel chemistry, it appears here — and you can plan your first meeting.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: VailColors.inkLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vail Requests tab (summary on home, taps through to full screen) ─────────
class _VailRequestsTab extends StatelessWidget {
  const _VailRequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VailRequestDoc>>(
      stream: VailRequestService.instance.incomingRequestsStream(),
      builder: (context, snapshot) {
        final pending = (snapshot.data ?? [])
            .where((r) => r.status == VailRequestStatus.pending)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VailColors.rose.withOpacity(0.9),
                    VailColors.roseDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pending.isEmpty
                        ? 'No pending requests'
                        : '${pending.length} ${pending.length == 1 ? 'person is' : 'people are'} waiting behind the veil',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Will you lift it?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/vail-requests'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: VailColors.rose,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'See all requests',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),

            if (pending.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'PREVIEW',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: VailColors.inkLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ...pending.take(2).toList().asMap().entries.map((e) {
                final req = e.value;
                return _CompactRequestPreview(request: req)
                    .animate(delay: (e.key * 80).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.05);
              }),
              if (pending.length > 2) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/vail-requests'),
                    child: Text(
                      '+ ${pending.length - 2} more',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: VailColors.rose,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _CompactRequestPreview extends StatelessWidget {
  const _CompactRequestPreview({required this.request});
  final VailRequestDoc request;

  // Derive a stable colour from the sender UID.
  Color get _senderColor {
    const palette = [
      Color(0xFF9B59B6),
      Color(0xFF4A90D9),
      Color(0xFF27AE60),
      Color(0xFFE8516A),
      Color(0xFF16A085),
      Color(0xFFE67E22),
      Color(0xFF2980B9),
      Color(0xFF7F8C8D),
    ];
    final index =
        request.senderId.codeUnits.fold(0, (a, b) => a + b) % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final color = _senderColor;
    return GestureDetector(
      onTap: () => context.push('/vail-requests'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: VailColors.ink.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.14),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  request.senderAlias[0],
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.senderAlias,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VailColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.insistenceLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VailColors.inkLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Hearts indicator
            Row(
              children: List.generate(
                request.heartCount.clamp(1, 5),
                (_) => const Padding(
                  padding: EdgeInsets.only(left: 1),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: VailColors.rose,
                    size: 13,
                  ),
                ),
              ),
            ),
            if (request.heartCount > 5) ...[
              const SizedBox(width: 2),
              Text(
                '+${request.heartCount - 5}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: VailColors.rose,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
