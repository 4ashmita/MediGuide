import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var engine: TriageEngine
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: EmergencyButtonCoordinator
    @EnvironmentObject var wakeVM: ScreenWakeViewModel
    @StateObject private var timer = ReassessmentTimer()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showReassessmentPrompt = false
    @State private var showSwitchConfirm = false
    @State private var showProfileSwitcher = false
    @State private var showFirstAid = false
    @State private var registeredWakeContext: WakeContext? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            tierHeader
                            VStack(alignment: .leading, spacing: 28) {
                                if engine.session.escalationCount > 0 { escalationBadge }
                                explanationSection
                                primaryActionButton
                                secondaryActionButton(proxy: proxy)
                                if !engine.warningSigns.isEmpty {
                                    WarningSignsView(tier: engine.currentTier, warnings: engine.warningSigns)
                                }
                                firstAidSection
                                    .id("firstAid")
                                whatToBringSection
                                whatToExpectSection
                                if let minutes = content.reassessmentMinutes { reassessmentSection(minutes: minutes) }
                                restartButton
                            }
                            .padding()
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }

                Divider()
                EscalationButton()
                    .padding(.horizontal)
                    .padding(.vertical, 12)
            }
            .tierTransition(tier: engine.currentTier)

            EmergencyButtonView(
                context: engine.currentTier == .call911 ? .resultsCall911 : .resultsLowerTier
            )
            .padding(.top, 56)
            .padding(.trailing, EmergencyButtonStyleGuide.trailingPadding)
        }
        .onAppear {
            timer.startTimer(for: engine.currentTier)
            applyWakeContext(for: engine.currentTier)
        }
        .onDisappear {
            releaseWakeContext()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background: timer.pause()
            case .active:     timer.resume()
            default:          break
            }
        }
        .onChange(of: timer.didExpire) { expired in
            if expired {
                showReassessmentPrompt = true
                timer.acknowledgeExpiry()
            }
        }
        .onChange(of: engine.currentTier) { _, newTier in
            timer.reset()
            timer.startTimer(for: newTier)
            applyWakeContext(for: newTier)
        }
        .background(switchProfileModifiers)
        .fullScreenCover(isPresented: $showReassessmentPrompt) {
            if let tier = timer.tier {
                ReassessmentPromptView(
                    tier: tier,
                    minutesElapsed: timer.minutesElapsed
                ) { response in
                    let shouldRestart = engine.reassess(
                        response: response,
                        minutesElapsed: timer.minutesElapsed
                    )
                    showReassessmentPrompt = false
                    if shouldRestart {
                        timer.reset()
                        timer.startTimer(for: engine.currentTier)
                    } else {
                        timer.reset()
                    }
                }
            }
        }
    }

    // MARK: - Wake Helpers

    private func wakeContext(for tier: RecommendationTier) -> WakeContext? {
        switch tier {
        case .call911:    return .call911Recommendation
        case .goToER:     return .goToERRecommendation
        case .urgentCare: return .urgentCareRecommendation
        case .monitor:    return nil
        }
    }

    private func applyWakeContext(for tier: RecommendationTier) {
        if let old = registeredWakeContext { wakeVM.deactivate(context: old) }
        let new = wakeContext(for: tier)
        if let new { wakeVM.activate(context: new) }
        registeredWakeContext = new
    }

    private func releaseWakeContext() {
        if let ctx = registeredWakeContext {
            wakeVM.deactivate(context: ctx)
            registeredWakeContext = nil
        }
    }

    // MARK: - Content

    private var content: TierContent {
        RecommendationContent.content(for: engine.currentTier)
    }

    private var tierColor: Color {
        switch engine.currentTier {
        case .call911:    return .red
        case .goToER:     return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .urgentCare: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .monitor:    return Color(red: 0.0, green: 0.67, blue: 0.0)
        }
    }

    // MARK: - Tier Header

    private var tierHeader: some View {
        ZStack(alignment: .bottom) {
            tierColor.ignoresSafeArea(edges: .top)
            VStack(spacing: 12) {
                Image(systemName: engine.currentTier.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                Text(engine.currentTier.displayName)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(content.timeSensitivity)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.bottom, 32)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 240)
    }

    // MARK: - Escalation Badge

    private var escalationBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill.checkmark")
                .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.0))
            Text("Escalated based on your concern")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.0))
            Spacer()
            if engine.session.escalationCount > 1 {
                Text("×\(engine.session.escalationCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 1.0, green: 0.55, blue: 0.0))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Explanation

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Why this recommendation")
            Text(content.explanation)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Primary Action

    private var primaryActionButton: some View {
        Button(action: primaryAction) {
            HStack(spacing: 10) {
                Image(systemName: engine.currentTier.icon)
                Text(primaryActionLabel)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tierColor)
            .cornerRadius(14)
        }
    }

    private var primaryActionLabel: String {
        switch engine.currentTier {
        case .call911:    return "Call 911 Now"
        case .goToER:     return "Get Directions to ER"
        case .urgentCare: return "Find Nearest Urgent Care"
        case .monitor:    return "Set Check-In Reminder"
        }
    }

    private func primaryAction() {
        switch engine.currentTier {
        case .call911:
            coordinator.buttonTapped(context: .resultsCall911, appState: appState)
        case .goToER, .urgentCare:
            let query = engine.currentTier == .goToER ? "Emergency+Room" : "Urgent+Care"
            if let url = URL(string: "maps://?q=\(query)") { UIApplication.shared.open(url) }
        case .monitor:
            break
        }
    }

    // MARK: - Secondary Action

    private func secondaryActionButton(proxy: ScrollViewProxy) -> some View {
        Button(action: { secondaryAction(proxy: proxy) }) {
            HStack(spacing: 8) {
                Image(systemName: secondaryIcon)
                Text(secondaryLabel)
                    .fontWeight(.semibold)
            }
            .foregroundColor(tierColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(tierColor, lineWidth: 1.5)
            )
        }
        .accessibilityLabel(secondaryLabel)
    }

    private var secondaryLabel: String {
        switch engine.currentTier {
        case .call911:    return "View First Aid Steps"
        case .goToER:     return "Call 911 Instead"
        case .urgentCare: return "Find ER Instead"
        case .monitor:    return "Find Urgent Care if Needed"
        }
    }

    private var secondaryIcon: String {
        switch engine.currentTier {
        case .call911:    return "cross.case.fill"
        case .goToER:     return "phone.fill"
        case .urgentCare: return "building.2.fill"
        case .monitor:    return "cross.fill"
        }
    }

    private func secondaryAction(proxy: ScrollViewProxy) {
        switch engine.currentTier {
        case .call911:
            showFirstAid = true
        case .goToER:
            if let url = URL(string: "tel://911") { UIApplication.shared.open(url) }
        case .urgentCare:
            if let url = URL(string: "maps://?q=Emergency+Room") { UIApplication.shared.open(url) }
        case .monitor:
            if let url = URL(string: "maps://?q=Urgent+Care") { UIApplication.shared.open(url) }
        }
    }

    // MARK: - Persistent 911 Button


    // MARK: - First Aid Steps

    private var firstAidSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("What to do right now")
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(content.firstAidSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(tierColor)
                            .clipShape(Circle())
                        Text(step)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Button(action: { showFirstAid = true }) {
                Label("View Full First Aid Instructions", systemImage: "cross.case.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(tierColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(tierColor, lineWidth: 1.5)
                    )
            }
        }
        .sheet(isPresented: $showFirstAid) {
            FirstAidView(
                emergencyType: FirstAidEmergencyType.resolve(from: engine.session),
                session: engine.session
            )
            .environmentObject(wakeVM)
        }
    }

    // MARK: - What to Bring

    @ViewBuilder
    private var whatToBringSection: some View {
        if !content.whatToBring.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("What to bring")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(content.whatToBring, id: \.self) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(tierColor)
                                .font(.caption)
                                .padding(.top, 3)
                            Text(item)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    // MARK: - What to Expect

    private var whatToExpectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("What to expect")
            Text(content.whatToExpect)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
        }
    }

    // MARK: - Reassessment Timer

    private func reassessmentSection(minutes: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Check-in timer")
            HStack(spacing: 10) {
                Image(systemName: timer.isRunning ? "timer" : "timer.circle")
                    .foregroundColor(tierColor)
                if timer.isRunning {
                    Text("Check-in in \(timer.formattedTimeRemaining)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                } else {
                    let label = minutes >= 60
                        ? "\(minutes / 60) hour\(minutes / 60 > 1 ? "s" : "")"
                        : "\(minutes) minutes"
                    Text("Starting \(label) check-in")
                        .fontWeight(.semibold)
                }
                Spacer()
                Text("Seek care sooner if symptoms change")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .background(tierColor.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // MARK: - Restart

    private var restartButton: some View {
        Button(action: sessionManager.resetSession) {
            Text("Start Over")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.12))
                .cornerRadius(12)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Switch Profile Modifiers

    var switchProfileModifiers: some View {
        EmptyView()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSwitchConfirm = true
                    } label: {
                        Label("Switch Profile", systemImage: "person.2")
                            .font(.subheadline)
                    }
                }
            }
            .confirmationDialog(
                "Switch Profile?",
                isPresented: $showSwitchConfirm,
                titleVisibility: .visible
            ) {
                Button("Switch Profile") { showProfileSwitcher = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will start a new triage session for another profile.")
            }
            .sheet(isPresented: $showProfileSwitcher) {
                NavigationStack {
                    ProfileSwitcherView()
                        .navigationTitle("Switch Profile")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showProfileSwitcher = false }
                            }
                        }
                        .onChange(of: appState.sessionStartCount) { _ in
                            showProfileSwitcher = false
                        }
                }
            }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
}
