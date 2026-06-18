import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var engine: TriageEngine
    @StateObject private var navigationManager: NavigationManager
    @StateObject private var sessionManager: SessionManager
    @StateObject private var authState = AuthStateManager.shared
    @StateObject private var appearanceManager = AppearanceManager()
    @StateObject private var emergencyCoordinator = EmergencyButtonCoordinator()
    @StateObject private var appNavManager = AppNavigationManager()
    @StateObject private var progressVM: TriageProgressViewModel
    @StateObject private var wakeVM = ScreenWakeViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLaunching: Bool = true

    init() {
        do {
            let treeData = try DecisionTreeLoader.load()
            let engine = TriageEngine(treeData: treeData)
            let navManager = NavigationManager(treeData: treeData, engine: engine)
            let appState = AppState()
            let sessionManager = SessionManager(engine: engine, navigationManager: navManager, appState: appState)

            // AppRouter determines the correct initial screen before first render
            AppRouter.route(into: appState, sessionManager: sessionManager)

            _engine = StateObject(wrappedValue: engine)
            _navigationManager = StateObject(wrappedValue: navManager)
            _appState = StateObject(wrappedValue: appState)
            _sessionManager = StateObject(wrappedValue: sessionManager)
            _progressVM = StateObject(wrappedValue: TriageProgressViewModel(engine: engine, navigationManager: navManager))
        } catch {
            fatalError("Failed to load DecisionTree.json: \(error.localizedDescription)")
        }
    }

    var body: some View {
        ZStack {
            mainContent

            if isLaunching {
                LaunchScreenView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
                isLaunching = false
            }
        }
        .environment(\.dynamicTypeSize, appearanceManager.dynamicTypeSize)
        .environment(\.legibilityWeight, appearanceManager.legibilityWeight)
        .environmentObject(engine)
        .environmentObject(navigationManager)
        .environmentObject(appState)
        .environmentObject(sessionManager)
        .environmentObject(authState)
        .environmentObject(appearanceManager)
        .environmentObject(emergencyCoordinator)
        .environmentObject(appNavManager)
        .environmentObject(progressVM)
        .environmentObject(wakeVM)
        .sheet(isPresented: $emergencyCoordinator.showQuickConfirmation) {
            QuickCallConfirmationView(
                context: emergencyCoordinator.activeContext,
                profileName: appState.activeProfileName,
                onConfirm: {
                    appNavManager.willStartCountdown(from: emergencyCoordinator.activeContext, appState: appState)
                    emergencyCoordinator.confirm(appState: appState)
                },
                onCancel: { emergencyCoordinator.cancel() }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: Binding(
            get: { authState.requiresAuthentication && profileAccessScreenActive },
            set: { _ in }
        )) {
            PrivacyGateView()
                .environmentObject(authState)
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showSessionRecovery) {
            SessionRecoveryView()
                .environmentObject(sessionManager)
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $appState.isEmergencyCountdownRunning) {
            EmergencyAlertView(session: engine.session)
                .environmentObject(appState)
                .environmentObject(emergencyCoordinator)
                .environmentObject(wakeVM)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                sessionManager.handleDidEnterBackground()
                authState.handleBackground()
                AppLifecycleObserver.handleBackground()
            case .active:
                sessionManager.handleWillEnterForeground()
                authState.handleForeground()
                AppLifecycleObserver.handleForeground()
                if sessionManager.hasInterruptedSession
                    && appState.activeScreen != .triage
                    && appState.activeScreen != .results {
                    appState.showSessionRecovery = true
                }
            default:
                break
            }
        }
        .onChange(of: navigationManager.isComplete) { _, isComplete in
            if isComplete { appState.activeScreen = .results }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch appState.activeScreen {
        case .profileCreation:
            ProfileCreationView(
                onComplete: {
                    if ProfileRepository.profileCount <= 1 {
                        appState.showFirstTimeCelebration = true
                    }
                    appState.activeScreen = .welcome
                },
                onSkip: { appState.activeScreen = .welcome }
            )
        case .welcome:
            WelcomeView()
        case .profileSelection:
            ProfileSelectionView()
        case .profileList:
            NavigationStack {
                ProfileManagementView(onDone: { appState.activeScreen = .welcome })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EmergencyButtonView(context: .noSession)
                        }
                    }
            }
        case .naturalLanguageInput:
            NaturalLanguageInputView(engine: engine)
        case .triage:
            QuestionView()
        case .results:
            ResultsView()
        }
    }

    // Derives the correct EmergencyContext based on current app state
    var currentEmergencyContext: EmergencyContext {
        if appState.isEmergencyCountdownRunning { return .countdownActive }
        switch appState.activeScreen {
        case .naturalLanguageInput, .triage:
            return .activeTriage
        case .results:
            return engine.currentTier == .call911 ? .resultsCall911 : .resultsLowerTier
        case .profileCreation:
            return .profileEditing
        default:
            return .noSession
        }
    }

    // Show privacy gate on screens that access profile data
    private var profileAccessScreenActive: Bool {
        switch appState.activeScreen {
        case .profileSelection, .profileList, .naturalLanguageInput, .triage, .results:
            return true
        case .profileCreation, .welcome:
            return false
        }
    }
}
