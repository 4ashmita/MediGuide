import Foundation
import Combine
import SwiftUI

@MainActor
final class WelcomeViewModel: ObservableObject {
    @Published var profileCount: Int = 0
    @Published var lastUsedName: String? = nil
    @Published var staleProfiles: [ProfileSummary] = []
    @Published var profilesMissingContact: [ProfileSummary] = []
    @Published var showPostSessionNote: Bool = false

    private var dismissTask: Task<Void, Never>?

    func load(isAuthenticated: Bool) {
        let summaries = ProfileRepository.summaries()
        profileCount = summaries.count

        if let recentId = RecentProfileTracker.mostRecent(from: summaries.map(\.id)),
           let match = summaries.first(where: { $0.id == recentId }) {
            lastUsedName = match.displayName
        } else {
            lastUsedName = nil
        }

        guard isAuthenticated else {
            staleProfiles = []
            profilesMissingContact = []
            return
        }

        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        staleProfiles = summaries.filter { $0.dateModified < sixMonthsAgo }

        profilesMissingContact = summaries.filter { summary in
            guard let profile = ProfileRepository.profile(id: summary.id) else { return false }
            return profile.emergencyContactPhone.isEmpty
                && profile.emergencyContactName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    func showPostSession() {
        showPostSessionNote = true
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { self.showPostSessionNote = false }
        }
    }
}
