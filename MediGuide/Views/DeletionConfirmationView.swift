import SwiftUI

struct DeletionConfirmationView: View {
    @StateObject private var vm: DeletionConfirmationViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let mode: DeletionMode

    init(mode: DeletionMode) {
        self.mode = mode
        _vm = StateObject(wrappedValue: DeletionConfirmationViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .individual(let summary):
                    individualView(summary: summary)
                case .fullWipe:
                    vm.wipeStage == 1 ? AnyView(wipeStage1View) : AnyView(wipeStage2View)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(vm.isAuthenticating)
                }
            }
        }
        .onAppear { vm.load() }
        .onChange(of: vm.isComplete) { _, complete in
            if complete { handleCompletion() }
        }
    }

    // MARK: - Individual Deletion

    private func individualView(summary: ProfileSummary) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 52))
                        .foregroundStyle(.red)
                    Text("Delete \(summary.displayName)'s Profile?")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                if let profile = vm.loadedProfile {
                    dataSummaryCard(profile: profile, name: summary.displayName)
                }

                warningBox(text: "This cannot be undone. All of \(summary.displayName)'s health information will be permanently removed from this device.")

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                deleteButton(label: "Delete Profile")
            }
            .padding()
        }
        .navigationTitle("Delete Profile")
    }

    // MARK: - Full Wipe Stage 1

    private var wipeStage1View: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.red)
                    Text("Clear All Health Data?")
                        .font(.title2.bold())
                    Text("\(vm.allSummaries.count) profile\(vm.allSummaries.count == 1 ? "" : "s") will be deleted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    ForEach(vm.allSummaries) { summary in
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(summary.displayName).font(.headline)
                                Text("\(summary.age) yrs · \(summary.ageGroup.rawValue.capitalized)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }

                warningBox(text: "This will permanently remove all health information from this device. This cannot be undone.")

                Button(action: { vm.proceedToStage2() }) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .navigationTitle("Clear All Health Data")
    }

    // MARK: - Full Wipe Stage 2

    private var wipeStage2View: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.red)
                    Text("Are You Absolutely Sure?")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                warningBox(text: "All health profiles, medications, allergies, and emergency contacts will be permanently deleted. The app will return to its initial state.")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type DELETE to confirm")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("", text: $vm.typeToConfirm)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .font(.title3.bold())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(vm.typeToConfirm == "DELETE" ? Color.green : Color.red.opacity(0.4),
                                        lineWidth: 1.5)
                        )
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                deleteButton(label: "Delete All Data")
            }
            .padding()
        }
        .navigationTitle("Final Confirmation")
    }

    // MARK: - Shared subviews

    private func deleteButton(label: String) -> some View {
        Button(action: { vm.executeDelete() }) {
            Group {
                if vm.isAuthenticating {
                    ProgressView().tint(.white)
                } else {
                    Text(label).fontWeight(.bold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(vm.isDeleteEnabled ? Color.red : Color.gray)
            .cornerRadius(14)
        }
        .disabled(!vm.isDeleteEnabled || vm.isAuthenticating)
    }

    private func dataSummaryCard(profile: UserProfile, name: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What will be deleted:")
                .font(.subheadline.bold())
            summaryRow(icon: "person.fill",
                       label: "\(name), \(profile.ageGroup.rawValue.capitalized)")
            summaryRow(icon: "heart.text.square",
                       label: conditionText(profile))
            summaryRow(icon: "pills.fill",
                       label: medicationText(profile))
            summaryRow(icon: "cross.case.fill",
                       label: allergyText(profile))
            summaryRow(icon: "phone.fill",
                       label: emergencyText(profile))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func summaryRow(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label).font(.subheadline)
        }
    }

    private func warningBox(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text).font(.subheadline)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func conditionText(_ p: UserProfile) -> String {
        p.conditions.isEmpty ? "No conditions" : "\(p.conditions.count) condition\(p.conditions.count == 1 ? "" : "s")"
    }

    private func medicationText(_ p: UserProfile) -> String {
        p.medications.isEmpty ? "No medications" : "\(p.medications.count) medication\(p.medications.count == 1 ? "" : "s")"
    }

    private func allergyText(_ p: UserProfile) -> String {
        let n = p.allergies.count
        return n == 0 ? "No allergies" : "\(n) allerg\(n == 1 ? "y" : "ies")"
    }

    private func emergencyText(_ p: UserProfile) -> String {
        p.emergencyContactName.isEmpty
            ? "No emergency contact"
            : "Emergency contact: \(p.emergencyContactName)"
    }

    // MARK: - Completion

    private func handleCompletion() {
        switch mode {
        case .individual(let summary):
            if appState.activeProfileId == summary.id {
                NotificationManager.cancelCheckIn()
            }
            dismiss()
        case .fullWipe:
            sessionManager.endSession()
            appState.showPostSessionContext = false  // full wipe is not a normal session end
            appState.activeScreen = .profileCreation
        }
    }
}
