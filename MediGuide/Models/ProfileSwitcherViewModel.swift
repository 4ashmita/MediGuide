import Foundation
import Combine
import LocalAuthentication

@MainActor
final class ProfileSwitcherViewModel: ObservableObject {

    @Published var profiles: [ProfileSummary] = []
    @Published var selectedId: UUID? = nil
    @Published var authError: String? = nil
    @Published var showManualEntry: Bool = false

    var preHighlightedId: UUID? {
        RecentProfileTracker.mostRecent(from: profiles.map(\.id))
    }

    var selectedSummary: ProfileSummary? {
        guard let id = selectedId else { return nil }
        return profiles.first { $0.id == id }
    }

    func load() {
        let all = ProfileRepository.summaries()
        let ordered = RecentProfileTracker.orderedIds(from: all.map(\.id))
        profiles = ordered.compactMap { id in all.first { $0.id == id } }
    }

    func isStale(_ summary: ProfileSummary) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return summary.dateModified < cutoff
    }

    func tap(id: UUID) {
        authError = nil
        selectedId = (selectedId == id) ? nil : id
    }

    func confirmTriage(sessionManager: SessionManager) {
        guard let id = selectedId else { return }
        authError = nil

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to load health profile"
            ) { [weak self] success, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if success {
                        self.launch(id: id, sessionManager: sessionManager)
                    } else {
                        self.authError = "Authentication failed. Please try again."
                    }
                }
            }
        } else {
            launch(id: id, sessionManager: sessionManager)
        }
    }

    private func launch(id: UUID, sessionManager: SessionManager) {
        let success = sessionManager.switchProfile(id: id)
        if success {
            RecentProfileTracker.record(id: id)
            selectedId = nil
        } else {
            authError = "Failed to load profile. Please try again."
        }
    }
}
