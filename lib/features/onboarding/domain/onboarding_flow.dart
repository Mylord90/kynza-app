/// Flow-wide constants shared by every onboarding screen so the pagination
/// count and the large-screen portrait panel width stay identical across
/// the whole flow instead of being redefined per screen.
abstract class OnboardingFlow {
  static const totalScreens = 3;
  static const panelWidth = 520.0;
}
