import SwiftUI

struct ProfileSelectionView: View {
    @StateObject private var vm = ProfileSelectionViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let error = vm.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    if vm.hasProfiles {
                        savedProfilesSection
                    } else {
                        emptyProfilesSection
                    }

                    helpSomeoneElseSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Who needs help?")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { appState.activeScreen = .welcome }
                }
            }
            .sheet(isPresented: $vm.showManualEntry) {
                ManualEntryView(vm: vm)
            }
        }
        .onAppear { vm.load() }
    }

    // MARK: - Saved Profiles

    private var savedProfilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Profiles")
                .font(.headline)
                .padding(.horizontal)

            ForEach(vm.profiles) { summary in
                ProfileCardView(
                    summary: summary,
                    isStale: vm.isStale(summary),
                    onTap: { vm.selectProfile(id: summary.id, sessionManager: sessionManager) }
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty State

    private var emptyProfilesSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text("No saved profiles")
                .font(.headline)
            Text("Create a profile for faster triage — your conditions and emergency contact will load automatically.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { appState.activeScreen = .profileCreation }) {
                Text("Create a Profile")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Help Someone Else

    private var helpSomeoneElseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if vm.hasProfiles { Divider().padding(.horizontal) }
            Button(action: { vm.showManualEntry = true }) {
                HStack(spacing: 16) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 44)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Someone Not in My Profiles")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Enter basic info for this session only — nothing will be saved.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.top, vm.hasProfiles ? 12 : 0)
            }
        }
    }
}

// MARK: - Profile Card

private struct ProfileCardView: View {
    let summary: ProfileSummary
    let isStale: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Text(summary.displayName.prefix(1).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(summary.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if isStale {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    Text("\(summary.age) yrs · \(summary.ageGroup.rawValue.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if !summary.conditionsSummary.isEmpty {
                        Text(summary.conditionsSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    if isStale {
                        Text("Profile may be outdated — consider updating after this session")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Manual Entry Sheet

struct ManualEntryView: View {
    @ObservedObject var vm: ProfileSelectionViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ageGroupSection
                    conditionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Basic Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Triage") {
                        dismiss()
                        vm.startManualSession(sessionManager: sessionManager)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Age Group

    private var ageGroupSection: some View {
        manualSection(title: "Age Group") {
            HStack(spacing: 10) {
                ForEach([AgeGroup.infant, .child, .adult, .elderly], id: \.self) { group in
                    Button(action: { vm.manualAgeGroup = group }) {
                        VStack(spacing: 6) {
                            Image(systemName: group.selectionIcon)
                                .font(.title2)
                            Text(group.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(vm.manualAgeGroup == group ? Color.red.opacity(0.1) : Color(.systemGray6))
                        .foregroundColor(vm.manualAgeGroup == group ? .red : .primary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(vm.manualAgeGroup == group ? Color.red : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Conditions

    private var conditionsSection: some View {
        manualSection(title: "Known Conditions") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Optional — skip if unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ConditionToggleView(vm: vm.manualConditionToggleVM)
            }
        }
    }

    private func manualSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .padding(.horizontal)
            content()
                .padding(.horizontal)
            Divider().padding(.top, 4)
        }
    }
}
