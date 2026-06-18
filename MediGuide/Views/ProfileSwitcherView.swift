import SwiftUI

struct ProfileSwitcherView: View {
    @StateObject private var vm = ProfileSwitcherViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            if vm.profiles.isEmpty {
                emptyState
            } else if vm.profiles.count <= 3 {
                horizontalSection
            } else {
                verticalSection
            }

            Divider()
            helpSomeoneElseRow
        }
        .onAppear { vm.load() }
        .sheet(isPresented: $vm.showManualEntry) {
            ManualEntryFlowView()
                .environmentObject(sessionManager)
        }
    }

    // MARK: - Horizontal Layout (≤3 profiles)

    private var horizontalSection: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.profiles) { summary in
                        ProfileCard(
                            summary: summary,
                            isStale: vm.isStale(summary),
                            context: .triage,
                            isPreHighlighted: summary.id == vm.preHighlightedId,
                            onTap: { vm.tap(id: summary.id) }
                        )
                        .frame(width: 268)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            if let selected = vm.selectedSummary {
                confirmationPanel(for: selected)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let error = vm.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: vm.selectedId)
    }

    // MARK: - Vertical Layout (≥4 profiles)

    private var verticalSection: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(vm.profiles) { summary in
                    VStack(spacing: 8) {
                        ProfileCard(
                            summary: summary,
                            isStale: vm.isStale(summary),
                            context: .triage,
                            isPreHighlighted: summary.id == vm.preHighlightedId,
                            onTap: { vm.tap(id: summary.id) }
                        )

                        if vm.selectedId == summary.id {
                            confirmationPanel(for: summary)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.22), value: vm.selectedId)
                    .padding(.horizontal)
                }

                if let error = vm.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Confirmation Panel

    private func confirmationPanel(for summary: ProfileSummary) -> some View {
        VStack(spacing: 10) {
            Text("Load profile for \(summary.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { vm.confirmTriage(sessionManager: sessionManager) }) {
                Text("Start Triage for \(summary.displayName)")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Help Someone Else

    private var helpSomeoneElseRow: some View {
        Button(action: { vm.showManualEntry = true }) {
            HStack(spacing: 16) {
                Image(systemName: "person.fill.questionmark")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Someone Not in My Profiles")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Enter basic info for this session only — nothing will be saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Set up a profile for faster triage next time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { appState.activeScreen = .profileCreation }) {
                Text("Create a Profile")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
