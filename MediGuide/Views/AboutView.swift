import SwiftUI
import StoreKit

struct AboutView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    @State private var showDisclaimer = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showAcknowledgments = false

    var body: some View {
        List {
            appInfoSection
            legalSection
            acknowledgmentsSection
            feedbackSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDisclaimer) { legalDocView("Medical Disclaimer", content: disclaimerText) }
        .sheet(isPresented: $showPrivacy) { legalDocView("Privacy Policy", content: privacyText) }
        .sheet(isPresented: $showTerms) { legalDocView("Terms of Service", content: termsText) }
        .sheet(isPresented: $showAcknowledgments) { legalDocView("Acknowledgments", content: acknowledgementsText) }
    }

    // MARK: - Sections

    private var appInfoSection: some View {
        Section("App Info") {
            HStack {
                Text("Version")
                Spacer()
                Text(version)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Build")
                Spacer()
                Text(build)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Last Updated")
                Spacer()
                Text("June 2026")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Button {
                showDisclaimer = true
            } label: {
                Label("Medical Disclaimer", systemImage: "cross.fill")
                    .foregroundColor(.primary)
            }
            Button {
                showPrivacy = true
            } label: {
                Label("Privacy Policy", systemImage: "lock.shield.fill")
                    .foregroundColor(.primary)
            }
            Button {
                showTerms = true
            } label: {
                Label("Terms of Service", systemImage: "doc.text.fill")
                    .foregroundColor(.primary)
            }
        }
    }

    private var acknowledgmentsSection: some View {
        Section {
            Button {
                showAcknowledgments = true
            } label: {
                Label("Acknowledgments", systemImage: "heart.fill")
                    .foregroundColor(.primary)
            }
        } header: {
            Text("Credits")
        }
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Button {
                if let url = URL(string: "mailto:support@mediguide.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Send Feedback", systemImage: "envelope.fill")
                    .foregroundColor(.primary)
            }
            if SettingsStore.shared.hasUsedAppForAWeek {
                Button {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                } label: {
                    Label("Rate MediGuide", systemImage: "star.fill")
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - Legal Doc Sheet Helper

    @ViewBuilder
    private func legalDocView(_ title: String, content: String) -> some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.body)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showDisclaimer = false
                        showPrivacy = false
                        showTerms = false
                        showAcknowledgments = false
                    }
                }
            }
        }
    }

    // MARK: - Legal Text

    private var disclaimerText: String {
        """
        MEDICAL DISCLAIMER

        MediGuide is designed to provide general health guidance and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.

        In case of a medical emergency, call 911 immediately.

        The triage recommendations provided by MediGuide are based on general guidelines and should not be relied upon as the sole basis for medical decisions. Individual circumstances may vary, and only a licensed medical professional can provide an accurate diagnosis and treatment plan.

        MediGuide does not store your triage session data. All symptom information is processed in-memory only and is cleared when you close or reset the app.

        By using MediGuide, you acknowledge that you have read and understood this disclaimer.
        """
    }

    private var privacyText: String {
        """
        PRIVACY POLICY

        Last updated: June 2026

        MediGuide is built with privacy as a core principle. We do not collect, store, or transmit your personal health data.

        DATA STORED ON DEVICE
        Health profiles (name, date of birth, medical conditions, medications, allergies, and emergency contacts) are stored locally on your device only. Sensitive fields are encrypted using iOS Keychain. Profile data is never sent to any server, synced to iCloud, or shared with any third party.

        TRIAGE SESSIONS
        Symptom selections, triage scores, and recommendations are held in memory only during an active session. They are never written to disk, UserDefaults, or any persistent store. They are wiped when you reset or close the app.

        LOCATION DATA
        Your location is captured only at the moment you initiate a 911 call, solely to include in the emergency SMS sent to your emergency contact. It is never stored.

        CAMERA AND PHOTOS
        Photos taken for wound or rash analysis are sent to an AI service for analysis and immediately discarded. No photos are stored by the app.

        BIOMETRIC DATA
        Face ID and Touch ID are used only to unlock profile access. Biometric data never leaves your device.

        CONTACT US
        If you have questions about this privacy policy, contact us at support@mediguide.app.
        """
    }

    private var termsText: String {
        """
        TERMS OF SERVICE

        Last updated: June 2026

        By downloading and using MediGuide, you agree to these terms.

        USE OF THE APP
        MediGuide is intended for general health guidance purposes only. It is not a medical device, and its recommendations do not constitute medical advice. You assume full responsibility for decisions made based on information provided by this app.

        EMERGENCY SITUATIONS
        If you or someone else is experiencing a life-threatening emergency, call 911 immediately. Do not rely solely on MediGuide to determine the severity of an emergency.

        LIMITATIONS
        MediGuide is provided "as is" without warranty of any kind. We do not guarantee the accuracy, completeness, or fitness for a particular purpose of any information provided.

        CHANGES
        We may update these terms from time to time. Continued use of the app after changes constitutes your acceptance of the new terms.

        CONTACT
        For questions about these terms, contact us at support@mediguide.app.
        """
    }

    private var acknowledgementsText: String {
        """
        ACKNOWLEDGMENTS

        MediGuide was built with the following open technologies and frameworks:

        SwiftUI — Apple's declarative UI framework
        HealthKit — Apple's health data framework
        CallKit — Apple's call handling framework
        CoreLocation — Apple's location services
        AVFoundation — Apple's audio/visual framework
        UserNotifications — Apple's notification framework
        StoreKit — Apple's in-app review framework

        The triage decision logic is based on publicly available general first-aid guidelines. It is not derived from any proprietary clinical protocol.

        Special thanks to the open-source community and all who provided feedback during development.

        MediGuide is dedicated to everyone who has ever been in an emergency and needed calm, clear guidance.
        """
    }
}
