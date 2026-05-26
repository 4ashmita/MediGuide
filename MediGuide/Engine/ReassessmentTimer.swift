import Foundation
import Combine

final class ReassessmentTimer: ObservableObject {

    // MARK: - Published State

    @Published private(set) var timeRemaining: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var didExpire: Bool = false

    // MARK: - Private

    private var totalInterval: Int = 0
    private var startDate: Date?
    private var backgroundDate: Date?
    private var cancellable: AnyCancellable?
    private(set) var tier: RecommendationTier?

    // MARK: - Public Interface

    func startTimer(for tier: RecommendationTier) {
        let interval = Self.interval(for: tier)
        guard interval > 0 else { return }

        self.tier = tier
        totalInterval = interval
        timeRemaining = interval
        startDate = Date()
        didExpire = false
        startTicking()
    }

    func pause() {
        guard isRunning else { return }
        backgroundDate = Date()
        stopTicking()
        if let t = tier, timeRemaining > 0 {
            NotificationManager.scheduleCheckIn(in: timeRemaining, tier: t)
        }
    }

    func resume() {
        NotificationManager.cancelCheckIn()
        guard let bg = backgroundDate, !isRunning else { return }
        let elapsed = Int(Date().timeIntervalSince(bg))
        timeRemaining = max(0, timeRemaining - elapsed)
        backgroundDate = nil
        if timeRemaining == 0 {
            expire()
        } else {
            startTicking()
        }
    }

    func reset() {
        stopTicking()
        NotificationManager.cancelCheckIn()
        timeRemaining = 0
        totalInterval = 0
        startDate = nil
        backgroundDate = nil
        didExpire = false
        tier = nil
    }

    func acknowledgeExpiry() {
        didExpire = false
    }

    // MARK: - Helpers

    static func interval(for tier: RecommendationTier) -> Int {
        switch tier {
        case .call911:    return 0
        case .goToER:     return 15 * 60
        case .urgentCare: return 30 * 60
        case .monitor:    return 120 * 60
        }
    }

    var formattedTimeRemaining: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var minutesElapsed: Int {
        guard let start = startDate else { return 0 }
        return Int(Date().timeIntervalSince(start)) / 60
    }

    // MARK: - Private

    private func startTicking() {
        isRunning = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func stopTicking() {
        isRunning = false
        cancellable = nil
    }

    private func tick() {
        guard timeRemaining > 0 else { expire(); return }
        timeRemaining -= 1
        if timeRemaining == 0 { expire() }
    }

    private func expire() {
        stopTicking()
        didExpire = true
    }
}
