import SwiftUI

struct TriageSettingsView: View {
    @ObservedObject private var store = SettingsStore.shared

    private let inputModeLabels = ["Natural Language", "Guided Questions", "Ask Each Time"]
    private let warningDetailLabels = ["Brief", "Standard", "Detailed"]
    private let instinctStyleLabels = ["Subtle", "Normal", "Prominent"]

    var body: some View {
        Form {
            inputModeSection
            reassessmentSection
            behaviorSection
            warningSection
        }
        .navigationTitle("Triage Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var inputModeSection: some View {
        Section {
            Picker("Default Input Mode", selection: Binding(
                get: { store.defaultInputMode },
                set: { store.defaultInputMode = $0 }
            )) {
                ForEach(0..<inputModeLabels.count, id: \.self) { i in
                    Text(inputModeLabels[i]).tag(i)
                }
            }
        } header: {
            Text("Input")
        } footer: {
            Text("\"Ask Each Time\" prompts you at the start of each triage whether to type naturally or answer guided questions.")
        }
    }

    private var reassessmentSection: some View {
        Section {
            Stepper(
                "ER: \(store.reassessIntervalER) min",
                value: Binding(
                    get: { store.reassessIntervalER },
                    set: { store.reassessIntervalER = $0 }
                ),
                in: 5...60,
                step: 5
            )
            Stepper(
                "Urgent Care: \(store.reassessIntervalUC) min",
                value: Binding(
                    get: { store.reassessIntervalUC },
                    set: { store.reassessIntervalUC = $0 }
                ),
                in: 15...120,
                step: 15
            )
            Stepper(
                "Monitor at Home: \(store.reassessIntervalMonitor) min",
                value: Binding(
                    get: { store.reassessIntervalMonitor },
                    set: { store.reassessIntervalMonitor = $0 }
                ),
                in: 30...480,
                step: 30
            )
        } header: {
            Text("Reassessment Intervals")
        } footer: {
            Text("How often to prompt a check-in after giving a recommendation.")
        }
    }

    private var behaviorSection: some View {
        Section {
            Toggle("Auto-Escalation", isOn: Binding(
                get: { store.autoEscalation },
                set: { store.autoEscalation = $0 }
            ))
            Picker("\"Something Feels Wrong\" Button", selection: Binding(
                get: { store.instinctButtonStyle },
                set: { store.instinctButtonStyle = $0 }
            )) {
                ForEach(0..<instinctStyleLabels.count, id: \.self) { i in
                    Text(instinctStyleLabels[i]).tag(i)
                }
            }
            Toggle("Show Score Explanation", isOn: Binding(
                get: { store.showScoreExplanation },
                set: { store.showScoreExplanation = $0 }
            ))
        } header: {
            Text("Behavior")
        } footer: {
            Text("Auto-Escalation automatically upgrades the recommendation tier if symptoms worsen at check-in.")
        }
    }

    private var warningSection: some View {
        Section {
            Picker("Warning Sign Detail", selection: Binding(
                get: { store.warningDetailLevel },
                set: { store.warningDetailLevel = $0 }
            )) {
                ForEach(0..<warningDetailLabels.count, id: \.self) { i in
                    Text(warningDetailLabels[i]).tag(i)
                }
            }
        } header: {
            Text("Warnings")
        } footer: {
            Text("Controls how much detail is shown in the warning signs list on the results screen.")
        }
    }
}
