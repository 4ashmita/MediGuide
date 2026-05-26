import SwiftUI

struct ReassessmentPromptView: View {
    let tier: RecommendationTier
    let minutesElapsed: Int
    let onResponse: (ReassessmentResponse) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                currentRecommendationCard
                responseSection
                escalationLink
            }
            .padding()
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Time to Check In")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text("It's been \(elapsedLabel). How are they doing now?")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Current Recommendation Card

    private var currentRecommendationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current recommendation")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: tier.icon)
                    .foregroundColor(tierColor)
                Text(tier.displayName)
                    .fontWeight(.semibold)
            }
            Text("Given \(minutesElapsed) minute\(minutesElapsed == 1 ? "" : "s") ago")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tierColor.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Response Options

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How are they doing compared to \(minutesElapsed) minute\(minutesElapsed == 1 ? "" : "s") ago?")
                .font(.headline)

            VStack(spacing: 10) {
                switch tier {
                case .monitor:
                    monitorOptions
                case .urgentCare:
                    urgentCareOptions
                case .goToER:
                    erOptions
                case .call911:
                    EmptyView()
                }
            }
        }
    }

    private var monitorOptions: some View {
        Group {
            responseButton(label: "Better", icon: "hand.thumbsup.fill", color: .green) {
                onResponse(.better)
            }
            responseButton(label: "About the Same", icon: "minus.circle.fill", color: .orange) {
                onResponse(.sameMonitor)
            }
            responseButton(label: "Worse", icon: "hand.thumbsdown.fill", color: .red) {
                onResponse(.worse)
            }
        }
    }

    private var urgentCareOptions: some View {
        Group {
            responseButton(label: "Better", icon: "hand.thumbsup.fill", color: .green) {
                onResponse(.better)
            }
            responseButton(label: "About the Same — on my way / going soon", icon: "car.fill", color: .orange) {
                onResponse(.sameOnWay)
            }
            responseButton(label: "About the Same — haven't left yet", icon: "house.fill", color: Color(red: 1.0, green: 0.55, blue: 0.0)) {
                onResponse(.sameNotGone)
            }
            responseButton(label: "Worse", icon: "hand.thumbsdown.fill", color: .red) {
                onResponse(.worse)
            }
        }
    }

    private var erOptions: some View {
        Group {
            responseButton(label: "Better", icon: "hand.thumbsup.fill", color: .green) {
                onResponse(.better)
            }
            responseButton(label: "About the Same — on my way", icon: "car.fill", color: .orange) {
                onResponse(.sameOnWay)
            }
            responseButton(label: "About the Same — haven't left yet", icon: "house.fill", color: Color(red: 1.0, green: 0.55, blue: 0.0)) {
                onResponse(.sameNotGone)
            }
            responseButton(label: "Worse", icon: "hand.thumbsdown.fill", color: .red) {
                onResponse(.worse)
            }
            responseButton(label: "I can't get to the car / too sick to travel", icon: "exclamationmark.triangle.fill", color: .red) {
                onResponse(.cantTravel)
            }
        }
    }

    // MARK: - Escalation Link

    private var escalationLink: some View {
        Button(action: { onResponse(.worse) }) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption)
                Text("Something feels seriously wrong")
                    .font(.subheadline)
            }
            .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.0))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Helpers

    private func responseButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 28)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
    }

    private var elapsedLabel: String {
        if minutesElapsed < 60 {
            return "\(minutesElapsed) minute\(minutesElapsed == 1 ? "" : "s")"
        } else {
            let h = minutesElapsed / 60
            return "\(h) hour\(h == 1 ? "" : "s")"
        }
    }

    private var tierColor: Color {
        switch tier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }
}
