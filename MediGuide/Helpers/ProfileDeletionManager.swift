import Foundation

enum ProfileDeletionManager {

    enum DeletionError: Error {
        case partialFailure(String)

        var message: String {
            switch self {
            case .partialFailure(let detail): return detail
            }
        }
    }

    // MARK: - Individual Profile Deletion

    static func deleteProfile(id: UUID) throws {
        performDelete(id: id)

        if !DeletionVerifier.verifyProfileDeletion(id: id) {
            performDelete(id: id)
            guard DeletionVerifier.verifyProfileDeletion(id: id) else {
                throw DeletionError.partialFailure("Some profile data could not be removed. Please try again.")
            }
        }
    }

    private static func performDelete(id: UUID) {
        ProfileRepository.delete(id: id)  // handles ProfileStore + ProfileOrderManager
        RecentProfileTracker.remove(id: id)
    }

    // MARK: - Full Wipe

    static func deleteAllProfiles() throws {
        let ids = ProfileRepository.summaries().map(\.id)

        for id in ids {
            performDelete(id: id)
        }
        RecentProfileTracker.clear()
        AuthStateManager.shared.lock()

        if !DeletionVerifier.verifyFullWipe(formerIds: ids) {
            for id in ids { performDelete(id: id) }
            RecentProfileTracker.clear()

            guard DeletionVerifier.verifyFullWipe(formerIds: ids) else {
                throw DeletionError.partialFailure("Some data could not be fully removed. Please try again.")
            }
        }
    }
}
