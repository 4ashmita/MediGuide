import SwiftUI
import Combine

struct CPRTimerView: View {

    @State private var compressionCount = 0
    @State private var totalCompressions = 0
    @State private var cycleCount = 0
    @State private var inBreathPause = false
    @State private var breathSecondsRemaining = 5
    @State private var elapsedSeconds = 0
    @State private var pulse = false

    // 110 BPM ≈ 0.545s per beat
    private let compressionTick = Timer.publish(every: 0.545, on: .main, in: .common).autoconnect()
    private let secondTick      = Timer.publish(every: 1,     on: .main, in: .common).autoconnect()
    private let feedback        = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(spacing: 20) {
            elapsedTimeLabel

            if inBreathPause {
                breathPrompt
            } else {
                compressionDisplay
            }

            aedReminder
        }
        .padding()
        .background(Color.red.opacity(0.06))
        .cornerRadius(16)
        .onReceive(compressionTick) { _ in handleCompressionTick() }
        .onReceive(secondTick)      { _ in handleSecondTick() }
        .onAppear { feedback.prepare() }
    }

    // MARK: - Sub-views

    private var elapsedTimeLabel: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            Text("CPR in progress: \(formattedElapsed)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .monospacedDigit()
            Spacer()
            Text("\(totalCompressions) compressions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var compressionDisplay: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .scaleEffect(pulse ? 1.25 : 1.0)
                    .animation(.easeOut(duration: 0.12), value: pulse)
            }

            VStack(spacing: 4) {
                Text("\(compressionCount)")
                    .font(.system(size: 52, weight: .black))
                    .monospacedDigit()
                    .foregroundColor(.red)
                Text("of 30")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Push hard and fast — 2 inches deep")
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }

    private var breathPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 52))
                .foregroundColor(.blue)

            Text("Give 2 Rescue Breaths")
                .font(.title3)
                .fontWeight(.bold)

            Text("Tilt head back, lift chin. One breath per second.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Resuming in \(breathSecondsRemaining)s…")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(12)
    }

    private var aedReminder: some View {
        Group {
            if elapsedSeconds > 0 && elapsedSeconds % 120 == 0 {
                Label("Check for an AED nearby", systemImage: "bolt.heart.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(10)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Timer Handlers

    private func handleCompressionTick() {
        guard !inBreathPause else { return }
        compressionCount += 1
        totalCompressions += 1

        pulse = true
        feedback.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { pulse = false }

        if compressionCount >= 30 {
            compressionCount = 0
            cycleCount += 1
            inBreathPause = true
            breathSecondsRemaining = 5
        }
    }

    private func handleSecondTick() {
        elapsedSeconds += 1
        if inBreathPause {
            breathSecondsRemaining -= 1
            if breathSecondsRemaining <= 0 {
                inBreathPause = false
            }
        }
    }

    private var formattedElapsed: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
