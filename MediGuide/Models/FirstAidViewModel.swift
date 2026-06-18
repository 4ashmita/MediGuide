import Foundation
import Combine

@MainActor
final class FirstAidViewModel: ObservableObject {

    @Published private(set) var emergencyType: FirstAidEmergencyType
    @Published private(set) var instructionSet: FirstAidInstructionSet?
    @Published var symptomOnsetTime: Date? = nil
    @Published var alternativeTypes: [FirstAidEmergencyType] = []

    let navManager = FirstAidNavigationManager()

    private let session: TriageSession
    private var cancellables: Set<AnyCancellable> = []

    init(emergencyType: FirstAidEmergencyType, session: TriageSession) {
        self.emergencyType = emergencyType
        self.session = session
        loadContent(for: emergencyType)
        buildAlternatives()

        // Forward navManager's published changes through vm so the view re-renders.
        navManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Content Loading

    func loadContent(for type: FirstAidEmergencyType) {
        emergencyType = type
        if let set = FirstAidLibrary.instructionSet(for: type) {
            instructionSet = set
            navManager.load(steps: set.steps)
        }
    }

    private func buildAlternatives() {
        let primary = emergencyType
        let symptoms = Set(session.symptoms.map { $0.symptomId })

        var alts: [FirstAidEmergencyType] = []

        // CPR types can coexist with other presentations
        if primary != .cprAdult && primary != .cprInfant {
            if symptoms.contains("chest_pain") && primary != .cardiac { alts.append(.cardiac) }
            if symptoms.contains("severe_bleeding") && primary != .severebleeding { alts.append(.severebleeding) }
        }
        if primary != .general { alts.append(.general) }

        alternativeTypes = alts
    }

    // MARK: - Profile-Aware Helpers

    var hasEpiPen: Bool {
        let meds = session.sessionMedicationList.lowercased()
        return meds.contains("epipen") || meds.contains("epinephrine") || meds.contains("auvi")
    }

    var aspirinContraindicated: Bool {
        session.sessionAllergyList.lowercased().contains("aspirin")
    }

    // MARK: - Actions

    func recordSymptomOnsetTime() {
        symptomOnsetTime = Date()
    }
}
