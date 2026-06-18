import Foundation
import Combine

enum AppScreen {
    case profileCreation
    case welcome
    case profileSelection
    case profileList
    case naturalLanguageInput
    case triage
    case results
}

final class AppState: ObservableObject {
    // AppRouter sets the correct initial screen synchronously before first render
    @Published var activeScreen: AppScreen = .welcome
    @Published var isSessionActive: Bool = false
    @Published var isProfileLoaded: Bool = false
    @Published var activeProfileName: String? = nil
    @Published var isVoiceModeOn: Bool = false
    @Published var isEmergencyCountdownRunning: Bool = false
    @Published var isInForeground: Bool = true
    // Incremented each time a new triage session starts — used to auto-dismiss mid-triage sheets
    @Published var sessionStartCount: Int = 0
    // Tracks which profile is loaded in the current session (nil = manual or no session)
    @Published var activeProfileId: UUID? = nil
    // Session recovery sheet — shown when app resumes with an interrupted in-memory session
    @Published var showSessionRecovery: Bool = false
    // One-time first-profile-creation celebration shown on WelcomeView
    @Published var showFirstTimeCelebration: Bool = false
    // Consumed by WelcomeView.onAppear to show a brief post-session note
    @Published var showPostSessionContext: Bool = false
}
