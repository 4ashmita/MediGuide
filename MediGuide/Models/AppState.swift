import Foundation
import Combine

enum AppScreen {
    case profileCreation
    case welcome
    case triage
    case results
}

final class AppState: ObservableObject {
    @Published var activeScreen: AppScreen = OnboardingManager.shouldShowCreation() ? .profileCreation : .welcome
    @Published var isSessionActive: Bool = false
    @Published var isProfileLoaded: Bool = false
    @Published var activeProfileName: String? = nil
    @Published var isVoiceModeOn: Bool = false
    @Published var isEmergencyCountdownRunning: Bool = false
    @Published var isInForeground: Bool = true
}
