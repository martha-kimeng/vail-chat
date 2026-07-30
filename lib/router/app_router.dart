import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/profile/profile_reveal_screen.dart';
import '../features/date/blind_date_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
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
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
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
  ],
);
