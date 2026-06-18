import Foundation
import Combine
import SwiftUI

@MainActor
final class ProfileManagementViewModel: ObservableObject {

    struct LoadedProfile: Identifiable {
        let profile: UserProfile
        let report: CompletenessReport
        var id: UUID { profile.id }
    }

    @Published var loadedProfiles: [LoadedProfile] = []
    @Published var deleteTarget: ProfileSummary? = nil
    @Published var editingProfileId: UUID? = nil
    @Published var isAddingProfile: Bool = false
    @Published var reviewingProfile: UserProfile? = nil
    @Published var highlightedProfileId: UUID? = nil

    var profileLimitReached: Bool { loadedProfiles.count >= ProfileRepository.maxProfiles }

    func load() {
        let summaries = ProfileRepository.summaries()
        loadedProfiles = summaries.compactMap { summary -> LoadedProfile? in
            guard let profile = ProfileRepository.profile(id: summary.id) else { return nil }
            return LoadedProfile(profile: profile, report: ProfileCompletenessChecker.check(profile))
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        loadedProfiles.move(fromOffsets: source, toOffset: destination)
        ProfileRepository.reorder(loadedProfiles.map { $0.profile.id })
    }

    func confirmDelete(_ profileId: UUID) {
        deleteTarget = ProfileRepository.summaries().first { $0.id == profileId }
    }

    func markReviewed(_ profile: UserProfile) {
        var updated = profile
        updated.dateModified = Date()
        try? ProfileStore.save(updated)
        load()
    }

    // Called after a new profile is successfully created so the new card highlights briefly
    func finishAddingProfile() {
        let previousIds = Set(loadedProfiles.map { $0.id })
        load()
        if let newId = loadedProfiles.first(where: { !previousIds.contains($0.id) })?.id {
            highlightedProfileId = newId
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                highlightedProfileId = nil
            }
        }
    }
}
