import SwiftUI

struct PrivacyGateView: View {
    @EnvironmentObject var authState: AuthStateManager
    @EnvironmentObject var appState: AppState

    @State private var failureCount = 0
    @State private var errorMessage: String? = nil
    @State private var isAuthenticating = false

    private var authType: BiometricAuthManager.AuthType { BiometricAuthManager.availableType }
    private var passcodeFallback: Bool {
        let key = StorageKeys.Defaults.privacyPasscodeFallback
        return UserDefaults.standard.object(forKey: key) == nil
            ? true
            : UserDefaults.standard.bool(forKey: key)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                lockIcon
                    .padding(.bottom, 28)

                Text("Health Profiles Protected")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Your medical information is kept private with biometric authentication.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 16)
                }

                primaryButton
                    .padding(.top, 32)
                    .padding(.horizontal, 40)

                if failureCount >= 2 && authType != .passcode {
                    secondaryPasscodeButton
                        .padding(.top, 12)
                        .padding(.horizontal, 40)
                }

                Spacer()

                if failureCount >= 2 {
                    emergencyBypassButton
                        .padding(.bottom, 32)
                }
            }
        }
    }

    // MARK: - Lock Icon

    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 96, height: 96)
            Image(systemName: authType.systemImage)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.red)
        }
    }

    // MARK: - Primary Auth Button

    private var primaryButton: some View {
        Button(action: authenticate) {
            HStack(spacing: 10) {
                if isAuthenticating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: authType.systemImage)
                    Text(authType.buttonLabel)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .cornerRadius(14)
        }
        .disabled(isAuthenticating)
    }

    // MARK: - Passcode Fallback Button

    private var secondaryPasscodeButton: some View {
        Button(action: { authenticateWithPasscode() }) {
            Text("Use Passcode Instead")
                .font(.subheadline)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .disabled(isAuthenticating)
    }

    // MARK: - Emergency Bypass

    private var emergencyBypassButton: some View {
        Button(action: { appState.activeScreen = .profileSelection }) {
            Text("Emergency Access — Proceed Without Profile")
                .font(.caption)
                .foregroundStyle(.secondary)
                .underline()
        }
    }

    // MARK: - Authentication Logic

    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        errorMessage = nil

        Task {
            let result = await BiometricAuthManager.authenticate(
                reason: .loadProfile,
                allowPasscodeFallback: passcodeFallback && failureCount >= 2
            )
            isAuthenticating = false
            handleResult(result)
        }
    }

    private func authenticateWithPasscode() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        errorMessage = nil

        Task {
            let result = await BiometricAuthManager.authenticate(reason: .loadProfile, allowPasscodeFallback: true)
            isAuthenticating = false
            handleResult(result)
        }
    }

    private func handleResult(_ result: BiometricAuthManager.AuthResult) {
        switch result {
        case .success:
            authState.recordAuthentication()
            errorMessage = nil
            failureCount = 0
        case .failure(let msg):
            failureCount += 1
            errorMessage = msg
        case .cancelled:
            errorMessage = nil
        case .unavailable:
            failureCount += 1
            errorMessage = "Authentication unavailable. Set up Face ID or a passcode in Settings."
        }
    }
}
