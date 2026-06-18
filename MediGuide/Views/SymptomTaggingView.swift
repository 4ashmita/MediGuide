import SwiftUI

struct SymptomTaggingView: View {
    let findings: VisualSymptomParser.ParsedVisualFindings
    let hardOverrideIds: Set<String>
    let onConfirm: ([String]) -> Void
    let onDismiss: () -> Void

    @State private var showManualPicker = false
    @State private var confirmedLowIds: Set<String> = []
    @State private var manualSelectedIds: Set<String> = []

    private var primaryFindings: [CalibratedFinding] {
        findings.calibratedFindings.filter { $0.calibratedConfidence != .low }
    }

    private var lowFindings: [CalibratedFinding] {
        findings.calibratedFindings.filter { $0.calibratedConfidence == .low }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            dragHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if showManualPicker {
                        manualPicker
                    } else {
                        confirmedFindingsList
                        if !lowFindings.isEmpty { lowFindingsList }
                        disclaimer
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            actionRow
        }
    }

    // MARK: - Sub-views

    private var dragHandle: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 20)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(showManualPicker ? "Select what you observe" : "Does this match what you see?")
                .font(.headline)
            Text(showManualPicker
                 ? "Tap everything that applies. These replace the detected findings."
                 : "Based on the photo we identified:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var confirmedFindingsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if primaryFindings.isEmpty {
                Label("No clear symptoms identified from this photo.", systemImage: "exclamationmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(primaryFindings, id: \.symptomId) { finding in
                    findingRow(finding: finding)
                }
            }
        }
    }

    private func findingRow(finding: CalibratedFinding) -> some View {
        let isOverride = hardOverrideIds.contains(finding.symptomId)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: isOverride ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isOverride ? .red : .green)
                .font(.body)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(VisualSymptomReferenceProvider.description(for: finding.symptomId))
                    .font(.subheadline)
                    .foregroundStyle(isOverride ? .red : .primary)
                if let note = finding.clinicalNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(finding.originalFinding.plainDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding(12)
        .background(
            isOverride
                ? Color.red.opacity(0.06)
                : Color(.systemGray6),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    private var lowFindingsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Also noticed — confirm if these apply:")
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.secondary)
            ForEach(lowFindings, id: \.symptomId) { finding in
                lowFindingRow(finding: finding)
            }
        }
    }

    private func lowFindingRow(finding: CalibratedFinding) -> some View {
        let isChecked = confirmedLowIds.contains(finding.symptomId)
        return Button {
            if isChecked { confirmedLowIds.remove(finding.symptomId) }
            else { confirmedLowIds.insert(finding.symptomId) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isChecked ? .blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(VisualSymptomReferenceProvider.description(for: finding.symptomId))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(finding.originalFinding.plainDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manual picker

    private var manualPicker: some View {
        let sortedIds = VisualSymptomReferenceProvider.visualSymptomIds.sorted()
        return LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(sortedIds, id: \.self) { id in
                manualToggleRow(id: id)
            }
        }
    }

    private func manualToggleRow(id: String) -> some View {
        let isSelected = manualSelectedIds.contains(id)
        return Button {
            if isSelected { manualSelectedIds.remove(id) }
            else { manualSelectedIds.insert(id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                Text(VisualSymptomReferenceProvider.description(for: id))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(12)
            .background(
                isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .buttonStyle(.plain)
    }

    private var disclaimer: some View {
        Text("Photo analysis provides additional context. It does not replace a professional examination. Always describe other symptoms using words or guided questions.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Actions

    private var actionRow: some View {
        VStack(spacing: 10) {
            Divider()
            VStack(spacing: 10) {
                Button(action: confirmAction) {
                    Text(showManualPicker ? "Use selected symptoms" : "Yes, continue")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                HStack(spacing: 20) {
                    if !showManualPicker {
                        Button { showManualPicker = true } label: {
                            Text("Something's different")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Text("Skip photo analysis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func confirmAction() {
        if showManualPicker {
            onConfirm(Array(manualSelectedIds))
        } else {
            let primaryIds = primaryFindings.map(\.symptomId)
            let confirmedLow = Array(confirmedLowIds)
            onConfirm(primaryIds + confirmedLow)
        }
    }
}
