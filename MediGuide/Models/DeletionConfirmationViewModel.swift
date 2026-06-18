import Foundation
import Combine

enum DeletionMode {
    case individual(ProfileSummary)
    case fullWipe
}

@MainActor
final class DeletionConfirmationViewModel: ObservableObject {

    let mode: DeletionMode

    @Published var loadedProfile: UserProfile? = nil
    @Published var allSummaries: [ProfileSummary] = []
    @Published var wipeStage: Int = 1
    @Published var typeToConfirm: String = ""
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isComplete: Bool = false

    var isDeleteEnabled: Bool {
        switch mode {
        case .individual: return true
        case .fullWipe:   return wipeStage == 2 && typeToConfirm == "DELETE"
        }
    }

    init(mode: DeletionMode) {
        self.mode = mode
    }

    func load() {
        switch mode {
        case .individual(let summary):
            loadedProfile = ProfileStore.load(id: summary.id)
        case .fullWipe:
            allSummaries = ProfileRepository.summaries()
        }
    }

    func proceedToStage2() {
        wipeStage = 2
    }

    func executeDelete() {
        Task {
            errorMessage = nil
            isAuthenticating = true
            let result = await BiometricAuthManager.authenticate(
                reason: .manageProfiles,
                allowPasscodeFallback: true
            )
            isAuthenticating = false

            switch result {
            case .success:
                break
            case .failure(let msg):
                errorMessage = msg
                return
            case .cancelled:
                return
            case .unavailable:
                errorMessage = "Authentication unavailable. Set up Face ID or a passcode in Settings."
                return
            }

            do {
                switch mode {
                case .individual(let summary):
                    try ProfileDeletionManager.deleteProfile(id: summary.id)
                case .fullWipe:
                    try ProfileDeletionManager.deleteAllProfiles()
                }
                isComplete = true
            } catch let e as ProfileDeletionManager.DeletionError {
                errorMessage = e.message
            } catch {
                errorMessage = "Deletion failed. Please try again."
            }
        }
    }
}
