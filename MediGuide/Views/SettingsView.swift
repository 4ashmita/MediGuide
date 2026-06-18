import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject private var authState: AuthStateManager

    var body: some View {
        List {
            Section {
                Text("MediGuide — Version \(vm.appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(vm.sections) { section in
                NavigationLink(destination: destinationView(for: section.id)) {
                    SettingsSectionRow(section: section)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EmergencyButtonView(context: .noSession)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for id: String) -> some View {
        switch id {
        case "profiles":      ProfileManagementView()
        case "privacy":       PrivacySettingsView().environmentObject(authState)
        case "accessibility": AccessibilitySettingsView()
        case "voice":         VoiceSettingsView()
        case "triage":        TriageSettingsView()
        case "notifications": NotificationSettingsView()
        case "language":      LanguageSettingsView()
        case "about":         AboutView()
        default:              Text("Coming soon").foregroundColor(.secondary)
        }
    }
}

private struct SettingsSectionRow: View {
    let section: SettingsSection

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: section.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(iconColor)
                .cornerRadius(7)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title).font(.body)
                Text(section.description).font(.caption).foregroundColor(.secondary)
            }

            if let badge = section.badge {
                Spacer()
                Circle()
                    .fill(badge == .attention ? Color.red : Color.orange)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 2)
    }

    private var iconColor: Color {
        switch section.id {
        case "profiles":      return .blue
        case "privacy":       return .green
        case "accessibility": return .purple
        case "voice":         return .orange
        case "triage":        return .red
        case "notifications": return Color(red: 1.0, green: 0.4, blue: 0.0)
        case "language":      return .teal
        case "about":         return .gray
        default:              return .secondary
        }
    }
}
