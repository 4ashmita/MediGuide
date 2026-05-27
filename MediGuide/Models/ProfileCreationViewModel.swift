import Foundation
import Combine

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

    @Published var selectedConditions: Set<String> = []
    @Published var conditionOtherNote: String = ""
    @Published var isPregnantToggleOn: Bool = false
    @Published var selectedTrimesterId: String? = nil

    private static let pregnancyIds: Set<String> = [
        "pregnant_t1", "pregnant_t2", "pregnant_t3", "postpartum", "pregnant_unknown"
    ]

    func setPregnantToggle(_ on: Bool) {
        isPregnantToggleOn = on
        if !on {
            selectedTrimesterId = nil
            selectedConditions.subtract(Self.pregnancyIds)
        }
    }

    func selectTrimester(_ id: String) {
        selectedConditions.subtract(Self.pregnancyIds)
        selectedTrimesterId = id
        selectedConditions.insert(id)
    }

    var pregnancyDisplayLabel: String? {
        guard let id = selectedTrimesterId else { return nil }
        return ConditionList.entry(for: id)?.displayName
    }

    // MARK: - Step 4: Medications

    @Published var medications: [String] = []
    @Published var newMedication: String = ""

    // MARK: - Step 5: Allergies

    @Published var allergies: [String] = []
    @Published var newAllergy: String = ""

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

    func addMedication() {
        let trimmed = newMedication.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !medications.contains(trimmed) else { return }
        medications.append(trimmed)
        newMedication = ""
    }

    func removeMedication(at offsets: IndexSet) {
        medications.remove(atOffsets: offsets)
    }

    func addAllergy() {
        let trimmed = newAllergy.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !allergies.contains(trimmed) else { return }
        allergies.append(trimmed)
        newAllergy = ""
    }

    func removeAllergy(at offsets: IndexSet) {
        allergies.remove(atOffsets: offsets)
    }

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
        profile.conditions = Array(selectedConditions)
        profile.conditionOtherNote = conditionOtherNote
        profile.medications = medications
        profile.allergies = allergies
        profile.emergencyContactName = emergencyContactName
        profile.emergencyContactPhone = emergencyContactPhone
        return profile
    }
}
