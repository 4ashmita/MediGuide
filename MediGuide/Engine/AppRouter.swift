import Foundation

enum AppRouter {

    /// Determines the correct initial screen and mutates appState accordingly.
    /// Called synchronously in ContentView.init before the first render.
    static func route(into appState: AppState, sessionManager: SessionManager) {
        // Check 1: First-time setup not yet complete
        if OnboardingManager.shouldShowCreation() {
            appState.activeScreen = .profileCreation
            return
        }

        // Check 2: Interrupted in-memory triage session
        if sessionManager.hasInterruptedSession {
            appState.showSessionRecovery = true
            appState.activeScreen = .welcome
            return
        }

        // Check 3: Defensive — onboarding complete but no profiles exist
        if ProfileRepository.profileCount == 0 {
            appState.activeScreen = .profileCreation
            return
        }

        // Check 4: Pending reassessment notification (wired up when notification system is implemented)

        appState.activeScreen = .welcome
    }
}
