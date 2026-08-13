import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'conversation_service.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum DateProposalStatus { pending, accepted, declined, countered }

enum DateType { coffee, dinner, walk, activity }

class DateProposalDoc {
  const DateProposalDoc({
    required this.id,
    required this.conversationId,
    required this.proposedBy,
    required this.participants,
    required this.dateType,
    required this.proposedDate,
    required this.proposedTime,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String proposedBy; // UID of the user who proposed
  final List<String> participants;
  final DateType dateType;
  final DateTime proposedDate;
  final String proposedTime; // e.g. "19:00"
  final DateProposalStatus status;
  final DateTime createdAt;

  bool get isPending => status == DateProposalStatus.pending;
  bool get isAccepted => status == DateProposalStatus.accepted;

  String get dateTypeLabel => switch (dateType) {
    DateType.coffee => 'Coffee',
    DateType.dinner => 'Dinner',
    DateType.walk => 'Walk',
    DateType.activity => 'Activity',
  };
}

// ─── Service ──────────────────────────────────────────────────────────────────

class DateService {
  DateService._();
  static final DateService instance = DateService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _dates =>
      _db.collection('dates');

  String get _currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No user is currently signed in.');
    return uid;
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Writes a new date proposal and sends an in-chat notification message.
  /// Returns the new document ID.
  Future<String> createProposal({
    required String conversationId,
    required List<String> participants,
    required DateType dateType,
    required DateTime proposedDate,
    required String proposedTime,
  }) async {
    final uid = _currentUid;
    final doc = _dates.doc();
    await doc.set({
      'conversationId': conversationId,
      'proposedBy': uid,
      'participants': participants,
      'dateType': dateType.name,
      'proposedDate': Timestamp.fromDate(proposedDate),
      'proposedTime': proposedTime,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Build a human-readable summary for the in-chat notification card.
    final typeLabel = switch (dateType) {
      DateType.coffee => 'Coffee',
      DateType.dinner => 'Dinner',
      DateType.walk => 'Walk',
      DateType.activity => 'Activity',
    };
    final dateDetails =
        '$typeLabel · ${proposedDate.day}/${proposedDate.month}/${proposedDate.year} · $proposedTime';

    // Fire-and-forget — a failure here shouldn't surface to the proposer.
    try {
      await ConversationService.instance.sendDateProposalNotification(
        conversationId: conversationId,
        participants: participants,
        proposalId: doc.id,
        dateDetails: dateDetails,
      );
    } catch (_) {
      // Notification is best-effort; the proposal itself was saved.
    }

    return doc.id;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Real-time stream of the most recent proposal for a conversation.
  /// Emits null when no proposal exists yet.
  Stream<DateProposalDoc?> proposalStream(String conversationId) {
    return _dates
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : _fromSnap(snap.docs.first));
  }

  // ── Respond ───────────────────────────────────────────────────────────────

  /// Accepts the proposal.
  Future<void> accept(String proposalId) async {
    await _dates.doc(proposalId).update({'status': 'accepted'});
  }

  /// Declines the proposal.
  Future<void> decline(String proposalId) async {
    await _dates.doc(proposalId).update({'status': 'declined'});
  }

  /// Submits a counter-proposal: marks the old one as countered and
  /// creates a fresh proposal with the new details.
  Future<String> counter({
    required String oldProposalId,
    required String conversationId,
    required List<String> participants,
    required DateType dateType,
    required DateTime proposedDate,
    required String proposedTime,
  }) async {
    await _dates.doc(oldProposalId).update({'status': 'countered'});
    return createProposal(
      conversationId: conversationId,
      participants: participants,
      dateType: dateType,
      proposedDate: proposedDate,
      proposedTime: proposedTime,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  DateProposalDoc _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    return DateProposalDoc(
      id: snap.id,
      conversationId: (d['conversationId'] as String?) ?? '',
      proposedBy: (d['proposedBy'] as String?) ?? '',
      participants: List<String>.from(
        (d['participants'] as List<dynamic>?) ?? [],
      ),
      dateType: _parseDateType(d['dateType'] as String?),
      proposedDate:
          (d['proposedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      proposedTime: (d['proposedTime'] as String?) ?? '',
      status: _parseStatus(d['status'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  DateType _parseDateType(String? s) => switch (s) {
    'dinner' => DateType.dinner,
    'walk' => DateType.walk,
    'activity' => DateType.activity,
    _ => DateType.coffee,
  };

  DateProposalStatus _parseStatus(String? s) => switch (s) {
    'accepted' => DateProposalStatus.accepted,
    'declined' => DateProposalStatus.declined,
    'countered' => DateProposalStatus.countered,
    _ => DateProposalStatus.pending,
  };
}
