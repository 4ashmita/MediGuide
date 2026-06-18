import SwiftUI

struct AccessibilitySettingsView: View {
    @ObservedObject private var store = SettingsStore.shared

    private let textSizeLabels = ["Small", "Default", "Large", "Extra Large", "Maximum"]
    private let previewFontSizes: [CGFloat] = [13, 15, 17, 20, 24]

    var body: some View {
        Form {
            textSizeSection
            displaySection
            layoutSection
            brightnessSection
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var textSizeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Text Size")
                    Spacer()
                    Text(textSizeLabels[store.textSizeLevel])
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 8) {
                    Text("A").font(.caption)
                    Slider(
                        value: Binding(
                            get: { Double(store.textSizeLevel) },
                            set: { store.textSizeLevel = Int($0.rounded()) }
                        ),
                        in: 0...4,
                        step: 1
                    )
                    Text("A").font(.title3)
                }
                Text("This is how body text will appear throughout the app.")
                    .font(.system(size: previewFontSizes[store.textSizeLevel]))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Text Size")
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Toggle("High Contrast", isOn: Binding(
                get: { store.highContrast },
                set: { store.highContrast = $0 }
            ))
            Toggle("Reduce Motion", isOn: Binding(
                get: { store.reduceMotion },
                set: { store.reduceMotion = $0 }
            ))
            Toggle("Bold Text", isOn: Binding(
                get: { store.boldText },
                set: { store.boldText = $0 }
            ))
            Toggle("Pill-shaped Buttons", isOn: Binding(
                get: { store.pillShapeButtons },
                set: { store.pillShapeButtons = $0 }
            ))
        }
    }

    private var layoutSection: some View {
        Section {
            Toggle("One-Handed Mode", isOn: Binding(
                get: { store.oneHandedMode },
                set: { store.oneHandedMode = $0 }
            ))
            Toggle("Large UI for Elderly", isOn: Binding(
                get: { store.elderlyLargeUI },
                set: { store.elderlyLargeUI = $0 }
            ))
        } header: {
            Text("Layout")
        } footer: {
            Text("Large UI increases tap targets and simplifies each screen for easier use.")
        }
    }

    private var brightnessSection: some View {
        Section {
            Toggle("Maximize Brightness During Emergencies", isOn: Binding(
                get: { store.maxBrightnessEmergency },
                set: { store.maxBrightnessEmergency = $0 }
            ))
        } footer: {
            Text("When a Call 911 recommendation is given, the screen brightness is maximized for better readability.")
        }
    }
}
