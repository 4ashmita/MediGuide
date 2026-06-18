import Foundation

struct SettingsSection: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    var badge: SettingsBadge? = nil
}

enum SettingsBadge {
    case attention  // red dot — something needs action
    case stale      // orange dot — something is outdated
}
