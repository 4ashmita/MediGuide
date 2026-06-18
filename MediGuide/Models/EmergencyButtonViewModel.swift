import Foundation
import Combine

@MainActor
final class EmergencyButtonViewModel: ObservableObject {
    @Published private(set) var isPressed: Bool = false

    func setPressed(_ pressed: Bool) {
        isPressed = pressed
    }
}
