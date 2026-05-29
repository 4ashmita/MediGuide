import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var engine: TriageEngine
    @StateObject private var navigationManager: NavigationManager
    @StateObject private var sessionManager: SessionManager
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let treeData = try DecisionTreeLoader.load()
            let engine = TriageEngine(treeData: treeData)
            let navManager = NavigationManager(treeData: treeData, engine: engine)
            let appState = AppState()
            let sessionManager = SessionManager(engine: engine, navigationManager: navManager, appState: appState)

            _engine = StateObject(wrappedValue: engine)
            _navigationManager = StateObject(wrappedValue: navManager)
            _appState = StateObject(wrappedValue: appState)
            _sessionManager = StateObject(wrappedValue: sessionManager)
        } catch {
            fatalError("Failed to load DecisionTree.json: \(error.localizedDescription)")
        }
    }

    var body: some View {
        Group {
            switch appState.activeScreen {
            case .profileCreation:
                ProfileCreationView(
                    onComplete: { appState.activeScreen = .welcome },
                    onSkip: { appState.activeScreen = .welcome }
                )
            case .welcome:
                WelcomeView()
            case .profileSelection:
                ProfileSelectionView()
            case .triage:
                QuestionView()
            case .results:
                ResultsView()
            }
        }
        .environmentObject(engine)
        .environmentObject(navigationManager)
        .environmentObject(appState)
        .environmentObject(sessionManager)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                sessionManager.handleDidEnterBackground()
            case .active:
                sessionManager.handleWillEnterForeground()
            default:
                break
            }
        }
        .onChange(of: navigationManager.isComplete) { _, isComplete in
            if isComplete { appState.activeScreen = .results }
        }
    }
}
