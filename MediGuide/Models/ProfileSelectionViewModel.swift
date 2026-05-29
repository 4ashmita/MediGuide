import Foundation
import Combine
import LocalAuthentication

final class ProfileSelectionViewModel: ObservableObject {

    // MARK: - Published State

    @Published var profiles: [ProfileSummary] = []
    @Published var showManualEntry: Bool = false
    @Published var authError: String? = nil

    // MARK: - Manual Entry State

    @Published var manualAgeGroup: AgeGroup = .adult
    let manualConditionToggleVM = ConditionToggleViewModel()

    // MARK: - Computed

    var hasProfiles: Bool { !profiles.isEmpty }

    func isStale(_ summary: ProfileSummary) -> Bool {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return summary.dateModified < sixMonthsAgo
    }

    // MARK: - Load

    func load() {
        let summaries = ProfileStore.listSummaries()
        profiles = summaries.sorted { $0.lastUsed > $1.lastUsed }
    }

    // MARK: - Profile Selection

    func selectProfile(id: UUID, sessionManager: SessionManager) {
        authError = nil
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to load health profile"
            ) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        self.loadAndStart(id: id, sessionManager: sessionManager)
                    } else {
                        self.authError = "Authentication failed. Please try again."
                    }
                }
            }
        } else {
            loadAndStart(id: id, sessionManager: sessionManager)
        }
    }

    private func loadAndStart(id: UUID, sessionManager: SessionManager) {
        guard let profile = ProfileStore.load(id: id) else {
            authError = "Failed to load profile. Please try again."
            return
        }
        ProfileStore.updateLastUsed(id: id)
        sessionManager.startSession(with: profile)
    }

    // MARK: - Manual Session

    func startManualSession(sessionManager: SessionManager) {
        let conditions = manualConditionToggleVM.exportConditionIds()
        sessionManager.startManualSession(ageGroup: manualAgeGroup, conditions: conditions)
    }

    // MARK: - Reset Manual State

    func resetManualEntry() {
        manualAgeGroup = .adult
        // Re-create to clear all toggle state
    }
}
