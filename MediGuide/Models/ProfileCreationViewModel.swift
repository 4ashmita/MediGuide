import Foundation
import Combine
import SwiftUI

final class ProfileCreationViewModel: ObservableObject {

    static let totalSteps = 7

    // MARK: - Step tracking

    @Published private(set) var currentStep: Int = 1
    @Published private(set) var validationError: String? = nil

    // MARK: - Step 1: Who

    @Published var isForSelf: Bool = true
    @Published var familyMemberName: String = ""

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

    // MARK: - Navigation

    var isNextEnabled: Bool {
        ProfileValidator.isStepValid(step: currentStep, profile: buildDraftProfile())
    }

    var isLastStep: Bool { currentStep == Self.totalSteps }
    var progress: Double { Double(currentStep) / Double(Self.totalSteps) }

    func goNext() {
        guard isNextEnabled, currentStep < Self.totalSteps else { return }
        validationError = nil
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 1 else { return }
        validationError = nil
        currentStep -= 1
    }

    func jumpToStep(_ step: Int) {
        guard step >= 1, step <= Self.totalSteps else { return }
        currentStep = step
    }

    // MARK: - List helpers

    // MARK: - Save

    @discardableResult
    func save() -> Bool {
        let profile = buildDraftProfile()
        if let error = ProfileValidator.validate(profile) {
            validationError = error.errorDescription
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
        profile.emergencyContactName = emergencyContactName
        profile.emergencyContactPhone = emergencyContactPhone
        return profile
    }
}
