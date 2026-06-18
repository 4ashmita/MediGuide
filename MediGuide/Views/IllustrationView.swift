import SwiftUI

struct IllustrationView: View {
    let key: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 160)
                VStack(spacing: 10) {
                    Image(systemName: symbolForKey(key))
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary)
                    Text(labelForKey(key))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private func symbolForKey(_ key: String) -> String {
        let map: [String: String] = [
            "scene_safety":           "eye.fill",
            "check_responsiveness":   "hand.tap.fill",
            "position_cpr":           "figure.roll",
            "hand_position_cpr":      "hand.raised.fill",
            "hand_position_infant":   "hand.point.up.left.fill",
            "compressions_cpr":       "waveform.path.ecg",
            "airway_opening":         "arrow.up.heart.fill",
            "airway_opening_infant":  "arrow.up.heart",
            "rescue_breath":          "lungs.fill",
            "rescue_breath_infant":   "lungs",
            "direct_pressure":        "bandage.fill",
            "hand_protection":        "hands.sparkles.fill",
            "tourniquet":             "staple",
            "elevate_limb":           "arrow.up.circle.fill",
            "search_epipen":          "bag.fill",
            "epipen_use":             "syringe.fill",
            "ana_position":           "figure.roll",
            "cardiac_position":       "heart.fill",
            "loosen_clothing":        "scissors",
            "time_recording":         "clock.fill",
            "fast_assessment":        "checkmark.circle.fill",
            "head_elevation":         "arrow.up.and.down",
            "seizure_clear":          "arrow.left.and.right",
            "protect_head":           "shield.fill",
            "recovery_position":      "figure.roll.runningpace",
        ]
        return map[key] ?? "photo"
    }

    private func labelForKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
