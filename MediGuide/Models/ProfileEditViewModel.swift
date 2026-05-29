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
    @Published private(set) var isSaved: Bool = false

    var hasChanges: Bool { changeTracker.hasChanges }

    var canSave: Bool {
        hasChanges && ProfileValidator.isStepValid(step: 2, profile: buildDraftProfile())
            && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Init

    init(profileId: UUID) {
        self.profileId = profileId
        let placeholder = UserProfile(displayName: "", dateOfBirth: Date(), biologicalSex: .preferNotToSay)
        self.original = placeholder
        self.changeTracker = ChangeTracker(original: placeholder)
        load()
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

    // MARK: - Save

    @discardableResult
    func save() -> Bool {
        let profile = buildDraftProfile()
        if let error = ProfileValidator.validate(profile) {
            validationError = error.errorDescription
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
}
