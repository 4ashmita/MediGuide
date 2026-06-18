import Foundation
import Combine
import UIKit

@MainActor
final class EmergencyAlertViewModel: ObservableObject {

    enum Phase { case countdown, showSMS, callPlaced }

    @Published private(set) var phase: Phase = .countdown
    @Published private(set) var secondsRemaining: Int = 10
    @Published var showCancelConfirm: Bool = false
    @Published private(set) var smsBody: String = ""
    @Published private(set) var smsRecipient: String = ""

    let session: TriageSession

    private let locationPackager = EmergencyLocationPackager()
    private var countdownTask: Task<Void, Never>?

    init(session: TriageSession) {
        self.session = session
        buildSMSBody(locationURL: "")
        startLocationCapture()
        startCountdown()
    }

    func callNow() {
        countdownTask?.cancel()
        placeCall()
    }

    func cancel() {
        showCancelConfirm = true
    }

    func dismissSMS() {
        phase = .callPlaced
    }

    // MARK: - Private

    private func startCountdown() {
        countdownTask = Task {
            for remaining in stride(from: secondsRemaining - 1, through: 0, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                secondsRemaining = remaining
            }
            placeCall()
        }
    }

    private func startLocationCapture() {
        Task {
            let url = await locationPackager.captureLocationURL()
            buildSMSBody(locationURL: url)
        }
    }

    private func buildSMSBody(locationURL: String) {
        var lines: [String] = []
        let name = session.sessionDisplayName.isEmpty ? "Unknown patient" : session.sessionDisplayName
        lines.append("EMERGENCY — \(name)")
        if let age = session.sessionAge { lines.append("Age: \(age)") }
        if !session.sessionBloodType.isEmpty { lines.append("Blood type: \(session.sessionBloodType)") }
        if !session.sessionMedicationList.isEmpty { lines.append("Medications: \(session.sessionMedicationList)") }
        if !session.sessionAllergyList.isEmpty { lines.append("Allergies: \(session.sessionAllergyList)") }
        if !locationURL.isEmpty { lines.append("Location: \(locationURL)") }
        lines.append("Sent via MediGuide")
        smsBody = lines.joined(separator: "\n")
        smsRecipient = session.sessionEmergencyContactPhone
    }

    private func placeCall() {
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
        phase = .showSMS
    }
}
