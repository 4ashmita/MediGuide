import Foundation

enum StorageKeys {

    // MARK: - UserDefaults (non-sensitive, encrypted before writing)

    enum Defaults {
        static let profileIndex          = "mediguide.profiles.index"
        static let activeProfileId       = "mediguide.profiles.activeId"
        static let profileCreated        = "mediguide.profileCreated"
        static let permanentlySkipped    = "mediguide.onboardingSkipped"

        static func displayName(for id: UUID)   -> String { "mediguide.profile.\(id).displayName" }
        static func dateOfBirth(for id: UUID)   -> String { "mediguide.profile.\(id).dateOfBirth" }
        static func biologicalSex(for id: UUID) -> String { "mediguide.profile.\(id).sex" }
        static func bloodType(for id: UUID)     -> String { "mediguide.profile.\(id).bloodType" }
        static func dateCreated(for id: UUID)        -> String { "mediguide.profile.\(id).dateCreated" }
        static func dateModified(for id: UUID)       -> String { "mediguide.profile.\(id).dateModified" }
        static func lastUsed(for id: UUID)           -> String { "mediguide.profile.\(id).lastUsed" }
        static func conditionsSummary(for id: UUID)  -> String { "mediguide.profile.\(id).conditionsSummary" }
    }

    // MARK: - Keychain (sensitive fields)

    enum Keychain {
        static let encryptionMasterKey = "mediguide.encryption.masterKey"

        static func sensitiveData(for id: UUID) -> String { "mediguide.profile.\(id).sensitive" }
    }
}
