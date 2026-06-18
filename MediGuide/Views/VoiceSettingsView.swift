import SwiftUI

struct VoiceSettingsView: View {
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        Form {
            masterSection
            if store.voiceNarration {
                narrationSection
            }
            alertTonesSection
        }
        .navigationTitle("Voice & Audio")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var masterSection: some View {
        Section {
            Toggle("Voice Narration", isOn: Binding(
                get: { store.voiceNarration },
                set: { store.voiceNarration = $0 }
            ))
            Toggle("Voice Commands", isOn: Binding(
                get: { store.voiceCommands },
                set: { store.voiceCommands = $0 }
            ))
        } header: {
            Text("Speech")
        } footer: {
            Text("Voice Narration reads instructions and recommendations aloud. Voice Commands lets you navigate by speaking.")
        }
    }

    private var narrationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Narration Speed")
                    Spacer()
                    Text(speedLabel)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Image(systemName: "tortoise.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Slider(
                        value: Binding(
                            get: { store.narrationSpeed },
                            set: { store.narrationSpeed = $0 }
                        ),
                        in: 0.1...1.0,
                        step: 0.1
                    )
                    Image(systemName: "hare.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            Toggle("Auto-Read Recommendations", isOn: Binding(
                get: { store.autoReadRecommendation },
                set: { store.autoReadRecommendation = $0 }
            ))
            Toggle("Auto-Read First Aid Steps", isOn: Binding(
                get: { store.autoReadFirstAid },
                set: { store.autoReadFirstAid = $0 }
            ))
        } header: {
            Text("Narration")
        }
    }

    private var alertTonesSection: some View {
        Section {
            Toggle("911 Countdown Tone", isOn: Binding(
                get: { store.alertToneCountdown },
                set: { store.alertToneCountdown = $0 }
            ))
            Toggle("Timer Alert Tone", isOn: Binding(
                get: { store.alertToneTimer },
                set: { store.alertToneTimer = $0 }
            ))
            Toggle("CPR Rhythm Tone", isOn: Binding(
                get: { store.alertToneCPR },
                set: { store.alertToneCPR = $0 }
            ))
        } header: {
            Text("Alert Tones")
        } footer: {
            Text("Alert tones play during time-critical steps to keep your attention on the patient, not the screen.")
        }
    }

    private var speedLabel: String {
        let speed = store.narrationSpeed
        switch speed {
        case ..<0.3: return "Slow"
        case 0.3..<0.6: return "Normal"
        case 0.6..<0.85: return "Fast"
        default: return "Very Fast"
        }
    }
}
