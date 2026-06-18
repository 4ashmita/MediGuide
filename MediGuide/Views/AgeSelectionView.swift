import SwiftUI

struct AgeSelectionView: View {
    @StateObject private var vm = AgeSelectionViewModel()
    @ObservedObject var coordinator: ManualEntryCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How old are they?")
                    .font(.title2.bold())
                    .padding(.horizontal)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach([AgeGroup.infant, .child, .teenager, .adult, .elderly], id: \.self) { group in
                        ageCard(group)
                    }
                }
                .padding(.horizontal)

                unknownAgeRow
                    .padding(.horizontal)

                if vm.ageIsEstimated {
                    Text("We'll use adult as a default. Adjust if you have a better estimate.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 100)
        }
        .overlay(alignment: .bottom) { nextButton }
        .navigationTitle("Age Group")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.15), value: vm.ageIsEstimated)
    }

    // MARK: - Age Card

    private func ageCard(_ group: AgeGroup) -> some View {
        Button {
            vm.select(group)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: group.selectionIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(vm.selectedAgeGroup == group ? .red : .secondary)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.rawValue.capitalized)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(group.ageRangeLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if vm.selectedAgeGroup == group && !vm.ageIsEstimated {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(vm.selectedAgeGroup == group && !vm.ageIsEstimated
                          ? Color.red.opacity(0.07)
                          : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(vm.selectedAgeGroup == group && !vm.ageIsEstimated
                            ? Color.red : Color.clear,
                            lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Age Unknown Row

    private var unknownAgeRow: some View {
        Button {
            vm.select(.adult, estimated: true)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
                Text("Age unknown")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if vm.ageIsEstimated {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(vm.ageIsEstimated ? Color(.systemGray5) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Next Button

    private var nextButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                guard let group = vm.selectedAgeGroup else { return }
                coordinator.confirm(ageGroup: group, estimated: vm.ageIsEstimated)
            } label: {
                Text("Next")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(vm.isNextEnabled ? Color.red : Color.gray.opacity(0.3))
                    .cornerRadius(14)
            }
            .disabled(!vm.isNextEnabled)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - AgeGroup display helpers

private extension AgeGroup {
    var ageRangeLabel: String {
        switch self {
        case .infant:   return "Under 2 years old"
        case .child:    return "2 to 12 years old"
        case .teenager: return "13 to 17 years old"
        case .adult:    return "18 to 64 years old"
        case .elderly:  return "65 years and older"
        }
    }
}
