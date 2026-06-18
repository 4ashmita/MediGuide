import Foundation
import Combine

final class AuthStateManager: ObservableObject {

    // MARK: - Singleton (allows static access from ProfileStore)

    static let shared = AuthStateManager()

    // MARK: - Published state

    @Published private(set) var isAuthenticated: Bool = false

    // MARK: - Settings (read from UserDefaults each time — stays in sync with PrivacySettingsViewModel)

    var isPrivacyEnabled: Bool {
        UserDefaults.standard.bool(forKey: StorageKeys.Defaults.privacyEnabled)
    }

    var windowMinutes: Int {
        let v = UserDefaults.standard.integer(forKey: StorageKeys.Defaults.privacyWindowMinutes)
        return v > 0 ? v : 5
    }

    var lockOnBackground: Bool {
        let key = StorageKeys.Defaults.privacyLockOnBackground
        if UserDefaults.standard.object(forKey: key) == nil { return true }
        return UserDefaults.standard.bool(forKey: key)
    }

    // MARK: - Internal tracking

    private var authenticatedAt: Date?
    private var windowTimer: Timer?

    private init() {}

    // MARK: - Record successful auth

    func recordAuthentication() {
        isAuthenticated = true
        authenticatedAt = Date()
        scheduleWindowExpiry()
    }

    // MARK: - Invalidate

    func lock() {
        isAuthenticated = false
        authenticatedAt = nil
        windowTimer?.invalidate()
        windowTimer = nil
    }

    func handleBackground() {
        if lockOnBackground { lock() }
    }

    func handleForeground() {
        guard isAuthenticated, let at = authenticatedAt else { return }
        let elapsed = Date().timeIntervalSince(at)
        if elapsed >= Double(windowMinutes * 60) { lock() }
    }

    // MARK: - Guard helper

    /// Returns true if the app needs to show the privacy gate before accessing profiles.
    var requiresAuthentication: Bool {
        isPrivacyEnabled && !isAuthenticated
    }

    // MARK: - Window timer

    private func scheduleWindowExpiry() {
        windowTimer?.invalidate()
        guard windowMinutes < Int.max else { return }
        let interval = TimeInterval(windowMinutes * 60)
        windowTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.lock() }
        }
    }
}
