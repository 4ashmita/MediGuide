import Foundation
import Combine
import SwiftUI

final class ProfileEditViewModel: ObservableObject {

    // MARK: - Identity

    let profileId: UUID
    private var original: UserProfile
    private var changeTracker: ChangeTracker

    // MARK: - Editable fields

    @Published var displayName: String = ""
    @Published var dateOfBirth: Date = Date()
    @Published var biologicalSex: BiologicalSex = .preferNotToSay
    @Published var bloodType: BloodType = .unknown
    private(set) var medicationListVM = MedicationListViewModel()
    private var medicationCancellable: AnyCancellable?
    private(set) var allergyListVM = AllergyListViewModel()
    private var allergyCancellable: AnyCancellable?
    @Published var emergencyContactName: String = ""
    @Published var emergencyContactPhone: String = ""

    // MARK: - Conditions

    private(set) var conditionToggleVM = ConditionToggleViewModel()
    private var conditionCancellable: AnyCancellable?

    // MARK: - State

    @Published private(set) var validationError: String? = nil
    @Published private(set) var validationFailures: [ValidationFailure] = []
    @Published private(set) var isSaved: Bool = false

    private var cancellables = Set<AnyCancellable>()

    var hasChanges: Bool { changeTracker.hasChanges }

    var canSave: Bool {
        guard hasChanges else { return false }
        let profile = buildDraftProfile()
        let result = ProfileValidator.validate(profile: profile)
        return !result.hasErrors
    }

    // MARK: - Init

    init(profileId: UUID) {
        self.profileId = profileId
        let placeholder = UserProfile(displayName: "", dateOfBirth: Date(), biologicalSex: .preferNotToSay)
        self.original = placeholder
        self.changeTracker = ChangeTracker(original: placeholder)
        load()
        setupValidationObservers()
    }

    // MARK: - Load

    private func load() {
        guard let profile = ProfileStore.load(id: profileId) else { return }
        original = profile
        changeTracker = ChangeTracker(original: profile)

        displayName = profile.displayName
        dateOfBirth = profile.dateOfBirth
        biologicalSex = profile.biologicalSex
        bloodType = profile.bloodType
        medicationListVM = MedicationListViewModel(initialEntries: profile.medications)
        observeMedicationChanges()
        allergyListVM = AllergyListViewModel(initialEntries: profile.allergies)
        observeAllergyChanges()
        emergencyContactName = profile.emergencyContactName
        emergencyContactPhone = profile.emergencyContactPhone

        conditionToggleVM = ConditionToggleViewModel(
            initialConditions: profile.conditions,
            otherNote: profile.conditionOtherNote
        )
        observeConditionChanges()
    }

    private func observeMedicationChanges() {
        medicationCancellable = medicationListVM.objectWillChange.sink { [weak self] in
            guard let self else { return }
            self.changeTracker.track("medications", current: self.medicationListVM.entries)
            self.objectWillChange.send()
        }
    }

    private func observeAllergyChanges() {
        allergyCancellable = allergyListVM.objectWillChange.sink { [weak self] in
            guard let self else { return }
            self.changeTracker.track("allergies", current: self.allergyListVM.entries)
            self.objectWillChange.send()
        }
    }

    private func observeConditionChanges() {
        conditionCancellable = conditionToggleVM.objectWillChange.sink { [weak self] in
            guard let self else { return }
            let ids = self.conditionToggleVM.exportConditionIds()
            self.changeTracker.track("conditions", current: ids.sorted())
            self.changeTracker.track("conditionOtherNote", current: self.conditionToggleVM.otherNote)
            self.objectWillChange.send()
        }
    }

    // MARK: - Change tracking

    func trackField(_ field: String) {
        switch field {
        case "displayName":           changeTracker.track(field, current: displayName)
        case "dateOfBirth":           changeTracker.track(field, current: dateOfBirth)
        case "biologicalSex":         changeTracker.track(field, current: biologicalSex)
        case "bloodType":             changeTracker.track(field, current: bloodType)
        case "emergencyContactName":  changeTracker.track(field, current: emergencyContactName)
        case "emergencyContactPhone": changeTracker.track(field, current: emergencyContactPhone)
        default: break
        }
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
        let result = ProfileValidator.validate(profile: profile)
        if result.hasErrors {
            validationFailures = result.failures
            validationError = result.errors.first?.message
            return false
        }
        do {
            try ProfileStore.update(profile)
            isSaved = true
            return true
        } catch {
            validationError = "Failed to save changes. Please try again."
            return false
        }
    }

    // MARK: - Discard

    func discardChanges() {
        load()
    }

    // MARK: - Draft assembly

    func buildDraftProfile() -> UserProfile {
        var profile = original
        profile.displayName = displayName.trimmingCharacters(in: .whitespaces)
        profile.dateOfBirth = dateOfBirth
        profile.biologicalSex = biologicalSex
        profile.bloodType = bloodType
        profile.conditions = conditionToggleVM.exportConditionIds()
        profile.conditionOtherNote = conditionToggleVM.otherNote
        profile.medications = medicationListVM.entries
        profile.allergies = allergyListVM.entries
        profile.emergencyContactName = emergencyContactName
        profile.emergencyContactPhone = emergencyContactPhone
        return profile
    }

    // MARK: - Private

    private func setupValidationObservers() {
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

        // Real-time display name validation
        $displayName
            .dropFirst()
            .sink { [weak self] name in
                guard let self else { return }
                self.validationFailures.removeAll { $0.field == .displayName }
                if let failure = ProfileValidator.validateDisplayName(name) {
                    self.validationFailures.append(failure)
                }
            }
            .store(in: &cancellables)
    }
}
