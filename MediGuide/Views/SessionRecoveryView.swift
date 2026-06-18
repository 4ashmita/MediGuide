import SwiftUI

struct SessionRecoveryView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState

    private var profileLabel: String {
        appState.activeProfileName ?? "your previous session"
    }

    private var timeAgoLabel: String {
        let elapsed = Date().timeIntervalSince(sessionManager.engine.session.sessionStartTime)
        let minutes = Int(elapsed / 60)
        if minutes < 1 { return "just now" }
        if minutes == 1 { return "1 minute ago" }
        if minutes < 60 { return "\(minutes) minutes ago" }
        let hours = minutes / 60
        return hours == 1 ? "about 1 hour ago" : "about \(hours) hours ago"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                    Text("Resume Previous Session?")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("You were triaging for \(profileLabel) — \(timeAgoLabel)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                Spacer()
                VStack(spacing: 12) {
                    Button(action: resumeSession) {
                        Text("Resume Session")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(14)
                    }
                    Button(action: startFresh) {
                        Text("Start Fresh")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Interrupted Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { appState.showSessionRecovery = false }
                }
            }
        }
    }

    private func resumeSession() {
        appState.showSessionRecovery = false
        appState.activeScreen = .triage
    }

    private func startFresh() {
        sessionManager.endSession()
        appState.showPostSessionContext = false
        appState.showSessionRecovery = false
    }
}
