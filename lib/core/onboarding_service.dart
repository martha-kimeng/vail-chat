import 'package:shared_preferences/shared_preferences.dart';

/// Persists a simple flag so onboarding only appears on first launch.
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _key = 'vail_onboarding_complete';

  /// Returns true if the user has already seen onboarding.
  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// Call this when the user finishes (or skips) onboarding.
  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
