import SwiftUI

struct ProfileManagementView: View {
    @StateObject private var vm = ProfileManagementViewModel()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var authState: AuthStateManager
    @State private var isEditMode: Bool = false
    @State private var showTriageConfirm: Bool = false
    @State private var triageTargetId: UUID? = nil

    var onDone: (() -> Void)? = nil

    var body: some View {
        Group {
            if vm.loadedProfiles.isEmpty {
                emptyState
            } else {
                profileList
            }
        }
        .navigationTitle("Health Profiles")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $vm.isAddingProfile, onDismiss: vm.finishAddingProfile) {
            ProfileCreationView(
                onComplete: { vm.isAddingProfile = false },
                onSkip:     { vm.isAddingProfile = false }
            )
        }
        .sheet(item: $vm.editingProfileId, onDismiss: vm.load) { id in
            ProfileEditView(profileId: id)
        }
        .sheet(item: $vm.deleteTarget, onDismiss: vm.load) { summary in
            DeletionConfirmationView(mode: .individual(summary))
        }
        .sheet(item: $vm.reviewingProfile, onDismiss: vm.load) { profile in
            reviewSheet(for: profile)
        }
        .confirmationDialog(
            "Start triage for \(profileName(triageTargetId))?",
            isPresented: $showTriageConfirm,
            titleVisibility: .visible
        ) {
            Button("Start Triage") { confirmStartTriage() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will begin a new triage session.")
        }
        .onAppear { vm.load() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if let onDone {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done", action: onDone)
            }
        }

        if !vm.loadedProfiles.isEmpty {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(isEditMode ? "Done" : "Edit") {
                    withAnimation { isEditMode.toggle() }
                }
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { vm.isAddingProfile = true }) {
                Image(systemName: "plus")
            }
            .disabled(vm.profileLimitReached)
        }
    }

    // MARK: - Profile List

    private var profileList: some View {
        ScrollView {
            VStack(spacing: 0) {
                countSummary
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                LazyVStack(spacing: 12) {
                    ForEach(vm.loadedProfiles) { item in
                        ProfileSummaryCard(
                            profile: item.profile,
                            report: item.report,
                            onEdit:        { vm.editingProfileId = item.profile.id },
                            onDelete:      { vm.confirmDelete(item.profile.id) },
                            onStartTriage: { requestTriage(for: item.profile.id) },
                            onReview:      { vm.reviewingProfile = item.profile }
                        )
                        .padding(.horizontal, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                                .padding(.horizontal, 16)
                                .opacity(vm.highlightedProfileId == item.profile.id ? 1 : 0)
                        )
                        .overlay(alignment: .topLeading) {
                            if isEditMode {
                                editOverlay(for: item)
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.loadedProfiles.map { $0.id })
    }

    private var countSummary: some View {
        let count = vm.loadedProfiles.count
        let max = ProfileRepository.maxProfiles
        let text: String
        if vm.profileLimitReached {
            text = "\(count) of \(max) profiles — maximum reached. Delete a profile to add a new one."
        } else if count > max - 3 {
            text = "\(count) of \(max) profiles saved"
        } else {
            text = "\(count) profile\(count == 1 ? "" : "s") saved"
        }
        return Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func editOverlay(for item: ProfileManagementViewModel.LoadedProfile) -> some View {
        HStack {
            Button(action: { vm.confirmDelete(item.profile.id) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .padding(8)
            }
            .buttonStyle(.plain)
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .padding(8)
        }
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .transition(.opacity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Profiles Saved")
                .font(.title2.bold())
            Text("Add a health profile to get faster, more accurate triage recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Profile") { vm.isAddingProfile = true }
                .buttonStyle(.borderedProminent)
            Text("You can also use guided triage without a profile.")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Review Sheet

    @ViewBuilder
    private func reviewSheet(for profile: UserProfile) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("\(profile.displayName)'s profile was last updated \(daysSince(profile.dateModified)) ago")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 10) {
                    reviewItem("Check if any new conditions have been diagnosed")
                    reviewItem("Verify the medication list is current")
                    reviewItem("Confirm allergy information is still accurate")
                    reviewItem("Make sure the emergency contact is still correct")
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        vm.reviewingProfile = nil
                        vm.editingProfileId = profile.id
                    }) {
                        Text("Update Profile")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(14)
                    }

                    VStack(spacing: 4) {
                        Button(action: {
                            vm.reviewingProfile = nil
                            vm.markReviewed(profile)
                        }) {
                            Text("Looks good — mark as reviewed")
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.12))
                                .cornerRadius(14)
                        }
                        Text("Updates the review date. Any missing information will still need to be filled in.")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Review Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.reviewingProfile = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func reviewItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top, 3)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Triage start

    private func requestTriage(for profileId: UUID) {
        triageTargetId = profileId
        showTriageConfirm = true
    }

    private func confirmStartTriage() {
        guard let id = triageTargetId else { return }
        triageTargetId = nil
        let started = sessionManager.startSession(withProfileId: id)
        if started { appState.activeScreen = .triage }
    }

    private func profileName(_ id: UUID?) -> String {
        vm.loadedProfiles.first { $0.id == id }?.profile.displayName ?? ""
    }

    private func daysSince(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 30 { return "\(days) days" }
        let months = days / 30
        return "\(months) month\(months == 1 ? "" : "s")"
    }
}
