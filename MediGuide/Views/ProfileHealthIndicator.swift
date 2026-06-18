import SwiftUI

struct ProfileHealthIndicator: View {
    let report: CompletenessReport
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.caption)
                    .foregroundColor(barColor)
                    .frame(width: 14)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 5)
                        Capsule()
                            .fill(barColor)
                            .frame(width: max(0, geo.size.width * CGFloat(report.score) / 100), height: 5)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 5)

                Text(labelText)
                    .font(.caption)
                    .foregroundColor(barColor)
                    .fixedSize()
            }
            .frame(height: 18)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var barColor: Color {
        switch report.status {
        case .complete:   return .green
        case .outdated:   return .orange
        case .incomplete: return report.score >= 60 ? Color(red: 0.85, green: 0.65, blue: 0) : .red
        }
    }

    private var iconName: String {
        switch report.status {
        case .complete:   return "checkmark.circle.fill"
        case .outdated:   return "clock.fill"
        case .incomplete:
            return report.score >= 60 ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill"
        }
    }

    private var labelText: String {
        switch report.status {
        case .complete:   return "Profile complete"
        case .outdated:   return "Consider reviewing"
        case .incomplete:
            let n = report.issues.count
            return "Fix \(n) item\(n == 1 ? "" : "s")"
        }
    }
}
