import Foundation

struct SettingsItem: Identifiable {
    let id: String
    let label: String
    let detail: String?
    let icon: String?
    var isDestructive: Bool = false

    init(id: String, label: String, detail: String? = nil, icon: String? = nil, isDestructive: Bool = false) {
        self.id = id
        self.label = label
        self.detail = detail
        self.icon = icon
        self.isDestructive = isDestructive
    }
}
