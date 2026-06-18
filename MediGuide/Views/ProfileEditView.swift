import SwiftUI

struct ProfileEditView: View {
    @StateObject private var vm: ProfileEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardAlert = false
    @State private var showDeleteConfirmation = false

    init(profileId: UUID) {
        _vm = StateObject(wrappedValue: ProfileEditViewModel(profileId: profileId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if let error = vm.validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    displayNameSection
                    basicInfoSection
                    conditionsSection
                    medicationsSection
                    allergiesSection
                    emergencyContactSection
                    deleteProfileSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if vm.hasChanges { showDiscardAlert = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        EmergencyButtonView(context: .profileEditing)
                        Button("Save") {
                            if vm.save() { dismiss() }
                        }
                        .fontWeight(.semibold)
                        .disabled(!vm.canSave)
                    }
                }
            }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    vm.discardChanges()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your unsaved changes will be lost.")
            }
        }
    }

    // MARK: - Display Name

    private var displayNameSection: some View {
        editSection(title: "Profile Name") {
            VStack(alignment: .leading, spacing: 6) {
                TextField("Name", text: $vm.displayName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: vm.displayName) { _, _ in vm.trackField("displayName") }
                ValidationErrorView(failures: vm.failuresFor(.displayName))
            }
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        editSection(title: "Basic Information") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Date of birth")
                        .font(.subheadline).foregroundColor(.secondary)
                    DatePicker("", selection: $vm.dateOfBirth, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: vm.dateOfBirth) { _, _ in vm.trackField("dateOfBirth") }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Biological sex")
                        .font(.subheadline).foregroundColor(.secondary)
                    Picker("", selection: $vm.biologicalSex) {
                        ForEach(BiologicalSex.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vm.biologicalSex) { _, _ in vm.trackField("biologicalSex") }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Blood type")
                        .font(.subheadline).foregroundColor(.secondary)
                    BloodTypeView(selection: $vm.bloodType)
                        .onChange(of: vm.bloodType) { _, _ in vm.trackField("bloodType") }
                }
            }
        }
    }

    // MARK: - Conditions

    private var conditionsSection: some View {
        editSection(title: "Pre-existing Conditions") {
            ConditionToggleView(vm: vm.conditionToggleVM)
        }
    }

    // MARK: - Medications

    private var medicationsSection: some View {
        editSection(title: "Medications") {
            NavigationStack {
                MedicationListView(vm: vm.medicationListVM)
            }
            .frame(minHeight: 200)
        }
    }

    // MARK: - Allergies

    private var allergiesSection: some View {
        editSection(title: "Known Allergies") {
            NavigationStack {
                AllergyListView(vm: vm.allergyListVM)
            }
            .frame(minHeight: 220)
        }
    }

    // MARK: - Emergency Contact

    private var emergencyContactSection: some View {
        editSection(title: "Emergency Contact") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("First name").font(.subheadline).foregroundColor(.secondary)
                    TextField("Contact name", text: $vm.emergencyContactName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: vm.emergencyContactName) { _, _ in vm.trackField("emergencyContactName") }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Phone number").font(.subheadline).foregroundColor(.secondary)
                    TextField("Phone number", text: $vm.emergencyContactPhone)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                        .onChange(of: vm.emergencyContactPhone) { _, _ in vm.trackField("emergencyContactPhone") }
                    ValidationErrorView(failures: vm.failuresFor(.emergencyContactPhone))
                }
                ValidationErrorView(failures: vm.emergencyContactWarnings)
            }
        }
    }

    // MARK: - Delete Profile

    private var deleteProfileSection: some View {
        VStack(spacing: 0) {
            Divider().padding(.top, 8)
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("Delete Profile")
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            if let summary = ProfileRepository.summaries().first(where: { $0.id == vm.profileId }) {
                DeletionConfirmationView(mode: .individual(summary))
                    .onDisappear {
                        // Dismiss edit view if the profile was deleted
                        if ProfileRepository.summaries().first(where: { $0.id == vm.profileId }) == nil {
                            dismiss()
                        }
                    }
            }
        }
    }

    // MARK: - Section wrapper

    private func editSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
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
