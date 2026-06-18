import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @ObservedObject private var store = SettingsStore.shared
    @State private var criticalAlertStatus: String = "Checking..."

    var body: some View {
        Form {
            checkInSection
            emergencySection
            privacySection
            reminderSection
            criticalAlertSection
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkNotificationStatus() }
    }

    private var checkInSection: some View {
        Section {
            Toggle("Check-In Reminders", isOn: Binding(
                get: { store.checkInNotifications },
                set: { store.checkInNotifications = $0 }
            ))
        } header: {
            Text("Check-In")
        } footer: {
            Text("Sends a notification when it's time to reassess your symptoms based on your reassessment interval settings.")
        }
    }

    private var emergencySection: some View {
        Section {
            Toggle("Emergency SMS Alerts", isOn: Binding(
                get: { store.emergencySMSEnabled },
                set: { store.emergencySMSEnabled = $0 }
            ))
        } header: {
            Text("Emergency")
        } footer: {
            Text("When enabled, an SMS with your location and medical info is sent to your emergency contact when 911 is called.")
        }
    }

    private var privacySection: some View {
        Section {
            Toggle("Hide Content in Notifications", isOn: Binding(
                get: { store.notificationPrivacy },
                set: { store.notificationPrivacy = $0 }
            ))
        } header: {
            Text("Privacy")
        } footer: {
            Text("When enabled, notification previews show \"MediGuide Alert\" instead of symptom details to protect your privacy on the lock screen.")
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Profile Update Reminders", isOn: Binding(
                get: { store.profileUpdateReminders },
                set: { store.profileUpdateReminders = $0 }
            ))
        } header: {
            Text("Maintenance")
        } footer: {
            Text("Reminds you to review your health profiles every 6 months to keep information current.")
        }
    }

    private var criticalAlertSection: some View {
        Section {
            HStack {
                Text("Notification Permission")
                Spacer()
                Text(criticalAlertStatus)
                    .foregroundColor(criticalAlertStatus == "Granted" ? .green : .orange)
                    .font(.subheadline)
            }
            Button("Open Notification Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } header: {
            Text("System")
        } footer: {
            Text("Manage notification permissions in iOS Settings.")
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                criticalAlertStatus = settings.authorizationStatus == .authorized ? "Granted" : "Not Granted"
            }
        }
    }
}
