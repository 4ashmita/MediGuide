import SwiftUI
import Combine

struct StepTimerView: View {
    let totalSeconds: Int
    let onComplete: () -> Void

    @State private var secondsRemaining: Int
    @State private var isComplete = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(totalSeconds: Int, onComplete: @escaping () -> Void) {
        self.totalSeconds = totalSeconds
        self.onComplete = onComplete
        _secondsRemaining = State(initialValue: totalSeconds)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return 1 - Double(secondsRemaining) / Double(totalSeconds)
    }

    private var timerColor: Color { isComplete ? .green : .blue }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(timerColor.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                VStack(spacing: 2) {
                    Text(formattedTime)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(timerColor)
                    if isComplete {
                        Text("Done")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(width: 110, height: 110)

            if isComplete {
                Label("Timer complete — move to next step", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            } else {
                Text("Keep going — do not stop")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(timerColor.opacity(0.06))
        .cornerRadius(16)
        .onReceive(tick) { _ in
            guard !isComplete else { return }
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            }
            if secondsRemaining == 0 {
                isComplete = true
                onComplete()
            }
        }
    }

    private var formattedTime: String {
        let h = secondsRemaining / 3600
        let m = (secondsRemaining % 3600) / 60
        let s = secondsRemaining % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}
