import SwiftUI

struct WelcomeView: View {
    @StateObject private var vm = WelcomeViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authState: AuthStateManager
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    appIdentityHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    primarySection
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    bannerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    Spacer(minLength: 48)

                    secondaryActions
                        .padding(.horizontal, 24)

                    disclaimerText
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
            }

            EmergencyButtonView(context: .noSession)
                .padding(.trailing, EmergencyButtonStyleGuide.trailingPadding)
                .padding(.top, 8)
        }
        .onAppear {
            let authenticated = authState.isAuthenticated || !authState.isPrivacyEnabled
            vm.load(isAuthenticated: authenticated)
            if appState.showPostSessionContext {
                appState.showPostSessionContext = false
                vm.showPostSession()
            }
        }
        .onChange(of: authState.isAuthenticated) { _, _ in
            vm.load(isAuthenticated: authState.isAuthenticated || !authState.isPrivacyEnabled)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(authState)
            }
        }
    }

    // MARK: - App Identity Header

    private var appIdentityHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "cross.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.red)
            Text("MediGuide")
                .font(.title2)
                .fontWeight(.black)
            Spacer()
        }
    }

    // MARK: - Primary Section

    private var primarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: { appState.activeScreen = .profileSelection }) {
                Text("Start Triage")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(Color.red)
                    .cornerRadius(16)
            }
            profileStatusRow
        }
    }

    @ViewBuilder
    private var profileStatusRow: some View {
        if !authState.isPrivacyEnabled || authState.isAuthenticated {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(vm.profileCount == 1 ? "1 profile protected" : "\(vm.profileCount) profiles protected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusText: String {
        guard vm.profileCount > 0 else { return "No profiles saved" }
        let countPart = vm.profileCount == 1 ? "1 profile ready" : "\(vm.profileCount) profiles ready"
        if let name = vm.lastUsedName {
            return "\(countPart) · Last used: \(name)"
        }
        return countPart
    }

    // MARK: - Contextual Banners

    @ViewBuilder
    private var bannerSection: some View {
        if appState.showFirstTimeCelebration {
            celebrationBanner
                .padding(.bottom, 8)
        }
        if vm.showPostSessionNote {
            postSessionBanner
                .padding(.bottom, 8)
        }
        if !vm.staleProfiles.isEmpty {
            staleProfilesBanner
                .padding(.bottom, 6)
        }
        if !vm.profilesMissingContact.isEmpty {
            missingContactBanner
                .padding(.bottom, 6)
        }
    }

    private var celebrationBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("You're all set.")
                    .font(.subheadline.bold())
                Text("Your health profile is saved and ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                withAnimation { appState.showFirstTimeCelebration = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var postSessionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
            Text("Previous session ended. Start a new triage when ready.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var staleProfilesBanner: some View {
        let shown = vm.staleProfiles.prefix(2).map(\.displayName).joined(separator: ", ")
        let extra = vm.staleProfiles.count > 2 ? " and \(vm.staleProfiles.count - 2) more" : ""
        let plural = vm.staleProfiles.count > 1
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundStyle(.orange)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(shown)\(extra)'s profile\(plural ? "s were" : " was") last updated over 6 months ago.")
                    .font(.caption)
                Button("Review") { appState.activeScreen = .profileList }
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .cornerRadius(12)
    }

    private var missingContactBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "phone.badge.exclamationmark.fill")
                .foregroundStyle(.orange)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Some profiles are missing an emergency contact. The SMS feature will not work for these profiles.")
                    .font(.caption)
                Button("Fix") { appState.activeScreen = .profileList }
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Secondary Actions

    private var secondaryActions: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 24) {
                Button(action: { appState.activeScreen = .profileList }) {
                    Label("Manage Profiles", systemImage: "person.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button(action: { showSettings = true }) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 14)
        }
    }

    // MARK: - Medical Disclaimer

    private var disclaimerText: some View {
        Text("This app provides guidance only and is not a substitute for professional medical advice.")
            .font(.caption2)
            .foregroundStyle(Color(.tertiaryLabel))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
