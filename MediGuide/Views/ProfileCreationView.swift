import SwiftUI

struct ProfileCreationView: View {
    @StateObject private var vm = ProfileCreationViewModel()
    @EnvironmentObject var appState: AppState
    var onComplete: () -> Void
    var onSkip: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    stepContent
                    if let error = vm.validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }

            navigationButtons
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Create Profile")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            if let skip = onSkip {
                Button("Skip for now", action: skip)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Progress

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: vm.progress)
                .tint(.red)
            Text("Step \(vm.currentStep) of \(ProfileCreationViewModel.totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch vm.currentStep {
        case 1: step1
        case 2: step2
        case 3: step3
        case 4: step4
        case 5: step5
        case 6: step6
        case 7: step7Review
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Who

    private var step1: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepTitle("Who is this profile for?")
            VStack(spacing: 12) {
                selectionButton(label: "Myself", selected: vm.isForSelf) {
                    vm.isForSelf = true
                }
                selectionButton(label: "A family member", selected: !vm.isForSelf) {
                    vm.isForSelf = false
                }
            }
            if !vm.isForSelf {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Their first name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g. Mom, Jake", text: $vm.familyMemberName)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Step 2: Basic Info

    private var step2: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepTitle("Basic Information")
            VStack(alignment: .leading, spacing: 6) {
                Text("Date of birth")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                DatePicker("", selection: $vm.dateOfBirth, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Biological sex")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $vm.biologicalSex) {
                    ForEach(BiologicalSex.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Blood type (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Blood type", selection: $vm.bloodType) {
                    ForEach(BloodType.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Step 3: Conditions

    private static let nonPregnancyConditions: [ConditionEntry] = ConditionList.all.filter {
        !["pregnant_t1", "pregnant_t2", "pregnant_t3", "postpartum", "pregnant_unknown"].contains($0.conditionId)
    }

    private static let trimesterOptions: [(String, String)] = [
        ("pregnant_t1", "First trimester (weeks 1–12)"),
        ("pregnant_t2", "Second trimester (weeks 13–26)"),
        ("pregnant_t3", "Third trimester (weeks 27–40)"),
        ("postpartum", "Postpartum (within 6 weeks of delivery)"),
        ("pregnant_unknown", "I'm not sure / prefer not to say")
    ]

    private var step3: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Pre-existing Conditions")
            Text("Tap to select all that apply. These load automatically during triage.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(Self.nonPregnancyConditions, id: \.conditionId) { entry in
                Toggle(entry.displayName, isOn: Binding(
                    get: { vm.selectedConditions.contains(entry.conditionId) },
                    set: { on in
                        if on { vm.selectedConditions.insert(entry.conditionId) }
                        else { vm.selectedConditions.remove(entry.conditionId) }
                    }
                ))
            }

            // Pregnancy — only shown for female
            if vm.biologicalSex == .female {
                VStack(alignment: .leading, spacing: 0) {
                    Toggle("Pregnancy", isOn: Binding(
                        get: { vm.isPregnantToggleOn },
                        set: { vm.setPregnantToggle($0) }
                    ))

                    if vm.isPregnantToggleOn {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Which stage?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)

                            ForEach(Self.trimesterOptions, id: \.0) { id, label in
                                Button(action: { vm.selectTrimester(id) }) {
                                    HStack {
                                        Text(label)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if vm.selectedTrimesterId == id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(vm.selectedTrimesterId == id
                                        ? Color.red.opacity(0.08)
                                        : Color.gray.opacity(0.06))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: vm.isPregnantToggleOn)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Other condition (optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Describe any other condition", text: $vm.conditionOtherNote)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Step 4: Medications

    private var step4: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Medications")
            Text("Names only — no dosage needed. This list can be shared with emergency responders.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                TextField("Add medication", text: $vm.newMedication)
                    .textFieldStyle(.roundedBorder)
                Button(action: vm.addMedication) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .disabled(vm.newMedication.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !vm.medications.isEmpty {
                ForEach(vm.medications, id: \.self) { med in
                    HStack {
                        Text(med)
                        Spacer()
                        Button {
                            vm.medications.removeAll { $0 == med }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
    }

    // MARK: - Step 5: Allergies

    private var step5: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle("Known Allergies")
            Text("Particularly important for medication allergies.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                TextField("Add allergy", text: $vm.newAllergy)
                    .textFieldStyle(.roundedBorder)
                Button(action: vm.addAllergy) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .disabled(vm.newAllergy.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !vm.allergies.isEmpty {
                ForEach(vm.allergies, id: \.self) { allergy in
                    HStack {
                        Text(allergy)
                        Spacer()
                        Button {
                            vm.allergies.removeAll { $0 == allergy }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
    }

    // MARK: - Step 6: Emergency Contact

    private var step6: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepTitle("Emergency Contact")
            Text("This person receives an automatic SMS with your location and medical info when 911 is called.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("First name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Contact name", text: $vm.emergencyContactName)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Phone number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Phone number", text: $vm.emergencyContactPhone)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
            }
        }
    }

    // MARK: - Step 7: Review

    private var step7Review: some View {
        let profile = vm.buildDraftProfile()
        return VStack(alignment: .leading, spacing: 20) {
            stepTitle("Review Your Profile")
            Text("Tap any section to edit before saving.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            reviewRow(title: "Name", value: profile.displayName, step: 1)
            reviewRow(title: "Date of Birth", value: formattedDate(profile.dateOfBirth), step: 2)
            reviewRow(title: "Biological Sex", value: profile.biologicalSex.rawValue, step: 2)
            reviewRow(title: "Blood Type", value: profile.bloodType.rawValue, step: 2)
            reviewRow(title: "Conditions",
                value: conditionsDisplayValue(profile.conditions),
                step: 3)
            reviewRow(title: "Medications",
                value: profile.medications.isEmpty ? "None" : profile.medications.joined(separator: ", "),
                step: 4)
            reviewRow(title: "Allergies",
                value: profile.allergies.isEmpty ? "None" : profile.allergies.joined(separator: ", "),
                step: 5)
            reviewRow(title: "Emergency Contact",
                value: profile.emergencyContactName.isEmpty ? "Not set" : "\(profile.emergencyContactName) · \(profile.emergencyContactPhone)",
                step: 6)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: 10) {
            Divider()
            HStack(spacing: 12) {
                if vm.currentStep > 1 {
                    Button(action: vm.goBack) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.12))
                            .cornerRadius(12)
                            .foregroundColor(.primary)
                    }
                }

                if vm.isLastStep {
                    Button(action: {
                        if vm.save() { onComplete() }
                    }) {
                        Text("Save Profile")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(vm.isNextEnabled ? Color.red : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .disabled(!vm.isNextEnabled)
                } else {
                    Button(action: vm.goNext) {
                        Text("Next")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(vm.isNextEnabled ? Color.red : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .disabled(!vm.isNextEnabled)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Helpers

    private func stepTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
    }

    private func selectionButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .fontWeight(selected ? .semibold : .regular)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(selected ? Color.red.opacity(0.08) : Color.gray.opacity(0.08))
            .cornerRadius(12)
            .foregroundColor(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.red : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private func reviewRow(title: String, value: String, step: Int) -> some View {
        Button(action: { vm.jumpToStep(step) }) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Spacer()
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.06))
            .cornerRadius(10)
        }
    }

    private func conditionsDisplayValue(_ conditions: [String]) -> String {
        if conditions.isEmpty { return "None" }
        return conditions.compactMap { ConditionList.entry(for: $0)?.displayName }.joined(separator: ", ")
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: date)
    }
}
