import Foundation
import Combine
import SwiftUI

// MARK: - Step Enum

enum ManualEntryStep {
    case ageSelection
    case conditionsSelection
}

// MARK: - Coordinator

@MainActor
final class ManualEntryCoordinator: ObservableObject {
    @Published var step: ManualEntryStep = .ageSelection
    @Published var selectedAgeGroup: AgeGroup = .adult
    @Published var ageIsEstimated: Bool = false
    let conditionToggleVM = ConditionToggleViewModel()

    func confirm(ageGroup: AgeGroup, estimated: Bool) {
        selectedAgeGroup = ageGroup
        ageIsEstimated = estimated
        step = .conditionsSelection
    }

    func startSession(sessionManager: SessionManager) {
        let conditions = conditionToggleVM.exportConditionIds()
        sessionManager.startManualSession(ageGroup: selectedAgeGroup, conditions: conditions)
    }
}

// MARK: - Flow Container

struct ManualEntryFlowView: View {
    @StateObject private var coordinator = ManualEntryCoordinator()
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            switch coordinator.step {
            case .ageSelection:
                AgeSelectionView(coordinator: coordinator)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                    }
            case .conditionsSelection:
                ManualConditionsView(coordinator: coordinator) {
                    dismiss()
                    coordinator.startSession(sessionManager: sessionManager)
                }
            }
        }
    }
}

// MARK: - Conditions Step

struct ManualConditionsView: View {
    @ObservedObject var coordinator: ManualEntryCoordinator
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ageSummaryBanner
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Known Conditions")
                        .font(.headline.weight(.semibold))
                        .padding(.horizontal)
                    Text("Optional — skip if unknown. These apply to this session only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    ConditionToggleView(vm: coordinator.conditionToggleVM)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Known Conditions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { coordinator.step = .ageSelection }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Start Triage") { onStart() }
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
        }
    }

    private var ageSummaryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: coordinator.selectedAgeGroup.selectionIcon)
                .font(.title2)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text(coordinator.selectedAgeGroup.rawValue.capitalized)
                    .font(.subheadline.bold())
                if coordinator.ageIsEstimated {
                    Text("Age estimated — using adult as default")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Change") { coordinator.step = .ageSelection }
                .font(.caption.bold())
                .foregroundStyle(.red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
