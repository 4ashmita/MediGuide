import SwiftUI

struct ProfileCard: View {
    enum Context { case triage, management }

    let summary: ProfileSummary
    let isStale: Bool
    let context: Context
    var isPreHighlighted: Bool = false
    var onTap: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    // Deterministic accent color derived from profile ID — stable across launches
    var accentColor: Color {
        let palette: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint, .cyan]
        let idx = abs(summary.id.hashValue) % palette.count
        return palette[idx]
    }

    private var relationshipLabel: String? {
        summary.relationship.map { $0.rawValue }
    }

    var body: some View {
        switch context {
        case .triage:     triageCard
        case .management: managementCard
        }
    }

    // MARK: - Triage Card

    private var triageCard: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                avatarCircle
                VStack(alignment: .leading, spacing: 4) {
                    nameRow
                    ageRow
                    conditionsSummaryRow
                    if isStale { staleNote }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isPreHighlighted ? accentColor : .clear, lineWidth: 2)
                    )
            )
            .shadow(color: isPreHighlighted ? accentColor.opacity(0.2) : .black.opacity(0.06),
                    radius: isPreHighlighted ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Management Card

    private var managementCard: some View {
        HStack(spacing: 14) {
            avatarCircle
            VStack(alignment: .leading, spacing: 4) {
                nameRow
                ageRow
                if let label = relationshipLabel {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                conditionsSummaryRow
                lastUpdatedRow
                if isStale { staleNote }
            }
            Spacer()
            VStack(spacing: 8) {
                Button(action: { onEdit?() }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Subviews

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.15))
                .frame(width: 52, height: 52)
            Text(summary.displayName.prefix(1).uppercased())
                .font(.title2.bold())
                .foregroundStyle(accentColor)
        }
    }

    private var nameRow: some View {
        HStack(spacing: 6) {
            Text(summary.displayName)
                .font(.headline)
            if isPreHighlighted {
                Text("Recent")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(accentColor)
            }
            if isStale {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var ageRow: some View {
        Text("\(summary.age) yrs · \(summary.ageGroup.rawValue.capitalized)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var conditionsSummaryRow: some View {
        Group {
            if !summary.conditionsSummary.isEmpty {
                Text(summary.conditionsSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var lastUpdatedRow: some View {
        Text("Updated \(summary.dateModified.formatted(.relative(presentation: .named)))")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    private var staleNote: some View {
        Text("Profile may be outdated — consider updating")
            .font(.caption2)
            .foregroundStyle(.orange)
    }
}
