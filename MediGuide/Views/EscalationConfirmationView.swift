import SwiftUI

struct EscalationConfirmationView: View {
    let currentTier: RecommendationTier
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var newTier: RecommendationTier {
        switch currentTier {
        case .monitor:    return .urgentCare
        case .urgentCare: return .goToER
        case .goToER:     return .call911
        case .call911:    return .call911
        }
    }

    private var tierColor: Color {
        switch newTier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.0))

                Text("Trust Your Instinct")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You know this situation best. We'll increase the urgency of our recommendation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            tierTransitionView
                .padding(.vertical, 28)
                .padding(.horizontal, 24)

            Divider()

            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text("Yes, Escalate")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tierColor)
                        .cornerRadius(12)
                }

                Button(action: onCancel) {
                    Text("Cancel")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }

    private var tierTransitionView: some View {
        VStack(spacing: 12) {
            tierRow(tier: currentTier, label: "Current")

            Image(systemName: "arrow.down")
                .font(.title3)
                .foregroundColor(.secondary)

            tierRow(tier: newTier, label: "After escalation")
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(14)
    }

    private func tierRow(tier: RecommendationTier, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tier.icon)
                .foregroundColor(colorFor(tier))
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(tier.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
    }

    private func colorFor(_ tier: RecommendationTier) -> Color {
        switch tier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }
}
