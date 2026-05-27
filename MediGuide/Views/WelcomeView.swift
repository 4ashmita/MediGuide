import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.red)
                Text("MediGuide")
                    .font(.largeTitle)
                    .fontWeight(.black)
                Text("Medical triage guidance for\nemergencies and urgent situations.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button(action: {
                    let profile = ProfileStore.loadAll().first
                    sessionManager.startSession(with: profile)
                }) {
                    Text("Start Triage")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(14)
                }

                Text("MediGuide does not replace professional medical advice.\nAlways call 911 if you believe there is an immediate danger to life.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
