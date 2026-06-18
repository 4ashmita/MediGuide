import SwiftUI

struct TriageProgressView: View {
    @ObservedObject var vm: TriageProgressViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Tick marks divide the bar into four zones matching the four phases.
    private let tickPositions: [Double] = [0.25, 0.50, 0.75]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            topRow
            progressBar
            if let estimate = vm.state.timeEstimate {
                Text(estimate)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.75))
                    .contentTransition(reduceMotion ? .identity : .opacity)
                    .animation(.easeInOut(duration: 0.3), value: estimate)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Top row: phase label | question counter | score dot

    private var topRow: some View {
        HStack(spacing: 6) {
            Text(vm.state.phase.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
                .contentTransition(reduceMotion ? .identity : .opacity)
                .animation(.easeInOut(duration: 0.3), value: vm.state.phase.rawValue)
                .accessibilityAddTraits(.updatesFrequently)

            Spacer()

            if !vm.state.questionLabel.isEmpty {
                Text(vm.state.questionLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: vm.state.questionLabel)
            }

            ScoreVisualizerView(
                color: vm.state.tierDotColor,
                isHardOverride: vm.state.isHardOverride
            )
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.13))
                    .frame(height: 5)

                // Filled portion — animated unless reduce motion
                if vm.state.isProcessing {
                    shimmerBar(width: geo.size.width)
                } else {
                    Capsule()
                        .fill(vm.state.barColor)
                        .frame(
                            width: max(0, geo.size.width * vm.state.barProgress),
                            height: 5
                        )
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.82),
                            value: vm.state.barProgress
                        )
                }

                // Phase tick marks
                ForEach(tickPositions, id: \.self) { pos in
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .frame(width: 1.5, height: 7)
                        .offset(x: geo.size.width * pos - 0.75)
                }
            }
            .frame(height: 7)
        }
        .frame(height: 7)
    }

    // Indeterminate shimmer used during NLP / photo API processing.
    @ViewBuilder
    private func shimmerBar(width: CGFloat) -> some View {
        if reduceMotion {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: width * 0.6, height: 5)
        } else {
            ShimmerBar(barWidth: width, color: vm.state.barColor)
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        let pct = Int(vm.state.barProgress * 100)
        var parts: [String] = [vm.state.phase.rawValue]
        if !vm.state.questionLabel.isEmpty { parts.append(vm.state.questionLabel) }
        parts.append("Progress \(pct) percent")
        if let t = vm.state.timeEstimate { parts.append(t) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Shimmer helper

private struct ShimmerBar: View {
    let barWidth: CGFloat
    let color: Color
    @State private var offset: CGFloat = -0.5

    var body: some View {
        Capsule()
            .fill(color.opacity(0.35))
            .frame(width: barWidth * 0.55, height: 5)
            .offset(x: offset * barWidth)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    offset = 1.0
                }
            }
            .clipped()
    }
}
