import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        Form {
            Section("Units") {
                Picker("Temperature", selection: Binding(
                    get: { store.tempUnitFahrenheit },
                    set: { store.tempUnitFahrenheit = $0 }
                )) {
                    Text("Fahrenheit (°F)").tag(true)
                    Text("Celsius (°C)").tag(false)
                }
                Picker("Distance", selection: Binding(
                    get: { store.distanceUnitMiles },
                    set: { store.distanceUnitMiles = $0 }
                )) {
                    Text("Miles").tag(true)
                    Text("Kilometers").tag(false)
                }
            }
            Section {
                HStack {
                    Image(systemName: "phone.fill").foregroundColor(.red)
                    Text("Emergency number: 911")
                    Spacer()
                }
                Text("If you are outside the US the emergency number may differ. Always verify your local emergency number.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Emergency Services")
            }
            Section("Language") {
                Text("App language follows your iOS system language setting.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Open Language Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle("Language & Region")
        .navigationBarTitleDisplayMode(.inline)
    }
}
