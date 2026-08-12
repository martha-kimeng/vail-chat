import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../core/auth_service.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/profile/profile_reveal_screen.dart';
import '../features/date/blind_date_screen.dart';
import '../features/vail_request/active_users_screen.dart';
import '../features/vail_request/send_vail_request_screen.dart';
import '../features/vail_request/incoming_vail_requests_screen.dart';
import '../features/profile/profile_screen.dart';

/// Routes that are accessible without being signed in.
const _publicRoutes = {'/sign-in', '/sign-up', '/onboarding'};

final appRouter = GoRouter(
  initialLocation: '/sign-in',
  // Rebuild the router whenever auth state changes so the redirect fires.
  refreshListenable: _AuthNotifier(),
  redirect: (context, state) {
    final signedIn = AuthService.instance.currentUser != null;
    final isPublic = _publicRoutes.contains(state.matchedLocation);

    // Signed-in user trying to reach a public page → send to home.
    if (signedIn && isPublic) return '/home';

    // Unauthenticated user trying to reach a protected page → send to sign-in.
    if (!signedIn && !isPublic) return '/sign-in';

    // No redirect needed.
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) =>
          ChatScreen(conversationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/profile/:id',
      builder: (context, state) =>
          ProfileRevealScreen(conversationId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/date/:id',
      builder: (context, state) =>
          BlindDateScreen(conversationId: state.pathParameters['id']!),
    ),
    // ── Vail Request flow ────────────────────────────────────────────────────
    GoRoute(
      path: '/active-users',
      builder: (context, state) => const ActiveUsersScreen(),
    ),
    GoRoute(
      path: '/vail-request/send/:userId',
      builder: (context, state) =>
          SendVailRequestScreen(userId: state.pathParameters['userId']!),
    ),
    GoRoute(
      path: '/vail-requests',
      builder: (context, state) => const IncomingVailRequestsScreen(),
    ),
    // ── Profile ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

/// A [ChangeNotifier] that listens to Firebase auth state changes and notifies
/// GoRouter so the redirect callback is re-evaluated on sign-in/sign-out.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    AuthService.instance.authStateChanges.listen((_) => notifyListeners());
  }
}
