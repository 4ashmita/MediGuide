import SwiftUI

struct QuestionView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var engine: TriageEngine
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authState: AuthStateManager

    @State private var showSwitchConfirm = false
    @State private var showProfileSwitcher = false
    @State private var selectedOptionText: String? = nil
    @State private var showSettingsDuringTriage = false
    @State private var showTriageSettingsWarning = false

    @EnvironmentObject private var progressVM: TriageProgressViewModel

    var body: some View {
        if let node = navigationManager.currentNode {
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(node.question)
                            .font(.title3.weight(.semibold))
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityLabel("\(progressVM.state.questionLabel): \(node.question)")

                        VStack(spacing: 10) {
                            ForEach(node.options, id: \.text) { option in
                                answerButton(for: option)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
                .id(node.id)
                .animation(.easeInOut(duration: 0.15), value: node.id)

                Divider()
                EscalationButton()
                    .padding(.horizontal)
                    .padding(.vertical, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showTriageSettingsWarning = true } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 15))
                        }
                        .accessibilityLabel("Settings")
                        Button { showSwitchConfirm = true } label: {
                            Image(systemName: "person.2")
                        }
                        .accessibilityLabel("Switch profile")
                    }
                }
            }
            .onChange(of: navigationManager.currentNode?.id) { _, _ in
                selectedOptionText = nil
            }
            .confirmationDialog(
                "Switch Profile?",
                isPresented: $showSwitchConfirm,
                titleVisibility: .visible
            ) {
                Button("Switch Profile") { showProfileSwitcher = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your current triage progress will be lost.")
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
                        .onChange(of: appState.sessionStartCount) { _, _ in
                            showProfileSwitcher = false
                        }
                }
            }
            .confirmationDialog(
                "Leaving triage will pause your session.",
                isPresented: $showTriageSettingsWarning,
                titleVisibility: .visible
            ) {
                Button("Open Settings") { showSettingsDuringTriage = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showSettingsDuringTriage) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(authState)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            profileBanner
            HStack(spacing: 12) {
                if navigationManager.canGoBack {
                    Button {
                        selectedOptionText = nil
                        navigationManager.goBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Back to previous question")
                }
                progressRow
                Spacer()
                EmergencyButtonView(context: .activeTriage)
            }
        }
    }

    private var profileBanner: some View {
        Button { showProfileSwitcher = true } label: {
            HStack(spacing: 10) {
                Image(systemName: engine.session.profileUsed
                      ? "person.circle.fill"
                      : "person.fill.questionmark")
                    .foregroundStyle(.red)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Triaging for: \(bannerTitle)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !bannerConditions.isEmpty {
                        Text(bannerConditions.joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Triaging for \(bannerTitle). Tap to switch profile.")
    }

    private var progressRow: some View {
        TriageProgressView(vm: progressVM)
    }

    // MARK: - Answer Button

    private func answerButton(for option: NodeOption) -> some View {
        let isSelected = selectedOptionText == option.text
        return Button {
            selectedOptionText = option.text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                navigationManager.advance(via: option)
            }
        } label: {
            HStack(spacing: 12) {
                Text(option.text)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.red : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.text)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }

    // MARK: - Banner Helpers

    private var bannerTitle: String {
        let group = engine.session.ageGroup
        if engine.session.profileUsed, !engine.session.sessionDisplayName.isEmpty {
            let ageLabel = engine.session.sessionAge.map { "\($0) years old · \(group.displayLabel)" }
                ?? group.displayLabel
            return "\(engine.session.sessionDisplayName) · \(ageLabel)"
        }
        return group.displayLabel
    }

    private var bannerConditions: [String] {
        var seen = Set<String>()
        return engine.session.modifiers.compactMap { modifier in
            guard let name = ConditionList.all.first(where: { $0.modifierId == modifier.modifierId })?.displayName,
                  seen.insert(name).inserted
            else { return nil }
            return name
        }
    }
}
