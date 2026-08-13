import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/conversation_service.dart';
import '../../core/theme.dart';

// ─── Internal display model ───────────────────────────────────────────────────
// Keeps UI widgets decoupled from Firestore types.

enum _Sender { me, other }

class _Message {
  const _Message({
    required this.text,
    required this.sender,
    required this.time,
    this.isSystem = false,
    this.isSparkNotification = false,
  });

  final String text;
  final _Sender sender;
  final String time;
  final bool isSystem;
  final bool isSparkNotification;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Loaded from Firestore — null until the first stream event.
  ConversationDoc? _conversation;
  bool _chemistrySignalled = false;
  bool _sendingChemistry = false;

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final doc = await ConversationService.instance.fetchConversation(
      widget.conversationId,
    );
    if (!mounted) return;
    if (doc != null) {
      setState(() {
        _conversation = doc;
        // If the current user already signalled before opening chat,
        // reflect that in the button state.
        _chemistrySignalled = doc.hasSignalled(_uid);
      });
      // Reset unread counter for this user.
      await ConversationService.instance.markRead(widget.conversationId);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Send ─────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();

    final participants = _conversation?.participants ?? [_uid];
    await ConversationService.instance.sendMessage(
      conversationId: widget.conversationId,
      text: text,
      participants: participants,
    );

    // Scroll to bottom after the stream rebuilds.
    Future.delayed(80.ms, () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Chemistry / Spark ─────────────────────────────────────────────────────

  void _onChemistryTap() {
    if (_chemistrySignalled || _sendingChemistry) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChemistrySheet(
        onConfirm: () async {
          Navigator.pop(context);
          await _signalChemistry();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _signalChemistry() async {
    setState(() => _sendingChemistry = true);
    try {
      final isMutual = await ConversationService.instance.signalChemistry(
        widget.conversationId,
      );

      // Notify the other participant with a system message.
      // We do this regardless of mutual status — if mutual, both parties
      // already navigated to the reveal screen, so the message acts as a
      // record in the thread either way.
      final participants = _conversation?.participants ?? [_uid];
      await ConversationService.instance.sendSparkNotification(
        conversationId: widget.conversationId,
        participants: participants,
      );

      if (!mounted) return;
      setState(() {
        _chemistrySignalled = true;
        _sendingChemistry = false;
      });
      if (isMutual) {
        // Both parties felt it — navigate to the profile reveal screen.
        context.go('/profile/${widget.conversationId}');
      }
    } catch (_) {
      if (mounted) setState(() => _sendingChemistry = false);
    }
  }

  // ── Map Firestore message to display model ────────────────────────────────

  _Message _toDisplayMessage(MessageDoc m) {
    final time = _formatTime(m.sentAt);
    if (m.isSystem) {
      return _Message(
        text: m.text,
        sender: _Sender.other,
        time: time,
        isSystem: true,
        isSparkNotification: m.isSparkNotification,
      );
    }
    return _Message(
      text: m.text,
      sender: m.senderId == _uid ? _Sender.me : _Sender.other,
      time: time,
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Derive alias: use the other participant's name from the conversation doc,
    // or fall back to 'Stranger' while loading.
    final alias = _conversation != null
        ? _conversation!.otherAlias
        : 'Stranger';

    return Scaffold(
      backgroundColor: VailColors.mist,
      appBar: _ChatAppBar(
        alias: alias,
        chemistrySignalled: _chemistrySignalled,
        sendingChemistry: _sendingChemistry,
        onChemistryTap: _onChemistryTap,
        onBackTap: () => context.go('/home'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageDoc>>(
              stream: ConversationService.instance.messagesStream(
                widget.conversationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: VailColors.rose),
                  );
                }
                final messages = (snapshot.data ?? [])
                    .map(_toDisplayMessage)
                    .toList();

                // Auto-scroll when new messages arrive.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients &&
                      _scrollCtrl.position.maxScrollExtent > 0) {
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent,
                      duration: 200.ms,
                      curve: Curves.easeOut,
                    );
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: VailColors.inkLight.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Say hello 👋',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: VailColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return _MessageBubble(
                          message: msg,
                          onSparkTap: _onChemistryTap,
                        )
                        .animate(delay: (i * 40).ms)
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: 0.05);
                  },
                );
              },
            ),
          ),
          _InputBar(controller: _textCtrl, onSend: _send),
        ],
      ),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.alias,
    required this.chemistrySignalled,
    required this.sendingChemistry,
    required this.onChemistryTap,
    required this.onBackTap,
  });

  final String alias;
  final bool chemistrySignalled;
  final bool sendingChemistry;
  final VoidCallback onChemistryTap;
  final VoidCallback onBackTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 16,
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: VailColors.ink,
              ),
              onPressed: onBackTap,
            ),
            // Anonymous avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VailColors.rose.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: VailColors.rose,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alias,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: VailColors.ink,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: VailColors.online,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Anonymous · identity hidden',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: VailColors.inkLight.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chemistry button
            GestureDetector(
              onTap: (chemistrySignalled || sendingChemistry)
                  ? null
                  : onChemistryTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: chemistrySignalled
                      ? VailColors.rose
                      : VailColors.roseSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: sendingChemistry
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VailColors.rose,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            chemistrySignalled
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 14,
                            color: chemistrySignalled
                                ? Colors.white
                                : VailColors.rose,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chemistrySignalled ? 'Sparked!' : 'Spark',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: chemistrySignalled
                                  ? Colors.white
                                  : VailColors.rose,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onSparkTap});
  final _Message message;
  final VoidCallback onSparkTap;

  @override
  Widget build(BuildContext context) {
    // Spark notification — tappable card with a CTA to send spark back.
    if (message.isSystem && message.isSparkNotification) {
      return GestureDetector(
        onTap: onSparkTap,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VailColors.rose.withOpacity(0.12),
                  VailColors.rose.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VailColors.rose.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: VailColors.rose,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '✨ Someone sent you a spark!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VailColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to send yours back',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: VailColors.rose,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Plain system message (e.g. conversation start events).
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: VailColors.ink.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: VailColors.inkLight.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final isMe = message.sender == _Sender.me;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? VailColors.bubbleSelf : VailColors.bubbleOther,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: VailColors.ink.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isMe ? Colors.white : VailColors.ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isMe
                    ? Colors.white60
                    : VailColors.inkLight.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 15, color: VailColors.ink),
              decoration: InputDecoration(
                hintText: 'Type something...',
                hintStyle: GoogleFonts.inter(
                  color: VailColors.inkLight.withOpacity(0.4),
                ),
                filled: true,
                fillColor: VailColors.mist,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: VailColors.rose,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: VailColors.rose,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chemistry bottom sheet ───────────────────────────────────────────────────
class _ChemistrySheet extends StatelessWidget {
  const _ChemistrySheet({required this.onConfirm, required this.onCancel});
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VailColors.ink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VailColors.rose.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: VailColors.rose,
                  size: 36,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 20),
          Text(
            'Signal the spark?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: VailColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "If the feeling is mutual, both of you will be notified and you can plan a blind date. They won't know unless they feel it too.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: VailColors.inkLight,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onConfirm,
            child: const Text('Yes, I feel chemistry ✨'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Not yet',
              style: GoogleFonts.inter(color: VailColors.inkLight),
            ),
          ),
        ],
      ),
    );
  }
}
