import SwiftUI

struct ConditionToggleView: View {
    @ObservedObject var vm: ConditionToggleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(vm.groups) { group in
                categorySection(group)
            }
            otherSection
        }
    }

    // MARK: - Category Section

    private func categorySection(_ group: ConditionGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            categoryHeader(group)

            if group.isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    if group.category == .immune {
                        immuneSection(group)
                    } else if group.category == .reproductive {
                        reproductiveSection(group)
                    } else {
                        ForEach(group.conditions, id: \.conditionId) { entry in
                            conditionRow(entry)
                        }
                    }
                }
                .padding(.bottom, 4)
            }

            Divider()
        }
    }

    // MARK: - Category Header

    private func categoryHeader(_ group: ConditionGroup) -> some View {
        Button(action: { vm.toggleCategoryExpanded(group.category) }) {
            HStack {
                Text(group.category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if !group.isExpanded && group.activeCount > 0 {
                    Text("\(group.activeCount) active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: group.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Standard Condition Row

    private func conditionRow(_ entry: ConditionEntry) -> some View {
        Toggle(isOn: Binding(
            get: { vm.isActive(entry.conditionId) },
            set: { _ in vm.toggleCondition(entry.conditionId) }
        )) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(entry.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(vm.isActive(entry.conditionId) ? Color.red.opacity(0.06) : Color.clear)
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.15), value: vm.isActive(entry.conditionId))
    }

    // MARK: - Immune Section

    private func immuneSection(_ group: ConditionGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Non-immuno-subtype conditions first (e.g. autoimmune)
            ForEach(group.conditions.filter { !$0.isImmunoSubtype }, id: \.conditionId) { entry in
                conditionRow(entry)
            }

            // Immunocompromised group header (not a toggle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Immunocompromised")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Select all that apply — each type you are currently affected by.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)

            // 4 sub-type toggles
            ForEach(group.conditions.filter { $0.isImmunoSubtype }, id: \.conditionId) { entry in
                conditionRow(entry)
                    .padding(.leading, 8)
            }
        }
    }

    // MARK: - Reproductive Section

    private func reproductiveSection(_ group: ConditionGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Non-pregnancy conditions (none currently, but future-proof)
            ForEach(group.conditions.filter { !$0.isPregnancyStage && !$0.isPregnancyRisk && !$0.isImmunoSubtype }, id: \.conditionId) { entry in
                conditionRow(entry)
            }

            // Pregnancy toggle
            pregnancyToggleSection
        }
    }

    // MARK: - Pregnancy Toggle + Sub-options

    private var pregnancyToggleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: Binding(
                get: { vm.isPregnantToggleOn },
                set: { vm.setPregnantToggle($0) }
            )) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Pregnancy")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("Trimester affects risk weighting. Risk factors lower the threshold for urgent evaluation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(vm.isPregnantToggleOn ? Color.red.opacity(0.06) : Color.clear)
            .cornerRadius(8)

            if vm.isPregnantToggleOn {
                VStack(alignment: .leading, spacing: 12) {
                    trimesterPicker
                    pregnancyRiskFactors
                }
                .padding(.leading, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.isPregnantToggleOn)
    }

    private var trimesterPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stage")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(ConditionList.pregnancyStages, id: \.conditionId) { stage in
                Button(action: { vm.selectTrimester(stage.conditionId) }) {
                    HStack {
                        Text(stage.displayName.replacingOccurrences(of: "Pregnancy — ", with: ""))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        if vm.selectedTrimesterId == stage.conditionId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(vm.selectedTrimesterId == stage.conditionId
                        ? Color.red.opacity(0.08) : Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }

    private var pregnancyRiskFactors: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk factors (optional)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text("Having any risk factor lowers the symptom threshold for urgent evaluation.")
                .font(.caption2)
                .foregroundColor(.secondary)

            ForEach(ConditionList.pregnancyRisks, id: \.conditionId) { risk in
                Button(action: { vm.togglePregnancyRisk(risk.conditionId) }) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: vm.isPregnancyRiskActive(risk.conditionId)
                              ? "checkmark.square.fill" : "square")
                            .font(.body)
                            .foregroundColor(vm.isPregnancyRiskActive(risk.conditionId) ? .red : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(risk.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text(risk.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(vm.isPregnancyRiskActive(risk.conditionId)
                        ? Color.red.opacity(0.06) : Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Other Free Text

    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Other")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.top, 12)
            Text("Any condition not listed above.")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Describe any other condition", text: $vm.otherNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }
}
