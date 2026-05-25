import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var engine: TriageEngine
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                tierHeader
                VStack(alignment: .leading, spacing: 28) {
                    explanationSection
                    primaryActionButton
                    if !engine.warningSigns.isEmpty { warningSignsSection }
                    firstAidSection
                    whatToBringSection
                    whatToExpectSection
                    escalationSection
                    if let minutes = content.reassessmentMinutes { reassessmentSection(minutes: minutes) }
                    restartButton
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Content

    private var content: TierContent {
        RecommendationContent.content(for: engine.currentTier)
    }

    private var tierColor: Color {
        switch engine.currentTier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }

    // MARK: - Tier Header

    private var tierHeader: some View {
        ZStack(alignment: .bottom) {
            tierColor.ignoresSafeArea(edges: .top)
            VStack(spacing: 12) {
                Image(systemName: engine.currentTier.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                Text(engine.currentTier.displayName)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(content.timeSensitivity)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.bottom, 32)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 240)
    }

    // MARK: - Explanation

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Why this recommendation")
            Text(content.explanation)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Primary Action

    private var primaryActionButton: some View {
        Button(action: primaryAction) {
            HStack(spacing: 10) {
                Image(systemName: engine.currentTier.icon)
                Text(primaryActionLabel)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tierColor)
            .cornerRadius(14)
        }
    }

    private var primaryActionLabel: String {
        switch engine.currentTier {
        case .call911:    return "Call 911 Now"
        case .goToER:     return "Get Directions to ER"
        case .urgentCare: return "Find Nearest Urgent Care"
        case .monitor:    return "Set Check-In Reminder"
        }
    }

    private func primaryAction() {
        switch engine.currentTier {
        case .call911:
            if let url = URL(string: "tel://911") { UIApplication.shared.open(url) }
        case .goToER, .urgentCare:
            let query = engine.currentTier == .goToER ? "Emergency+Room" : "Urgent+Care"
            if let url = URL(string: "maps://?q=\(query)") { UIApplication.shared.open(url) }
        case .monitor:
            break
        }
    }

    // MARK: - Warning Signs

    private var warningSignsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Call 911 immediately if:")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(engine.warningSigns, id: \.self) { sign in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .padding(.top, 3)
                        Text(sign)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // MARK: - First Aid Steps

    private var firstAidSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("What to do right now")
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(content.firstAidSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(tierColor)
                            .clipShape(Circle())
                        Text(step)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - What to Bring

    @ViewBuilder
    private var whatToBringSection: some View {
        if !content.whatToBring.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("What to bring")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(content.whatToBring, id: \.self) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(tierColor)
                                .font(.caption)
                                .padding(.top, 3)
                            Text(item)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    // MARK: - What to Expect

    private var whatToExpectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("What to expect")
            Text(content.whatToExpect)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
        }
    }

    // MARK: - Escalation

    private var escalationSection: some View {
        Button(action: {
            engine.triggerInstinctOverride()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Something feels more serious")
                        .fontWeight(.semibold)
                        .font(.subheadline)
                    Text("Tap to escalate to the next level of care")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
        }
        .disabled(engine.currentTier == .call911)
        .opacity(engine.currentTier == .call911 ? 0 : 1)
    }

    // MARK: - Reassessment Timer

    private func reassessmentSection(minutes: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Re-assess in")
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .foregroundColor(tierColor)
                Text(minutes >= 60 ? "\(minutes / 60) hour\(minutes / 60 > 1 ? "s" : "")" : "\(minutes) minutes")
                    .fontWeight(.semibold)
                Spacer()
                Text("If symptoms change, seek care sooner")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .background(tierColor.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // MARK: - Restart

    private var restartButton: some View {
        Button(action: navigationManager.restart) {
            Text("Start Over")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.12))
                .cornerRadius(12)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
}
