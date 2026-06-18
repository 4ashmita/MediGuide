import Foundation
import Combine
import SwiftUI

enum EmergencyContext: Equatable {
    case noSession
    case activeTriage
    case resultsCall911
    case resultsLowerTier
    case firstAid
    case profileEditing
    case countdownActive

    var autoDismisses: Bool {
        self == .noSession || self == .profileEditing
    }

    var confirmationMessage: String {
        switch self {
        case .noSession:        return "This will begin a 10-second countdown before calling emergency services."
        case .activeTriage:     return "Your triage session will be saved."
        case .resultsLowerTier: return "This will override the current recommendation."
        case .firstAid:         return "First aid instructions will remain available during the call."
        case .profileEditing:   return "Profile changes will not be saved."
        default:                return ""
        }
    }
}

@MainActor
final class EmergencyButtonCoordinator: ObservableObject {
    @Published var showQuickConfirmation: Bool = false
    private(set) var activeContext: EmergencyContext = .noSession

    func buttonTapped(context: EmergencyContext, appState: AppState) {
        guard context != .countdownActive else { return }
        if context == .resultsCall911 {
            appState.isEmergencyCountdownRunning = true
            return
        }
        activeContext = context
        showQuickConfirmation = true
    }

    func confirm(appState: AppState) {
        showQuickConfirmation = false
        appState.isEmergencyCountdownRunning = true
    }

    func cancel() {
        showQuickConfirmation = false
    }
}
