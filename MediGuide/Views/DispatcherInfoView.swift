import SwiftUI

struct DispatcherInfoView: View {
    let session: TriageSession

    private let tips: [(String, String)] = [
        ("Give your location first", "Street address or cross streets — say it immediately."),
        ("Stay calm and speak clearly", "Answer every question the dispatcher asks."),
        ("Don't hang up", "Stay on the line until dispatch tells you to."),
        ("Follow their instructions", "They may guide you through first aid until help arrives.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("While waiting for help")
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(tips, id: \.0) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.0).fontWeight(.semibold)
                        Text(tip.1).font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            if hasProfileData {
                Divider()
                Text("Show this to responders")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    if !session.sessionDisplayName.isEmpty {
                        profileRow("person.fill", session.sessionDisplayName)
                    }
                    if !session.sessionBloodType.isEmpty {
                        profileRow("drop.fill", "Blood type: \(session.sessionBloodType)")
                    }
                    if !session.sessionMedicationList.isEmpty {
                        profileRow("pill.fill", session.sessionMedicationList)
                    }
                    if !session.sessionAllergyList.isEmpty {
                        profileRow("exclamationmark.triangle.fill", "Allergies: \(session.sessionAllergyList)")
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private var hasProfileData: Bool {
        !session.sessionDisplayName.isEmpty || !session.sessionBloodType.isEmpty ||
        !session.sessionMedicationList.isEmpty || !session.sessionAllergyList.isEmpty
    }

    private func profileRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundColor(.orange)
            Text(text).font(.subheadline)
        }
    }
}
