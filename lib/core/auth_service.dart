import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth — keeps auth logic out of the UI layer.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The currently signed-in user, or null if not authenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits a [User] on sign-in and null on sign-out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create a new account with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Send a password-reset email.
  /// Throws [FirebaseAuthException] on failure.
  Future<void> sendPasswordReset({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign the current user out.
  Future<void> signOut() => _auth.signOut();

  /// Human-readable message for common [FirebaseAuthException] codes.
  static String messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
