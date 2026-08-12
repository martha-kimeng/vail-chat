import 'package:firebase_database/firebase_database.dart';

/// Manages online/offline presence in Firebase Realtime Database.
///
/// Each user's presence lives at `/presence/{uid}`:
/// ```json
/// { "online": true, "lastSeen": <server timestamp> }
/// ```
///
/// The `onDisconnect()` handler is registered immediately after going online,
/// so Firebase will automatically flip `online` to false even if the app
/// crashes or loses connectivity — the server handles it without a client call.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── Go online ─────────────────────────────────────────────────────────────

  /// Call this right after a successful sign-in (or on app resume for an
  /// already signed-in user).
  ///
  /// Registers the onDisconnect handler first so the server-side cleanup is
  /// guaranteed regardless of what happens next.
  Future<void> goOnline(String uid) async {
    final ref = _db.ref('presence/$uid');

    // 1. Register the offline payload — the server will write this
    //    automatically the moment the connection is lost.
    await ref.onDisconnect().set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });

    // 2. Write the online payload.
    await ref.set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });
  }

  // ── Go offline ────────────────────────────────────────────────────────────

  /// Call this on an intentional sign-out so the user appears offline
  /// immediately rather than waiting for the RTDB connection to time out.
  ///
  /// Also cancels the pending onDisconnect handler to avoid a double-write.
  Future<void> goOffline(String uid) async {
    final ref = _db.ref('presence/$uid');

    // Cancel the pending onDisconnect so it doesn't fire after our explicit
    // write below.
    await ref.onDisconnect().cancel();

    await ref.set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Returns a stream that emits the online status map for a single user.
  ///
  /// Emits `null` when the presence node doesn't exist yet.
  Stream<Map<String, dynamic>?> presenceStream(String uid) {
    return _db.ref('presence/$uid').onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return null;
      return Map<String, dynamic>.from(val as Map);
    });
  }

  /// One-shot check — returns true if [uid] is currently online.
  Future<bool> isOnline(String uid) async {
    final snap = await _db.ref('presence/$uid/online').get();
    return (snap.value as bool?) ?? false;
  }

  /// Returns a stream of all UIDs that are currently online.
  ///
  /// Used by ActiveUsersScreen to decorate user cards with a live green dot.
  Stream<Set<String>> onlineUidsStream() {
    return _db
        .ref('presence')
        .orderByChild('online')
        .equalTo(true)
        .onValue
        .map((event) {
      final val = event.snapshot.value;
      if (val == null) return <String>{};
      final map = Map<String, dynamic>.from(val as Map);
      return map.keys.toSet();
    });
  }
}
