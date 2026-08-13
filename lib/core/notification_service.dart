import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// ─── Background message handler ───────────────────────────────────────────────
// Must be a top-level function — Flutter's isolate requirement for FCM.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase initialisation is handled automatically by the plugin for
  // background isolates.  Nothing extra needed here — the system tray
  // notification is displayed by FCM itself when the payload contains a
  // `notification` object.  If you later need silent data-only messages
  // processed in the background, add logic here.
  debugPrint('[FCM background] ${message.messageId}');
}

/// Manages FCM token lifecycle and foreground notification display.
///
/// Call [init] once on app start (after Firebase.initializeApp).
/// Call [saveTokenForUser] after every sign-in/sign-up so the token stored
/// in Firestore stays fresh (tokens rotate periodically).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Call once in main() after Firebase.initializeApp().
  Future<void> init() async {
    // Register the background handler first — must happen before any other
    // FirebaseMessaging calls.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // On Android 13+ (API 33+) a runtime permission is required.
    // On earlier Android versions this is a no-op.
    await _requestPermission();

    // Handle messages that arrive while the app is in the foreground.
    // (Background / terminated messages are handled by the OS notification
    //  tray automatically when the FCM payload has a 'notification' object.)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // When the user taps a notification that brought the app to the
    // foreground from background state, this fires immediately.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // If the app was fully terminated and launched via a notification,
    // getInitialMessage() returns that message once.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);

    // Listen for token rotation and persist the new token automatically.
    _fcm.onTokenRefresh.listen((token) {
      _persistToken(token);
    });
  }

  // ── Permission (Android 13+ / API 33+) ───────────────────────────────────

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  // ── Token management ──────────────────────────────────────────────────────

  /// Fetches the current FCM token and saves it to `users/{uid}/fcmToken`.
  ///
  /// Call after every successful sign-in and sign-up because the token may
  /// have rotated since the last session.
  Future<void> saveTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _persistToken(token, uid: uid);
    } catch (e) {
      debugPrint('[FCM] saveTokenForUser failed: $e');
    }
  }

  Future<void> _persistToken(String token, {String? uid}) async {
    final resolvedUid =
        uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUid == null) return;
    try {
      await _db.collection('users').doc(resolvedUid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FCM] _persistToken failed: $e');
    }
  }

  // ── Foreground message handler ────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    // On Android the system tray does NOT show a heads-up notification
    // when the app is in the foreground — the OS suppresses it.
    // The standard pattern is to show an in-app banner instead.
    // For now we just log; a future iteration can show a SnackBar/overlay.
    debugPrint(
      '[FCM foreground] '
      '${message.notification?.title}: ${message.notification?.body}',
    );
  }

  // ── Notification tap handler ──────────────────────────────────────────────

  void _handleNotificationTap(RemoteMessage message) {
    // Route the user based on the data payload written by Cloud Functions.
    //   data.type = 'message'       → data.conversationId
    //   data.type = 'vail_request'  → navigate to /vail-requests
    //   data.type = 'chemistry'     → data.conversationId
    //
    // Routing is intentionally not wired here yet because GoRouter's context
    // isn't available at this point in the lifecycle.  Store the pending
    // route and consume it from the router once the widget tree is built.
    // For now we log so the plumbing is clear.
    debugPrint('[FCM tap] data: ${message.data}');
  }
}
