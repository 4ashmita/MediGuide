import SwiftUI

struct ProfileSummaryCard: View {
    let profile: UserProfile
    let report: CompletenessReport
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onStartTriage: () -> Void
    var onReview: () -> Void

    @State private var conditionsExpanded = false
    @State private var medicationsExpanded = false
    @State private var allergiesExpanded = false

    private var accentColor: Color {
        let palette: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint, .cyan]
        return palette[abs(profile.id.hashValue) % palette.count]
    }

    private var anaphylacticAllergies: [AllergyEntry] {
        profile.allergies.filter { $0.severity == .anaphylactic }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
                .padding(.horizontal, 16)
                .padding(.top, 14)

            ProfileHealthIndicator(
                report: report,
                onTap: report.status == .outdated ? onReview
                     : report.status == .incomplete ? onEdit
                     : nil
            )
                .padding(.horizontal, 16)
                .padding(.top, 10)

            if report.status == .incomplete {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(report.issues.filter { $0.category != .outdated }) { issue in
                        Label(issue.description, systemImage: "arrow.right.circle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)
            }

            Divider()
                .padding(.top, 10)

            conditionsSection
                .padding(.horizontal, 16)
                .padding(.top, 10)

            medicationsRow
                .padding(.horizontal, 16)
                .padding(.top, 8)

            allergiesRow
                .padding(.horizontal, 16)
                .padding(.top, 6)

            Divider()
                .padding(.top, 10)

            metaRows
                .padding(.horizontal, 16)
                .padding(.top, 8)

            quickActions
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 14)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            avatarCircle

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(.headline)

                Text(ageLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let rel = profile.relationship {
                    Text(rel.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.15))
                .frame(width: 52, height: 52)
            Text(profile.displayName.prefix(1).uppercased())
                .font(.title2.bold())
                .foregroundColor(accentColor)
        }
    }

    private var ageLabel: String {
        let age = profile.age
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextBirthday).day ?? 999
        if days <= 7 {
            return "\(age) yrs — turns \(age + 1) in \(days) day\(days == 1 ? "" : "s")"
        }
        return "\(age) years old"
    }

    private var nextBirthday: Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.month, .day], from: profile.dateOfBirth)
        comps.year = cal.component(.year, from: Date())
        guard var next = cal.date(from: comps) else { return Date.distantFuture }
        if next <= Date() { next = cal.date(byAdding: .year, value: 1, to: next) ?? next }
        return next
    }

    // MARK: - Conditions

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if profile.conditions.isEmpty {
                Text("No conditions recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                let displayed = conditionsExpanded ? profile.conditions : Array(profile.conditions.prefix(5))
                let extra = profile.conditions.count - 5

                FlowLayout(spacing: 6) {
                    ForEach(displayed, id: \.self) { condId in
                        conditionBadge(condId)
                    }
                    if !conditionsExpanded && extra > 0 {
                        Text("+\(extra) more")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(10)
                            .onTapGesture { conditionsExpanded = true }
                    }
                }

                if conditionsExpanded && profile.conditions.count > 5 {
                    Button("Show less") { conditionsExpanded = false }
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func conditionBadge(_ condId: String) -> some View {
        let entry = ConditionList.all.first { $0.conditionId == condId }
        let label = entry?.displayName ?? condId
        let color = conditionColor(for: entry?.category ?? .other)
        return Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
    }

    private func conditionColor(for category: ConditionCategory) -> Color {
        switch category {
        case .cardiovascular: return .red
        case .metabolic:      return .blue
        case .respiratory:    return .green
        case .immune:         return .orange
        case .reproductive:   return .pink
        case .neurological:   return .purple
        case .organFunction:  return .teal
        case .mentalHealth:   return .indigo
        case .other:          return .secondary
        }
    }

    // MARK: - Medications

    private var medicationsRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: { medicationsExpanded.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: "pills.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if profile.medications.isEmpty {
                        Text("No medications recorded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(profile.medications.count) medication\(profile.medications.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: medicationsExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(profile.medications.isEmpty)

            if medicationsExpanded {
                ForEach(profile.medications) { med in
                    Text("• \(med.name)\(med.note.isEmpty ? "" : " (\(med.note))")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 18)
                }
            }
        }
    }

    // MARK: - Allergies

    private var allergiesRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: { allergiesExpanded.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(profile.allergies.isEmpty ? .secondary : .orange)
                    if profile.allergies.isEmpty {
                        Text("No allergies recorded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(profile.allergies.count) allerg\(profile.allergies.count == 1 ? "y" : "ies")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !anaphylacticAllergies.isEmpty {
                            Text("\(anaphylacticAllergies.count) anaphylactic")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .cornerRadius(6)
                        }
                        Image(systemName: allergiesExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(profile.allergies.isEmpty)

            if allergiesExpanded {
                ForEach(profile.allergies) { allergy in
                    HStack(spacing: 4) {
                        Text("• \(allergy.allergen)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("(\(allergy.severity.displayName))")
                            .font(.caption2)
                            .foregroundColor(allergy.severity == .anaphylactic ? .red : .secondary)
                    }
                    .padding(.leading, 18)
                }
            }
        }
    }

    // MARK: - Meta Rows

    private var metaRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: profile.emergencyContactPhone.isEmpty ? "phone.badge.exclamationmark.fill" : "phone.fill")
                    .font(.caption)
                    .foregroundColor(profile.emergencyContactPhone.isEmpty ? .red : .green)
                Text(profile.emergencyContactPhone.isEmpty
                     ? "No emergency contact — SMS feature disabled"
                     : "Emergency contact saved")
                    .font(.caption)
                    .foregroundColor(profile.emergencyContactPhone.isEmpty ? .red : .secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(profile.bloodType == .unknown ? "Blood type: Unknown" : "Blood type: \(profile.bloodType.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(lastTriagedLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var lastTriagedLabel: String {
        let cal = Calendar.current
        let now = Date()
        let daysSince = cal.dateComponents([.day], from: profile.lastUsed, to: now).day ?? 0

        // If lastUsed is very close to dateCreated, profile hasn't been used in triage
        let wasUsed = abs(profile.lastUsed.timeIntervalSince(profile.dateCreated)) > 60
        guard wasUsed else { return "Never triaged" }

        if daysSince < 1 { return "Last triaged today" }
        if daysSince < 7 { return "Last triaged \(daysSince) day\(daysSince == 1 ? "" : "s") ago" }
        let weeks = daysSince / 7
        if weeks < 5 { return "Last triaged \(weeks) week\(weeks == 1 ? "" : "s") ago" }
        let months = daysSince / 30
        return "Last triaged \(months) month\(months == 1 ? "" : "s") ago"
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button(action: onStartTriage) {
                Label("Start Triage", systemImage: "stethoscope")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Button(action: { shareProfile() }) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.caption.bold())
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.1))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    private func shareProfile() {
        // AirDrop sharing — serializes public (non-sensitive) profile fields only
        let summary = "\(profile.displayName), \(profile.age) yrs — Blood type: \(profile.bloodType.rawValue)"
        let av = UIActivityViewController(activityItems: [summary], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}

// MARK: - FlowLayout helper (wraps badges to next line)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(in: proposal.width ?? 300, subviews: subviews)
        let height = rows.map { $0.map { $0.size.height }.max() ?? 0 }.reduce(0, +)
            + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 300, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(in: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.size.height }.max() ?? 0
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(in width: CGFloat, subviews: Subviews) -> [[(view: LayoutSubview, size: CGSize)]] {
        var rows: [[(view: LayoutSubview, size: CGSize)]] = [[]]
        var x: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && !rows.last!.isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append((view, size))
            x += size.width + spacing
        }
        return rows.filter { !$0.isEmpty }
    }
}
