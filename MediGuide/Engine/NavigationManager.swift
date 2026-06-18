import Foundation
import Combine

final class NavigationManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentNode: TreeNode?
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var canGoBack: Bool = false

    // MARK: - Private

    private let treeData: DecisionTreeData
    private let engine: TriageEngine

    private struct NavigationEntry {
        let node: TreeNode
        let addedSymptomId: String?
        let addedModifierId: String?
        let addedAgeGroupId: String?
    }
    private var navigationStack: [NavigationEntry] = []
    private var nodesToSkip: Set<String> = []

    var questionNumber: Int { navigationStack.count + 1 }

    func setNodesToSkip(_ ids: Set<String>) {
        nodesToSkip = ids
    }

    // MARK: - Init

    init(treeData: DecisionTreeData, engine: TriageEngine, startingNodeId: String? = nil) {
        self.treeData = treeData
        self.engine = engine
        let nodeId = startingNodeId ?? treeData.startNode
        self.currentNode = DecisionTreeLoader.getNodeById(nodeId, from: treeData)
    }

    // MARK: - Navigation

    func advance(via option: NodeOption) {
        if let symptomId = option.symptomId {
            engine.addSymptom(symptomId)
        }
        if let modifierId = option.modifierId {
            engine.addModifier(modifierId)
        }
        if let ageGroupId = option.ageGroupId,
           let ageGroup = AgeGroup(rawValue: ageGroupId) {
            engine.setAgeGroup(ageGroup)
        }

        if option.next == "result" {
            isComplete = true
            return
        }

        if let current = currentNode {
            navigationStack.append(NavigationEntry(
                node: current,
                addedSymptomId: option.symptomId,
                addedModifierId: option.modifierId,
                addedAgeGroupId: option.ageGroupId
            ))
            canGoBack = true
        }

        if let nextNode = DecisionTreeLoader.getNodeById(option.next, from: treeData) {
            if nodesToSkip.contains(nextNode.id), let skipTarget = conditionSkipTarget(for: nextNode) {
                currentNode = DecisionTreeLoader.getNodeById(skipTarget, from: treeData) ?? nextNode
            } else {
                currentNode = nextNode
            }
        } else {
            isComplete = true
        }
    }

    // Returns the fallback destination of a node that only asks about pre-existing conditions,
    // so the node can be skipped when a profile has already loaded those modifiers.
    private func conditionSkipTarget(for node: TreeNode) -> String? {
        let hasSymptomOptions = node.options.contains { $0.symptomId != nil }
        guard !hasSymptomOptions else { return nil }
        let hasModifierOptions = node.options.contains { $0.modifierId != nil }
        guard hasModifierOptions else { return nil }
        // The "None of these" option has no modifier — its next is the safe skip destination
        return node.options.first { $0.modifierId == nil && $0.symptomId == nil }?.next
    }

    func goBack() {
        guard let last = navigationStack.popLast() else { return }

        if let symptomId = last.addedSymptomId {
            engine.removeSymptom(symptomId)
        }
        if let modifierId = last.addedModifierId {
            engine.removeModifier(modifierId)
        }
        if last.addedAgeGroupId != nil {
            engine.setAgeGroup(.adult)
        }

        isComplete = false
        currentNode = last.node
        canGoBack = !navigationStack.isEmpty
    }

    func restart() {
        navigationStack.removeAll()
        nodesToSkip = []
        isComplete = false
        canGoBack = false
        currentNode = DecisionTreeLoader.getNodeById(treeData.startNode, from: treeData)
        engine.reset()
    }

    func restart(startingAt nodeId: String) {
        navigationStack.removeAll()
        nodesToSkip = []
        isComplete = false
        canGoBack = false
        currentNode = DecisionTreeLoader.getNodeById(nodeId, from: treeData)
    }
}
