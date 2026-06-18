import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)
                Text("MediGuide")
                    .font(.largeTitle)
                    .fontWeight(.black)
                Text("Emergency guidance when it matters most")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
    }
}
