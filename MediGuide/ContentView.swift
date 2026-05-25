import SwiftUI

struct ContentView: View {
    @StateObject private var engine: TriageEngine
    @StateObject private var navigationManager: NavigationManager

    init() {
        do {
            let treeData = try DecisionTreeLoader.load()
            let engine = TriageEngine(treeData: treeData)
            _engine = StateObject(wrappedValue: engine)
            _navigationManager = StateObject(wrappedValue: NavigationManager(treeData: treeData, engine: engine))
        } catch {
            fatalError("Failed to load DecisionTree.json: \(error.localizedDescription)")
        }
    }

    var body: some View {
        QuestionView()
            .environmentObject(engine)
            .environmentObject(navigationManager)
    }
}
