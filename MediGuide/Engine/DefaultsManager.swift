import Foundation

enum DefaultsManager {
    private static var store: SettingsStore { .shared }

    // Reassessment intervals in seconds
    static func reassessSeconds(for tier: RecommendationTier) -> Int {
        switch tier {
        case .goToER:     return store.reassessIntervalER * 60
        case .urgentCare: return store.reassessIntervalUC * 60
        case .monitor:    return store.reassessIntervalMonitor * 60
        case .call911:    return 0
        }
    }

    enum InputMode: Int { case naturalLanguage = 0, guidedQuestions = 1, askEachTime = 2 }
    static var defaultInputMode: InputMode { InputMode(rawValue: store.defaultInputMode) ?? .askEachTime }

    static var autoEscalation: Bool { store.autoEscalation }
    static var showScoreExplanation: Bool { store.showScoreExplanation }
    static var emergencySMSEnabled: Bool { store.emergencySMSEnabled }
    static var voiceNarrationEnabled: Bool { store.voiceNarration }
}
