import Foundation

enum StorageKeys {

    // MARK: - UserDefaults (non-sensitive, encrypted before writing)

    enum Defaults {
        static let profileIndex          = "mediguide.profiles.index"
        static let profileOrder          = "mediguide.profiles.order"
        static let recentProfileUsage    = "mediguide.profiles.recentUsage"
        static let activeProfileId       = "mediguide.profiles.activeId"
        static let profileCreated        = "mediguide.profileCreated"
        static let permanentlySkipped    = "mediguide.onboardingSkipped"

        // Privacy / biometric settings (plain bools and int — not sensitive)
        static let privacyEnabled           = "mediguide.privacy.enabled"
        static let privacyWindowMinutes     = "mediguide.privacy.windowMinutes"
        static let privacyLockOnBackground  = "mediguide.privacy.lockOnBackground"
        static let privacyPasscodeFallback  = "mediguide.privacy.passcodeFallback"

        static func displayName(for id: UUID)   -> String { "mediguide.profile.\(id).displayName" }
        static func dateOfBirth(for id: UUID)   -> String { "mediguide.profile.\(id).dateOfBirth" }
        static func biologicalSex(for id: UUID) -> String { "mediguide.profile.\(id).sex" }
        static func bloodType(for id: UUID)     -> String { "mediguide.profile.\(id).bloodType" }
        static func dateCreated(for id: UUID)        -> String { "mediguide.profile.\(id).dateCreated" }
        static func dateModified(for id: UUID)       -> String { "mediguide.profile.\(id).dateModified" }
        static func lastUsed(for id: UUID)           -> String { "mediguide.profile.\(id).lastUsed" }
        static func conditionsSummary(for id: UUID)  -> String { "mediguide.profile.\(id).conditionsSummary" }
        static func relationship(for id: UUID)       -> String { "mediguide.profile.\(id).relationship" }
    }

    // MARK: - Settings (non-sensitive preferences)

    enum Settings {
        static let textSizeLevel           = "mediguide.settings.textSizeLevel"
        static let highContrast            = "mediguide.settings.highContrast"
        static let reduceMotion            = "mediguide.settings.reduceMotion"
        static let oneHandedMode           = "mediguide.settings.oneHandedMode"
        static let elderlyLargeUI          = "mediguide.settings.elderlyLargeUI"
        static let boldText                = "mediguide.settings.boldText"
        static let pillShapeButtons        = "mediguide.settings.pillShapeButtons"
        static let maxBrightnessEmergency  = "mediguide.settings.maxBrightnessEmergency"
        static let voiceNarration          = "mediguide.settings.voiceNarration"
        static let narrationSpeed          = "mediguide.settings.narrationSpeed"
        static let autoReadRecommendation  = "mediguide.settings.autoReadRecommendation"
        static let autoReadFirstAid        = "mediguide.settings.autoReadFirstAid"
        static let voiceCommands           = "mediguide.settings.voiceCommands"
        static let alertToneCountdown      = "mediguide.settings.alertToneCountdown"
        static let alertToneTimer          = "mediguide.settings.alertToneTimer"
        static let alertToneCPR            = "mediguide.settings.alertToneCPR"
        static let defaultInputMode        = "mediguide.settings.defaultInputMode"
        static let reassessIntervalER      = "mediguide.settings.reassessIntervalER"
        static let reassessIntervalUC      = "mediguide.settings.reassessIntervalUC"
        static let reassessIntervalMonitor = "mediguide.settings.reassessIntervalMonitor"
        static let autoEscalation          = "mediguide.settings.autoEscalation"
        static let instinctButtonStyle     = "mediguide.settings.instinctButtonStyle"
        static let showScoreExplanation    = "mediguide.settings.showScoreExplanation"
        static let warningDetailLevel      = "mediguide.settings.warningDetailLevel"
        static let checkInNotifications    = "mediguide.settings.checkInNotifications"
        static let emergencySMSEnabled     = "mediguide.settings.emergencySMSEnabled"
        static let notificationPrivacy     = "mediguide.settings.notificationPrivacy"
        static let profileUpdateReminders  = "mediguide.settings.profileUpdateReminders"
        static let tempUnitFahrenheit      = "mediguide.settings.tempUnitFahrenheit"
        static let distanceUnitMiles       = "mediguide.settings.distanceUnitMiles"
        static let installDate             = "mediguide.settings.installDate"
    }

    // MARK: - Keychain (sensitive fields)

    enum Keychain {
        static let encryptionMasterKey = "mediguide.encryption.masterKey"

        static func sensitiveData(for id: UUID)  -> String { "mediguide.profile.\(id).sensitive" }
        static func medications(for id: UUID)    -> String { "mediguide.profile.\(id).medications" }
        static func allergies(for id: UUID)      -> String { "mediguide.profile.\(id).allergies" }
    }
}
