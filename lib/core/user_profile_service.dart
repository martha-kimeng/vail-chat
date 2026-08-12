import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/profile/user_profile.dart';

/// Handles all Firestore reads and writes for the `users` collection.
///
/// Every document lives at `users/{uid}` and maps 1-to-1 with [UserProfile].
class UserProfileService {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection reference ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _users.doc(uid);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new profile document for [uid] after sign-up.
  ///
  /// Uses [SetOptions(merge: true)] so a second call (e.g. after a partial
  /// failure) only updates the fields provided rather than wiping the doc.
  Future<void> createProfile({
    required String uid,
    required UserProfile profile,
  }) async {
    await _userDoc(uid).set(_toMap(profile, uid), SetOptions(merge: true));
  }

  /// Overwrites editable fields on an existing profile document.
  ///
  /// Only the fields a user can change on the profile screen are updated;
  /// `createdAt` and `uid` are left untouched.
  Future<void> updateProfile({
    required String uid,
    required UserProfile profile,
  }) async {
    await _userDoc(uid).update({
      'nickname': profile.nickname,
      'email': profile.email,
      'age': profile.age,
      'gender': profile.gender,
      'town': profile.town,
      'interestedIn': profile.interestedIn,
      'occupation': profile.occupation,
      'hobbies': profile.hobbies,
      'maritalStatus': profile.maritalStatus,
      'avatarStyle': profile.avatarStyle,
      'avatarSeed': profile.avatarSeed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches the profile for [uid] once.
  ///
  /// Returns `null` when the document doesn't exist yet (e.g. first launch
  /// after a sign-in on a new device before the write completes).
  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return _fromMap(snap.data()!);
  }

  /// Returns a real-time stream for the signed-in user's profile document.
  ///
  /// Emits a new [UserProfile] whenever the Firestore document changes.
  /// Emits `null` if the document is deleted or doesn't exist.
  Stream<UserProfile?> profileStream(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return _fromMap(snap.data()!);
    });
  }

  // ── Serialisation helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _toMap(UserProfile p, String uid) {
    return {
      'uid': uid,
      'nickname': p.nickname,
      'email': p.email,
      'age': p.age,
      'gender': p.gender,
      'town': p.town,
      'interestedIn': p.interestedIn,
      'occupation': p.occupation,
      'hobbies': p.hobbies,
      'maritalStatus': p.maritalStatus,
      'avatarStyle': p.avatarStyle,
      'avatarSeed': p.avatarSeed,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile _fromMap(Map<String, dynamic> data) {
    return UserProfile(
      nickname: (data['nickname'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      age: (data['age'] as int?) ?? 18,
      gender: (data['gender'] as String?) ?? '',
      town: (data['town'] as String?) ?? '',
      interestedIn: List<String>.from(
        (data['interestedIn'] as List<dynamic>?) ?? [],
      ),
      occupation: (data['occupation'] as String?) ?? '',
      hobbies: (data['hobbies'] as String?) ?? '',
      maritalStatus: (data['maritalStatus'] as String?) ?? '',
      avatarStyle: (data['avatarStyle'] as String?) ?? 'lorelei',
      avatarSeed: (data['avatarSeed'] as String?) ?? 'vail-user-default',
    );
  }

  // ── Convenience ───────────────────────────────────────────────────────────

  /// Returns the UID of the currently signed-in user, or throws if none.
  String get currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No user is currently signed in.');
    return uid;
  }
}
