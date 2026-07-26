/// Animation durations and curves used across the app.
/// All motion references should use these constants for consistency.
class AnimationConfig {
  AnimationConfig._();

  // --- Orb ---
  static const Duration orbBreathingCycle = Duration(milliseconds: 3000);
  static const Duration orbTransitionDuration = Duration(milliseconds: 600);

  // --- Status Badge ---
  static const Duration statusFadeDuration = Duration(milliseconds: 300);

  // --- Conversation Panel ---
  static const Duration messageSlideIn = Duration(milliseconds: 250);

  // --- Power Button ---
  static const Duration powerToggleDuration = Duration(milliseconds: 400);

  // --- Page Transitions ---
  static const Duration pageFadeDuration = Duration(milliseconds: 350);

  // --- Micro-animations ---
  static const Duration microFeedbackDuration = Duration(milliseconds: 120);
}
