import SwiftUI

struct ScoreVisualizerView: View {
    let color: Color
    let isHardOverride: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .scaleEffect(pulse ? 1.35 : 1.0)
            .animation(
                isHardOverride
                    ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                    : .easeInOut(duration: 0.2),
                value: pulse
            )
            .onAppear { pulse = isHardOverride }
            .onChange(of: isHardOverride) { _, newValue in pulse = newValue }
            .accessibilityHidden(true)
    }
}
