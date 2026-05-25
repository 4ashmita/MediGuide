import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var engine: TriageEngine
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                emergencyButton

                tierHeader

                if !engine.warningSigns.isEmpty {
                    warningSigns
                }

                restartButton
            }
            .padding()
        }
    }

    // MARK: - Subviews

    private var emergencyButton: some View {
        Button(action: { /* 911 call flow — built in Emergency Response feature */ }) {
            Text("Call 911")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(10)
        }
    }

    private var tierHeader: some View {
        Text(engine.currentTier.displayName)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(tierColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(tierColor.opacity(0.1))
            .cornerRadius(12)
    }

    private var warningSigns: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch for these warning signs:")
                .font(.headline)

            ForEach(engine.warningSigns, id: \.self) { sign in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(sign)
                        .font(.subheadline)
                }
            }
        }
    }

    private var restartButton: some View {
        Button(action: navigationManager.restart) {
            Text("Start Over")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Helpers

    private var tierColor: Color {
        switch engine.currentTier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }
}
