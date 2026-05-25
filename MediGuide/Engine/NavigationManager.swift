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
            currentNode = nextNode
        } else {
            isComplete = true
        }
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
        isComplete = false
        canGoBack = false
        currentNode = DecisionTreeLoader.getNodeById(treeData.startNode, from: treeData)
        engine.reset()
    }
}
