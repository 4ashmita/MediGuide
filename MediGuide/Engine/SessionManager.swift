import Foundation
import Combine

final class SessionManager: ObservableObject {

    // MARK: - Dependencies

    let engine: TriageEngine
    let navigationManager: NavigationManager
    private let appState: AppState

    // MARK: - Init

    init(engine: TriageEngine, navigationManager: NavigationManager, appState: AppState) {
        self.engine = engine
        self.navigationManager = navigationManager
        self.appState = appState
    }

    // MARK: - Session Lifecycle

    func startSession(with profile: UserProfile? = nil) {
        engine.reset()
        navigationManager.restart()
        NotificationManager.cancelCheckIn()

        engine.session.sessionStartTime = Date()
        engine.session.isActive = true

        if let profile = profile {
            engine.session.profileUsed = true
            engine.setAgeGroup(profile.ageGroup)
            for modifier in ProfileMapper.modifiers(from: profile) {
                engine.addModifier(modifier.modifierId)
            }
            appState.isProfileLoaded = true
            appState.activeProfileName = profile.displayName
        } else {
            engine.session.profileUsed = false
            appState.isProfileLoaded = false
            appState.activeProfileName = nil
        }

        appState.isSessionActive = true
        appState.activeScreen = .triage
    }

    func resetSession() {
        engine.reset()
        navigationManager.restart()
        NotificationManager.cancelCheckIn()

        appState.isSessionActive = true
        appState.activeScreen = .triage
    }

    func endSession() {
        engine.reset()
        navigationManager.restart()
        NotificationManager.cancelCheckIn()

        appState.isSessionActive = false
        appState.isProfileLoaded = false
        appState.activeProfileName = nil
        appState.isEmergencyCountdownRunning = false
        appState.activeScreen = .welcome
    }

    // MARK: - Foreground / Background

    func handleDidEnterBackground() {
        appState.isInForeground = false
    }

    func handleWillEnterForeground() {
        appState.isInForeground = true

        // If the session was active but engine has been wiped by OS termination, return to welcome
        if appState.isSessionActive && engine.session.symptoms.isEmpty
            && !engine.session.isActive {
            endSession()
        }
    }
}
