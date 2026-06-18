import SwiftUI

struct WarningSignsView: View {
    let tier: RecommendationTier
    let warnings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(accentColor)
                Text(header)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(warnings, id: \.self) { sign in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(sign)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }

    private var header: String {
        switch tier {
        case .call911:    return "Call 911 Immediately If:"
        case .goToER:     return "Call 911 or Go to ER If:"
        case .urgentCare: return "Go to ER Immediately If:"
        case .monitor:    return "Seek Medical Care If:"
        }
    }

    private var accentColor: Color {
        switch tier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }
}
