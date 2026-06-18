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

    /// Profile-backed session: delegates entirely to ProfileLoader. Returns false if profile cannot be retrieved.
    @discardableResult
    func startSession(withProfileId profileId: UUID) -> Bool {
        engine.reset()
        NotificationManager.cancelCheckIn()

        engine.setSessionStartTime(Date())
        engine.setSessionActive(true)

        do {
            let result = try ProfileLoader.load(profileId: profileId, into: engine)
            navigationManager.restart(startingAt: "\(result.ageGroup.rawValue)_start")
            navigationManager.setNodesToSkip(["condition_check"])
            ProfileStore.updateLastUsed(id: profileId)
            appState.isProfileLoaded = true
            appState.activeProfileName = result.displayName
            appState.activeProfileId = profileId
        } catch {
            navigationManager.restart()
            engine.setSessionActive(false)
            appState.activeProfileId = nil
            return false
        }

        appState.isSessionActive = true
        appState.sessionStartCount += 1
        appState.activeScreen = .naturalLanguageInput
        return true
    }

    /// Resets the current session and starts a new one for the given profile. Used for mid-session profile switching.
    @discardableResult
    func switchProfile(id: UUID) -> Bool {
        startSession(withProfileId: id)
    }

    /// Direct-profile session used when the caller already holds a UserProfile (e.g. reset within an active session).
    func startSession(with profile: UserProfile? = nil) {
        engine.reset()
        NotificationManager.cancelCheckIn()

        engine.setSessionStartTime(Date())
        engine.setSessionActive(true)

        if let profile = profile {
            let result = ProfileMapper.map(profile)
            engine.setAgeGroup(result.ageGroup)
            navigationManager.restart(startingAt: "\(result.ageGroup.rawValue)_start")
            navigationManager.setNodesToSkip(["condition_check"])
            for modifier in result.modifiers {
                engine.addModifier(modifier.modifierId)
            }
            engine.setEmergencyContact(name: result.emergencyContactName,
                                       phone: result.emergencyContactPhone)
            engine.setSessionMedicationList(result.formattedMedications)
            engine.setRecentMedicationDetected(result.recentMedicationDetected)
            engine.setSessionAllergyList(result.formattedAllergies)
            engine.setAllergyAnaphylacticPresent(result.allergyAnaphylacticPresent)
            engine.setSessionBloodType(result.formattedBloodType)
            engine.setSessionDisplayName(result.displayName)
            engine.setSessionAge(result.age)
            engine.setProfileUsed(true)
            appState.isProfileLoaded = true
            appState.activeProfileName = profile.displayName
            appState.activeProfileId = profile.id
        } else {
            navigationManager.restart()
            engine.setProfileUsed(false)
            appState.isProfileLoaded = false
            appState.activeProfileName = nil
            appState.activeProfileId = nil
        }

        appState.isSessionActive = true
        appState.sessionStartCount += 1
        appState.activeScreen = .naturalLanguageInput
    }

    func startManualSession(ageGroup: AgeGroup, conditions: [String]) {
        engine.reset()
        navigationManager.restart(startingAt: "\(ageGroup.rawValue)_start")
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
        if !conditions.isEmpty {
            navigationManager.setNodesToSkip(["condition_check"])
        }

        appState.isProfileLoaded = false
        appState.activeProfileName = nil
        appState.activeProfileId = nil
        appState.isSessionActive = true
        appState.sessionStartCount += 1
        appState.activeScreen = .naturalLanguageInput
    }

    func resetSession() {
        engine.reset()
        navigationManager.restart()
        NotificationManager.cancelCheckIn()

        appState.activeProfileId = nil
        appState.isSessionActive = true
        appState.activeScreen = .naturalLanguageInput
    }

    func endSession() {
        engine.reset()
        navigationManager.restart()
        NotificationManager.cancelCheckIn()

        appState.isSessionActive = false
        appState.isProfileLoaded = false
        appState.activeProfileName = nil
        appState.activeProfileId = nil
        appState.isEmergencyCountdownRunning = false
        appState.showPostSessionContext = true
        appState.activeScreen = .welcome
    }

    // MARK: - Session State Query

    /// True when a triage session is live in memory — used by AppRouter to offer session recovery.
    var hasInterruptedSession: Bool {
        engine.session.isActive && appState.isSessionActive
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
