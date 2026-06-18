import SwiftUI

struct ProfileListView: View {
    @StateObject private var vm = ProfileListViewModel()
    @EnvironmentObject var appState: AppState
    @State private var editingProfileId: UUID? = nil

    var body: some View {
        NavigationStack {
            Group {
                if vm.profiles.isEmpty {
                    emptyState
                } else {
                    profileList
                }
            }
            .navigationTitle("My Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { appState.activeScreen = .welcome }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(item: $editingProfileId) { id in
                ProfileEditView(profileId: id)
                    .onDisappear { vm.load() }
            }
            .sheet(item: $vm.deleteTarget) { summary in
                DeletionConfirmationView(mode: .individual(summary))
                    .onDisappear { vm.load() }
            }
        }
        .onAppear { vm.load() }
    }

    // MARK: - Profile List

    private var profileList: some View {
        List {
            ForEach(vm.profiles) { summary in
                ProfileCard(
                    summary: summary,
                    isStale: vm.isStale(summary),
                    context: .management,
                    onEdit: { editingProfileId = summary.id },
                    onDelete: { vm.confirmDelete(summary) }
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove { vm.move(from: $0, to: $1) }

            if vm.profileLimitReached {
                Text("Profile limit reached (\(ProfileRepository.maxProfiles) max). Delete a profile to add another.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Profiles Yet")
                .font(.title2.bold())
            Text("Create a profile for yourself or a family member. Conditions and emergency contact load automatically at triage start.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Create First Profile") {
                appState.activeScreen = .profileCreation
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Group {
            if vm.profileLimitReached {
                Button("Add Profile") {}
                    .disabled(true)
            } else {
                Button("Add Profile") {
                    appState.activeScreen = .profileCreation
                }
            }
        }
    }

}

// UUID conformance to Identifiable for sheet binding
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
