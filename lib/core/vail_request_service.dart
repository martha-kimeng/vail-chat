import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Firestore model for a VailRequest document ───────────────────────────────

enum VailRequestStatus { pending, unveiled, declined }

class VailRequestDoc {
  VailRequestDoc({
    required this.id,
    required this.senderId,
    required this.senderAlias,
    required this.receiverId,
    required this.heartCount,
    required this.status,
    required this.sentAt,
    this.conversationId,
  });

  final String id;
  final String senderId;
  final String senderAlias;
  final String receiverId;
  final int heartCount;
  final VailRequestStatus status;
  final DateTime sentAt;
  final String? conversationId; // set after unveil

  /// Sub-label that scales with heart count — mirrors the UI mock logic.
  String get insistenceLabel {
    if (heartCount >= 10) return 'Absolutely enchanted by you ✨';
    if (heartCount >= 7) return 'Really, really hoping you will unveil 💫';
    if (heartCount >= 4) return 'Genuinely curious about you 🌹';
    return 'Sending you a gentle knock 🪄';
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────

class VailRequestService {
  VailRequestService._();
  static final VailRequestService instance = VailRequestService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('vailRequests');

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No user is currently signed in.');
    return uid;
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  /// Writes a new vailRequest document from the current user to [receiverId].
  ///
  /// [senderAlias] is the current user's nickname (fetched by the caller from
  /// UserProfileService so this service stays single-responsibility).
  Future<String> sendRequest({
    required String receiverId,
    required String senderAlias,
    required int heartCount,
  }) async {
    final uid = _currentUid;
    final doc = _requests.doc(); // auto-ID
    await doc.set({
      'senderId': uid,
      'senderAlias': senderAlias,
      'receiverId': receiverId,
      'heartCount': heartCount.clamp(1, 12),
      'status': 'pending',
      'sentAt': FieldValue.serverTimestamp(),
      'conversationId': null,
    });
    return doc.id;
  }

  // ── Listen (incoming) ────────────────────────────────────────────────────

  /// Real-time stream of all requests sent TO the current user.
  Stream<List<VailRequestDoc>> incomingRequestsStream() {
    final uid = _currentUid;
    return _requests
        .where('receiverId', isEqualTo: uid)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromSnap).toList());
  }

  /// Real-time stream of pending requests count — used for badge on HomeScreen.
  Stream<int> pendingCountStream() {
    final uid = _currentUid;
    return _requests
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Respond ───────────────────────────────────────────────────────────────

  /// Accepts a Vail Request:
  ///   1. Creates a `conversations/{id}` document.
  ///   2. Updates the vailRequest with status = "unveiled" and the new convo id.
  ///
  /// Returns the new [conversationId] so the caller can navigate to chat.
  Future<String> unveil(VailRequestDoc request) async {
    final uid = _currentUid;

    // 1. Create the conversation document.
    final convoRef = _conversations.doc();
    await convoRef.set({
      'participants': [request.senderId, uid],
      'vailRequestId': request.id,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'chemistrySignals': <String>[],
      'mutualChemistry': false,
      // Track unread counts per participant.
      'unreadCount': {request.senderId: 0, uid: 0},
    });

    // 2. Update the request status.
    await _requests.doc(request.id).update({
      'status': 'unveiled',
      'conversationId': convoRef.id,
    });

    return convoRef.id;
  }

  /// Declines a Vail Request — simply updates status to "declined".
  Future<void> decline(String requestId) async {
    await _requests.doc(requestId).update({'status': 'declined'});
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  VailRequestDoc _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    return VailRequestDoc(
      id: snap.id,
      senderId: (d['senderId'] as String?) ?? '',
      senderAlias: (d['senderAlias'] as String?) ?? 'Stranger',
      receiverId: (d['receiverId'] as String?) ?? '',
      heartCount: (d['heartCount'] as int?) ?? 1,
      status: _parseStatus(d['status'] as String?),
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      conversationId: d['conversationId'] as String?,
    );
  }

  VailRequestStatus _parseStatus(String? s) => switch (s) {
    'unveiled' => VailRequestStatus.unveiled,
    'declined' => VailRequestStatus.declined,
    _ => VailRequestStatus.pending,
  };
}
