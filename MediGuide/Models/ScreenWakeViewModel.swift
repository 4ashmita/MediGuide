import Combine

@MainActor
final class ScreenWakeViewModel: ObservableObject {
    private let registry = WakeContextRegistry.shared

    func activate(context: WakeContext) {
        registry.register(context)
    }

    func deactivate(context: WakeContext) {
        registry.release(context)
    }
}
