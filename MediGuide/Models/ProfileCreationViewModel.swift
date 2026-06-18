import Foundation
import Combine
import SwiftUI

final class ProfileCreationViewModel: ObservableObject {

    static let totalSteps = 7

    // MARK: - Step tracking

    @Published private(set) var currentStep: Int = 1
    @Published private(set) var validationError: String? = nil

    // MARK: - Step 1: Who

    @Published var isForSelf: Bool
    @Published var familyMemberName: String = ""
    @Published var relationship: ProfileRelationship? = nil

    // MARK: - Step 2: Basic info

    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @Published var biologicalSex: BiologicalSex = .preferNotToSay
    @Published var bloodType: BloodType = .unknown

    // MARK: - Step 3: Conditions

    let conditionToggleVM = ConditionToggleViewModel()

    // MARK: - Step 4: Medications

    let medicationListVM = MedicationListViewModel()

    // MARK: - Step 5: Allergies

    let allergyListVM = AllergyListViewModel()

    // MARK: - Step 6: Emergency contact

    @Published var emergencyContactName: String = ""
    @Published var emergencyContactPhone: String = ""

    // MARK: - Validation

    @Published private(set) var validationFailures: [ValidationFailure] = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(isAddingFamilyMember: Bool = false) {
        self.isForSelf = !isAddingFamilyMember
        setupValidationObservers()
    }

    // MARK: - Navigation

    var isNextEnabled: Bool {
        let profile = buildDraftProfile()
        guard ProfileValidator.isStepValid(step: currentStep, profile: profile) else { return false }
        if currentStep == 3 {
            return ProfileValidator.validateTrimester(
                pregnancyOn: conditionToggleVM.isPregnantToggleOn,
                trimestedId: conditionToggleVM.selectedTrimesterId
            ) == nil
        }
        return true
    }

    var isLastStep: Bool { currentStep == Self.totalSteps }
    var progress: Double { Double(currentStep) / Double(Self.totalSteps) }

    func goNext() {
        guard currentStep < Self.totalSteps else { return }
        let profile = buildDraftProfile()
        var stepFailures = ProfileValidator.validate(step: currentStep, profile: profile).failures
        if currentStep == 3, let tf = ProfileValidator.validateTrimester(
            pregnancyOn: conditionToggleVM.isPregnantToggleOn,
            trimestedId: conditionToggleVM.selectedTrimesterId
        ) {
            stepFailures.append(tf)
        }
        if stepFailures.contains(where: { $0.severity == .error }) {
            validationFailures = stepFailures
            return
        }
        validationFailures = []
        validationError = nil
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 1 else { return }
        validationFailures = []
        validationError = nil
        currentStep -= 1
    }

    func jumpToStep(_ step: Int) {
        guard step >= 1, step <= Self.totalSteps else { return }
        validationFailures = []
        currentStep = step
    }

    // MARK: - Validation Helpers

    func failuresFor(_ field: ValidationField) -> [ValidationFailure] {
        validationFailures.filter { $0.field == field }
    }

    var epiPenWarnings: [ValidationFailure] {
        let profile = buildDraftProfile()
        return ProfileValidator.validate(profile: profile).failures.filter {
            if case .allergyEpiPen = $0.field { return true }
            return false
        }
    }

    var emergencyContactWarnings: [ValidationFailure] {
        failuresFor(.emergencyContact)
    }

    // MARK: - Save

    @discardableResult
    func save() -> Bool {
        let profile = buildDraftProfile()
        var allFailures = ProfileValidator.validate(profile: profile).failures
        if let tf = ProfileValidator.validateTrimester(
            pregnancyOn: conditionToggleVM.isPregnantToggleOn,
            trimestedId: conditionToggleVM.selectedTrimesterId
        ) {
            allFailures.append(tf)
        }
        let errors = allFailures.filter { $0.severity == .error }
        if !errors.isEmpty {
            validationFailures = allFailures
            validationError = errors.first?.message
            return false
        }
        do {
            try ProfileStore.save(profile)
            return true
        } catch {
            validationError = "Failed to save profile. Please try again."
            return false
        }
    }

    // MARK: - Draft

    func buildDraftProfile() -> UserProfile {
        let name = isForSelf ? "Me" : familyMemberName.trimmingCharacters(in: .whitespaces)
        var profile = UserProfile(
            displayName: name.isEmpty ? "Me" : name,
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex
        )
        profile.bloodType = bloodType
        profile.conditions = conditionToggleVM.exportConditionIds()
        profile.conditionOtherNote = conditionToggleVM.otherNote
        profile.medications = medicationListVM.entries
        profile.allergies = allergyListVM.entries
        profile.relationship = isForSelf ? nil : relationship
        profile.emergencyContactName = emergencyContactName
        profile.emergencyContactPhone = emergencyContactPhone
        return profile
    }

    // MARK: - Private

    private func setupValidationObservers() {
        // Forward nested object changes so views re-render on condition/allergy edits
        conditionToggleVM.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        allergyListVM.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Real-time phone validation
        $emergencyContactPhone
            .dropFirst()
            .sink { [weak self] phone in
                guard let self else { return }
                self.validationFailures.removeAll { $0.field == .emergencyContactPhone }
                if let failure = ProfileValidator.validatePhone(phone) {
                    self.validationFailures.append(failure)
                }
            }
            .store(in: &cancellables)

        // Real-time name validation (family member only)
        $familyMemberName
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, !self.isForSelf else { return }
                self.validationFailures.removeAll { $0.field == .displayName }
                let profile = self.buildDraftProfile()
                let nameFailures = ProfileValidator.validate(step: 1, profile: profile).failures
                self.validationFailures.append(contentsOf: nameFailures)
            }
            .store(in: &cancellables)
    }
}
