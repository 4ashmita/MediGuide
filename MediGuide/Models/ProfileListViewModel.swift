import Foundation
import Combine
import SwiftUI

@MainActor
final class ProfileListViewModel: ObservableObject {

    @Published var profiles: [ProfileSummary] = []
    @Published var deleteTarget: ProfileSummary? = nil

    var profileLimitReached: Bool { profiles.count >= ProfileRepository.maxProfiles }

    func load() {
        profiles = ProfileRepository.summaries()
    }

    func confirmDelete(_ summary: ProfileSummary) {
        deleteTarget = summary
    }

    func move(from source: IndexSet, to destination: Int) {
        profiles.move(fromOffsets: source, toOffset: destination)
        ProfileRepository.reorder(profiles.map { $0.id })
    }

    func isStale(_ summary: ProfileSummary) -> Bool {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return summary.dateModified < sixMonthsAgo
    }
}
