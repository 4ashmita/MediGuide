import SwiftUI

struct EscalationButton: View {
    @EnvironmentObject var engine: TriageEngine
    @State private var showConfirmation = false

    private var isAtMaximum: Bool { engine.currentTier == .call911 }
    private var hasEscalated: Bool { engine.session.escalationCount > 0 }

    var body: some View {
        Button(action: {
            if !isAtMaximum { showConfirmation = true }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.subheadline)
                Text(isAtMaximum ? "Already at Maximum Urgency" : hasEscalated ? "Escalate Further" : "This Feels More Serious")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isAtMaximum ? .secondary : Color(red: 1.0, green: 0.55, blue: 0.0))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isAtMaximum ? Color.secondary.opacity(0.3) : Color(red: 1.0, green: 0.55, blue: 0.0),
                        lineWidth: 1.5
                    )
            )
        }
        .disabled(isAtMaximum)
        .sheet(isPresented: $showConfirmation) {
            EscalationConfirmationView(
                currentTier: engine.currentTier,
                onConfirm: {
                    engine.triggerInstinctOverride()
                    showConfirmation = false
                },
                onCancel: {
                    showConfirmation = false
                }
            )
            .presentationDetents([.medium])
        }
        .accessibilityLabel(
            isAtMaximum
                ? "Already at maximum urgency level"
                : "This feels more serious. Escalates recommendation to a higher level of care."
        )
    }
}
