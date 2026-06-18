import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    private let store = SettingsStore.shared

    var sections: [SettingsSection] {
        [
            SettingsSection(id: "profiles", icon: "person.crop.circle", title: "Profiles",
                description: "Manage your health profiles and family members",
                badge: missingContactBadge),
            SettingsSection(id: "privacy", icon: "lock.fill", title: "Privacy & Security",
                description: "Face ID, data protection, and profile access"),
            SettingsSection(id: "accessibility", icon: "accessibility", title: "Accessibility",
                description: "Text size, contrast, voice, and display options"),
            SettingsSection(id: "voice", icon: "speaker.wave.2.fill", title: "Voice & Audio",
                description: "Narration, speech input, and alert tones"),
            SettingsSection(id: "triage", icon: "cross.fill", title: "Triage Preferences",
                description: "Default mode, sensitivity, and reassessment"),
            SettingsSection(id: "notifications", icon: "bell.fill", title: "Notifications",
                description: "Reassessment reminders and emergency alerts"),
            SettingsSection(id: "language", icon: "globe", title: "Language & Region",
                description: "App language, units, and regional settings"),
            SettingsSection(id: "about", icon: "info.circle.fill", title: "About",
                description: "App information, legal documents, and feedback"),
        ]
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var missingContactBadge: SettingsBadge? {
        // Check via ProfileRepository if any profile is missing emergency contact
        // Import-safe: just check UserDefaults for profile count > 0 as a proxy
        nil  // Detailed check would require ProfileRepository which imports KeychainManager etc.
    }
}
