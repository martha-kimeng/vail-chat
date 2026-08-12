import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ConversationDoc {
  const ConversationDoc({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.mutualChemistry,
    required this.chemistrySignals,
    required this.createdAt,
    this.otherAlias = 'Stranger',
  });

  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;
  final bool mutualChemistry;
  final List<String> chemistrySignals;
  final DateTime createdAt;

  /// Populated after merging with the users collection — the other
  /// participant's nickname.  Defaults to 'Stranger' until resolved.
  final String otherAlias;

  /// Returns unread count for [uid].
  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  /// Whether [uid] has already signalled chemistry.
  bool hasSignalled(String uid) => chemistrySignals.contains(uid);
}

class MessageDoc {
  const MessageDoc({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isSystem = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isSystem;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class ConversationService {
  ConversationService._();
  static final ConversationService instance = ConversationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No user is currently signed in.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversations.doc(conversationId).collection('messages');

  // ── Conversations stream (Chats tab) ─────────────────────────────────────

  /// Real-time stream of all conversations the current user is part of,
  /// ordered most-recently-active first.
  ///
  /// Each [ConversationDoc] has [otherAlias] set by fetching the other
  /// participant's nickname from the `users` collection in a single batch.
  Stream<List<ConversationDoc>> conversationsStream() {
    final uid = _currentUid;
    return _conversations
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final docs = snap.docs.map(_fromSnap).toList();
      // Collect all unique other-participant UIDs in one pass.
      final otherUids = docs
          .map((d) => d.participants.firstWhere((p) => p != uid,
              orElse: () => ''))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (otherUids.isEmpty) return docs;

      // Batch-fetch nicknames (Firestore `whereIn` supports up to 30 items).
      final Map<String, String> aliases = {};
      // Split into chunks of 30 just in case.
      for (var i = 0; i < otherUids.length; i += 30) {
        final chunk = otherUids.sublist(
            i, i + 30 > otherUids.length ? otherUids.length : i + 30);
        final userSnap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in userSnap.docs) {
          aliases[doc.id] =
              (doc.data()['nickname'] as String?) ?? 'Stranger';
        }
      }

      return docs.map((d) {
        final otherId = d.participants.firstWhere((p) => p != uid,
            orElse: () => '');
        return ConversationDoc(
          id: d.id,
          participants: d.participants,
          lastMessage: d.lastMessage,
          lastMessageAt: d.lastMessageAt,
          unreadCount: d.unreadCount,
          mutualChemistry: d.mutualChemistry,
          chemistrySignals: d.chemistrySignals,
          createdAt: d.createdAt,
          otherAlias: aliases[otherId] ?? 'Stranger',
        );
      }).toList();
    });
  }

