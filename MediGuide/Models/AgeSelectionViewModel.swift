import Foundation
import Combine

@MainActor
final class AgeSelectionViewModel: ObservableObject {
    @Published var selectedAgeGroup: AgeGroup? = nil
    @Published var ageIsEstimated: Bool = false

    var isNextEnabled: Bool { selectedAgeGroup != nil }

    func select(_ group: AgeGroup, estimated: Bool = false) {
        selectedAgeGroup = group
        ageIsEstimated = estimated
    }
}
