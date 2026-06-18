import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var vm = PrivacySettingsViewModel()
    @EnvironmentObject var authState: AuthStateManager
    @State private var showClearAllConfirmation = false

    var body: some View {
        Form {
            masterToggleSection
            if vm.isEnabled {
                windowSection
                behaviorSection
            }
            biometricStatusSection
            clearAllSection
        }
        .sheet(isPresented: $showClearAllConfirmation) {
            DeletionConfirmationView(mode: .fullWipe)
        }
        .navigationTitle("Profile Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.load() }
        .overlay {
            if vm.isLoading {
                ProgressView()
                    .scaleEffect(1.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.15))
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .overlay(alignment: .bottom) {
            if let msg = vm.successMessage {
                Text(msg)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { vm.successMessage = nil }
                        }
                    }
                    .animation(.easeInOut, value: vm.successMessage)
            }
        }
    }

    // MARK: - Master Toggle

    private var masterToggleSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { vm.isEnabled },
                set: { vm.setEnabled($0) }
            )) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protect Profiles")
                            .font(.body)
                        Text("Require \(vm.biometricType.buttonLabel.replacingOccurrences(of: "Use ", with: "")) to access health profiles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: vm.isEnabled ? "lock.fill" : "lock.open")
                        .foregroundStyle(vm.isEnabled ? .green : .secondary)
                }
            }
        } footer: {
            Text("Turning protection on or off requires authentication to confirm your identity.")
        }
    }

    // MARK: - Auth Window

    private var windowSection: some View {
        Section {
            ForEach(vm.windowOptions, id: \.minutes) { option in
                Button(action: { vm.setWindow(minutes: option.minutes) }) {
                    HStack {
                        Text(option.label)
                            .foregroundStyle(.primary)
                        Spacer()
                        if vm.windowMinutes == option.minutes {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        } header: {
            Text("Authentication Window")
        } footer: {
            Text("After this period of active use you will need to authenticate again.")
        }
    }

    // MARK: - Behavior Toggles

    private var behaviorSection: some View {
        Section {
            Toggle("Lock when app backgrounds", isOn: Binding(
                get: { vm.lockOnBackground },
                set: { vm.setLockOnBackground($0) }
            ))
            Toggle("Allow passcode as fallback", isOn: Binding(
                get: { vm.passcodeFallback },
                set: { vm.setPasscodeFallback($0) }
            ))
        } header: {
            Text("Lock Behavior")
        } footer: {
            Text("When app backgrounds resets authentication immediately. Passcode fallback activates after two biometric failures.")
        }
    }

    // MARK: - Biometric Status

    private var biometricStatusSection: some View {
        Section("Device Status") {
            HStack(spacing: 12) {
                Image(systemName: vm.biometricType.systemImage)
                    .font(.title3)
                    .foregroundStyle(vm.isBiometricsEnrolled ? .green : .orange)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(biometricStatusTitle)
                        .font(.body)
                    Text(biometricStatusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !vm.isBiometricsEnrolled {
                Button("Open Face ID & Passcode Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundStyle(.blue)
            }
        }
    }

    private var biometricStatusTitle: String {
        switch vm.biometricType {
        case .faceID:   return "Face ID available and enrolled"
        case .touchID:  return "Touch ID available and enrolled"
        case .passcode: return "Passcode set (no biometrics enrolled)"
        case .none:     return "No authentication method set up"
        }
    }

    // MARK: - Clear All Health Data

    private var clearAllSection: some View {
        Section {
            Button(role: .destructive) {
                showClearAllConfirmation = true
            } label: {
                Label("Clear All Health Data", systemImage: "trash.fill")
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Permanently removes all profiles, medications, allergies, and emergency contacts from this device. The app returns to its initial state.")
        }
    }

    private var biometricStatusSubtitle: String {
        switch vm.biometricType {
        case .faceID, .touchID:
            return "Your device supports hardware-level biometric protection."
        case .passcode:
            return "Set up Face ID or Touch ID in Settings for stronger protection."
        case .none:
            return "Set up Face ID or a passcode in Settings > Face ID & Passcode."
        }
    }
}