  /// Stream filtered to conversations where [mutualChemistry] is true.
  Stream<List<ConversationDoc>> sparkConversationsStream() {
    final uid = _currentUid;
    return _conversations
        .where('participants', arrayContains: uid)
        .where('mutualChemistry', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final docs = snap.docs.map(_fromSnap).toList();
      final otherUids = docs
          .map((d) => d.participants.firstWhere((p) => p != uid,
              orElse: () => ''))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (otherUids.isEmpty) return docs;

      final Map<String, String> aliases = {};
      for (var i = 0; i < otherUids.length; i += 30) {
        final chunk = otherUids.sublist(
            i, i + 30 > otherUids.length ? otherUids.length : i + 30);
        final userSnap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in userSnap.docs) {
          aliases[doc.id] =
              (doc.data()['nickname'] as String?) ?? 'Stranger';
        }
      }

      return docs.map((d) {
        final otherId = d.participants.firstWhere((p) => p != uid,
            orElse: () => '');
        return ConversationDoc(
          id: d.id,
          participants: d.participants,
          lastMessage: d.lastMessage,
          lastMessageAt: d.lastMessageAt,
          unreadCount: d.unreadCount,
          mutualChemistry: d.mutualChemistry,
          chemistrySignals: d.chemistrySignals,
          createdAt: d.createdAt,
          otherAlias: aliases[otherId] ?? 'Stranger',
        );
      }).toList();
    });
  }

  /// One-shot fetch of a single conversation document.
  Future<ConversationDoc?> fetchConversation(String conversationId) async {
    final snap = await _conversations.doc(conversationId).get();
    if (!snap.exists || snap.data() == null) return null;
    return _fromSnap(snap);
  }

  // ── Messages stream ───────────────────────────────────────────────────────

  /// Real-time stream of messages in a conversation, ordered oldest-first.
  Stream<List<MessageDoc>> messagesStream(String conversationId) {
    return _messages(conversationId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(_messageFromSnap).toList());
  }

  // ── Send a message ────────────────────────────────────────────────────────

  /// Writes a new message document and updates the conversation metadata
  /// (lastMessage, lastMessageAt, unreadCount) in a single batch.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required List<String> participants,
  }) async {
    final uid = _currentUid;
    final msgRef = _messages(conversationId).doc();
    final convoRef = _conversations.doc(conversationId);

    // Build the unread increment: +1 for everyone except the sender.
    final unreadUpdate = <String, dynamic>{};
    for (final p in participants) {
      if (p != uid) {
        unreadUpdate['unreadCount.$p'] = FieldValue.increment(1);
      }
    }

    final batch = _db.batch();

    batch.set(msgRef, {
      'senderId': uid,
      'text': text.trim(),
      'sentAt': FieldValue.serverTimestamp(),
      'isSystem': false,
    });

    batch.update(convoRef, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      ...unreadUpdate,
    });

    await batch.commit();
  }

  // ── Mark messages as read ─────────────────────────────────────────────────

  /// Resets the unread counter for the current user on a conversation.
  /// Call this when the user opens a chat screen.
  Future<void> markRead(String conversationId) async {
    final uid = _currentUid;
    await _conversations.doc(conversationId).update({
      'unreadCount.$uid': 0,
    });
  }

  // ── Chemistry / Spark signal ──────────────────────────────────────────────

  /// Adds the current user's UID to [chemistrySignals].
  /// If both participants have signalled, sets [mutualChemistry] to true.
  ///
  /// Uses a Firestore transaction so the mutual check is atomic.
  Future<bool> signalChemistry(String conversationId) async {
    final uid = _currentUid;
    bool isMutual = false;

    await _db.runTransaction((txn) async {
      final snap =
          await txn.get(_conversations.doc(conversationId));
      if (!snap.exists) return;

      final data = snap.data()!;
      final signals = List<String>.from(
          (data['chemistrySignals'] as List<dynamic>?) ?? []);
      final participants = List<String>.from(
          (data['participants'] as List<dynamic>?) ?? []);

      // Idempotent — don't double-add.
      if (!signals.contains(uid)) signals.add(uid);

      isMutual = participants.every((p) => signals.contains(p));

      txn.update(_conversations.doc(conversationId), {
        'chemistrySignals': signals,
        'mutualChemistry': isMutual,
      });
    });

    return isMutual;
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  ConversationDoc _fromSnap(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    final rawUnread = (d['unreadCount'] as Map<dynamic, dynamic>?) ?? {};
    final unread =
        rawUnread.map((k, v) => MapEntry(k.toString(), (v as int?) ?? 0));

    return ConversationDoc(
      id: snap.id,
      participants: List<String>.from(
          (d['participants'] as List<dynamic>?) ?? []),
      lastMessage: (d['lastMessage'] as String?) ?? '',
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: unread,
      mutualChemistry: (d['mutualChemistry'] as bool?) ?? false,
      chemistrySignals: List<String>.from(
          (d['chemistrySignals'] as List<dynamic>?) ?? []),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MessageDoc _messageFromSnap(
      DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    return MessageDoc(
      id: snap.id,
      senderId: (d['senderId'] as String?) ?? '',
      text: (d['text'] as String?) ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystem: (d['isSystem'] as bool?) ?? false,
    );
  }
}
