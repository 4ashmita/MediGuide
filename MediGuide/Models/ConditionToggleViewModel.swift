import Foundation
import Combine

final class ConditionToggleViewModel: ObservableObject {

    // MARK: - Category Groups

    @Published var groups: [ConditionGroup] = []

    // MARK: - Active State

    @Published private(set) var activeConditionIds: Set<String> = []

    // MARK: - Pregnancy State

    @Published var isPregnantToggleOn: Bool = false
    @Published var selectedTrimesterId: String? = nil
    @Published var activePregnancyRiskIds: Set<String> = []

    // MARK: - Other

    @Published var otherNote: String = ""

    // MARK: - Init

    init(initialConditions: [String] = [], otherNote: String = "") {
        self.otherNote = otherNote
        buildGroups()
        applyInitialConditions(initialConditions)
    }

    // MARK: - Build Groups

    private func buildGroups() {
        groups = ConditionCategory.allCases.compactMap { category -> ConditionGroup? in
            let conditions = ConditionList.all.filter {
                $0.category == category && !$0.isPregnancyStage && !$0.isPregnancyRisk
            }
            guard !conditions.isEmpty else { return nil }
            return ConditionGroup(
                category: category,
                conditions: conditions,
                isExpanded: true,
                activeCount: 0
            )
        }
    }

    // MARK: - Load Initial State

    private func applyInitialConditions(_ conditionIds: [String]) {
        let ids = Set(conditionIds)

        // Pregnancy stage
        for stage in ConditionList.pregnancyStages where ids.contains(stage.conditionId) {
            isPregnantToggleOn = true
            selectedTrimesterId = stage.conditionId
            break
        }

        // Pregnancy risk factors
        for risk in ConditionList.pregnancyRisks where ids.contains(risk.conditionId) {
            activePregnancyRiskIds.insert(risk.conditionId)
        }

        // Standard conditions (excludes pregnancy stages/risks)
        let nonPregnancyIds = ids.subtracting(
            Set(ConditionList.pregnancyStages.map { $0.conditionId })
            .union(Set(ConditionList.pregnancyRisks.map { $0.conditionId }))
        )
        activeConditionIds = nonPregnancyIds
        refreshActiveCounts()
    }

    // MARK: - Toggle Condition

    func toggleCondition(_ id: String) {
        if activeConditionIds.contains(id) {
            activeConditionIds.remove(id)
        } else {
            activeConditionIds.insert(id)
        }
        refreshActiveCounts()
    }

    func isActive(_ id: String) -> Bool { activeConditionIds.contains(id) }

    // MARK: - Pregnancy

    func setPregnantToggle(_ on: Bool) {
        isPregnantToggleOn = on
        if !on {
            selectedTrimesterId = nil
            activePregnancyRiskIds.removeAll()
        }
        refreshActiveCounts()
    }

    func selectTrimester(_ id: String) {
        selectedTrimesterId = id
    }

    func togglePregnancyRisk(_ id: String) {
        if activePregnancyRiskIds.contains(id) {
            activePregnancyRiskIds.remove(id)
        } else {
            activePregnancyRiskIds.insert(id)
        }
    }

    func isPregnancyRiskActive(_ id: String) -> Bool { activePregnancyRiskIds.contains(id) }

    // MARK: - Category Expansion

    func toggleCategoryExpanded(_ category: ConditionCategory) {
        if let idx = groups.firstIndex(where: { $0.category == category }) {
            groups[idx].isExpanded.toggle()
        }
    }

    func activeCount(for category: ConditionCategory) -> Int {
        groups.first { $0.category == category }?.activeCount ?? 0
    }

    // MARK: - Export

    func exportConditionIds() -> [String] {
        var ids = Array(activeConditionIds)
        if isPregnantToggleOn, let tid = selectedTrimesterId {
            ids.append(tid)
        }
        ids.append(contentsOf: activePregnancyRiskIds)
        return ids
    }

    // MARK: - Helpers

    private func refreshActiveCounts() {
        for idx in groups.indices {
            let cat = groups[idx].category
            let count = groups[idx].conditions.filter { activeConditionIds.contains($0.conditionId) }.count
            let pregnancyBonus = (cat == .reproductive && isPregnantToggleOn) ? 1 : 0
            groups[idx].activeCount = count + pregnancyBonus
        }
    }
}
