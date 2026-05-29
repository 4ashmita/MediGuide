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

        engine.setSessionStartTime(Date())
        engine.setSessionActive(true)

        if let profile = profile {
            engine.setProfileUsed(true)
            engine.setAgeGroup(profile.ageGroup)
            for modifier in ProfileMapper.modifiers(from: profile) {
                engine.addModifier(modifier.modifierId)
            }
            engine.setEmergencyContact(name: profile.emergencyContactName,
                                       phone: profile.emergencyContactPhone)
            autoDetectAdvancedMaternalAge(profile: profile)
            appState.isProfileLoaded = true
            appState.activeProfileName = profile.displayName
        } else {
            engine.setProfileUsed(false)
            appState.isProfileLoaded = false
            appState.activeProfileName = nil
        }

        appState.isSessionActive = true
        appState.activeScreen = .triage
    }

    func startManualSession(ageGroup: AgeGroup, conditions: [String]) {
        engine.reset()
        navigationManager.restart()
        NotificationManager.cancelCheckIn()

        engine.setSessionStartTime(Date())
        engine.setSessionActive(true)
        engine.setProfileUsed(false)

        engine.setAgeGroup(ageGroup)
        for conditionId in conditions {
            if let entry = ConditionList.entry(for: conditionId) {
                engine.addModifier(entry.modifierId)
            }
        }

        appState.isProfileLoaded = false
        appState.activeProfileName = nil
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

    // MARK: - Helpers

    private static let pregnancyConditionIds: Set<String> = [
        "pregnant_t1", "pregnant_t2", "pregnant_t3", "postpartum", "pregnant_unknown"
    ]

    private func autoDetectAdvancedMaternalAge(profile: UserProfile) {
        let hasPregnancy = profile.conditions.contains { Self.pregnancyConditionIds.contains($0) }
        let alreadyFlagged = profile.conditions.contains("advanced_maternal_age")
        if hasPregnancy && profile.age >= 35 && !alreadyFlagged {
            engine.addModifier("advanced_maternal_age")
        }
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
