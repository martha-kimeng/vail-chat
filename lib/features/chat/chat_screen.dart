import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
enum _Sender { me, other }

class _Message {
  const _Message({
    required this.text,
    required this.sender,
    required this.time,
    this.isSystem = false,
  });

  final String text;
  final _Sender sender;
  final String time;
  final bool isSystem;
}

final _mockMessages = [
  const _Message(
    text: 'Two anonymous strangers have been connected. Say hi 👋',
    sender: _Sender.other,
    time: '9:00 PM',
    isSystem: true,
  ),
  const _Message(
      text: 'Hey! This is kind of wild — no idea who you are.',
      sender: _Sender.other,
      time: '9:01 PM'),
  const _Message(
      text: 'Right? I kind of love it. Forces you to actually talk.',
      sender: _Sender.me,
      time: '9:02 PM'),
  const _Message(
      text: 'Exactly. So... what\'s something you\'re weirdly passionate about?',
      sender: _Sender.other,
      time: '9:03 PM'),
  const _Message(
      text: 'Old film scores. Like, I will argue at length that Ennio Morricone changed cinema.',
      sender: _Sender.me,
      time: '9:05 PM'),
  const _Message(
      text: 'Oh wow. That\'s not what I expected but I\'m here for it.',
      sender: _Sender.other,
      time: '9:06 PM'),
  const _Message(
      text: 'That playlist you mentioned — I listened all night.',
      sender: _Sender.other,
      time: '11:42 PM'),
];

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
  final List<_Message> _messages = List.from(_mockMessages);
  bool _chemistrySignalled = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(
        text: text,
        sender: _Sender.me,
        time: 'Now',
      ));
      _textCtrl.clear();
    });
    Future.delayed(50.ms, () {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: 300.ms,
        curve: Curves.easeOut,
      );
    });
  }

  void _signalChemistry() {
    setState(() => _chemistrySignalled = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChemistrySheet(
        onConfirm: () {
          Navigator.pop(context);
          context.go('/profile/${widget.conversationId}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Alias derived from id for the mock
    final alias = _aliasFromId(widget.conversationId);

    return Scaffold(
      backgroundColor: VailColors.mist,
      appBar: _ChatAppBar(
        alias: alias,
        chemistrySignalled: _chemistrySignalled,
        onChemistryTap: _signalChemistry,
        onBackTap: () => context.go('/home'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return _MessageBubble(message: msg)
                    .animate(delay: (i * 40).ms)
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.05);
              },
            ),
          ),
          _InputBar(
            controller: _textCtrl,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  String _aliasFromId(String id) {
    const map = {
      'c1': 'NightOwl42',
      'c2': 'DesertSage',
      'c3': 'VelvetEcho',
      'c4': 'CrimsonWave',
      'c5': 'FrostedPine',
    };
    return map[id] ?? 'Stranger';
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.alias,
    required this.chemistrySignalled,
    required this.onChemistryTap,
    required this.onBackTap,
  });

  final String alias;
  final bool chemistrySignalled;
  final VoidCallback onChemistryTap;
  final VoidCallback onBackTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top, left: 8, right: 16),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: VailColors.ink),
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
              child: const Icon(Icons.person_outline_rounded,
                  color: VailColors.rose, size: 22),
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
                        'Anonymous · Online',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: VailColors.inkLight.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chemistry button
            GestureDetector(
              onTap: chemistrySignalled ? null : onChemistryTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: chemistrySignalled
                      ? VailColors.rose
                      : VailColors.roseSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
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
  const _MessageBubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
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
                fontStyle: FontStyle.italic),
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
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                color:
                    isMe ? Colors.white60 : VailColors.inkLight.withOpacity(0.5),
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
                    color: VailColors.inkLight.withOpacity(0.4)),
                filled: true,
                fillColor: VailColors.mist,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                      color: VailColors.rose, width: 1.5),
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
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chemistry bottom sheet ───────────────────────────────────────────────────
class _ChemistrySheet extends StatelessWidget {
  const _ChemistrySheet({required this.onConfirm});
  final VoidCallback onConfirm;

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
            child: const Icon(Icons.favorite_rounded,
                color: VailColors.rose, size: 36),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms,
                  curve: Curves.easeInOut),
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
                fontSize: 14, color: VailColors.inkLight, height: 1.6),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onConfirm,
            child: const Text('Yes, I feel chemistry ✨'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
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
