import Foundation
import Combine

// Tracks the navigation context at the moment the emergency countdown was triggered,
// and ensures the correct return path when the countdown ends or is cancelled.
@MainActor
final class AppNavigationManager: ObservableObject {
    private(set) var returnContext: EmergencyContext = .noSession
    private var cancellable: AnyCancellable?

    func willStartCountdown(from context: EmergencyContext, appState: AppState) {
        returnContext = context
        // Observe countdown ending to perform any return-path restoration.
        cancellable = appState.$isEmergencyCountdownRunning
            .dropFirst()
            .filter { !$0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.didEndCountdown(appState: appState)
            }
    }

    private func didEndCountdown(appState: AppState) {
        // Triage and results screens persist under the fullScreenCover — no restoration needed.
        // Profile editing: the sheet was discarded before countdown started per UX spec.
        // All other contexts restore naturally when the cover dismisses.
        returnContext = .noSession
        cancellable = nil
    }
}
