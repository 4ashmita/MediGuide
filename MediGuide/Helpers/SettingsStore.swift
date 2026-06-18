import Foundation
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private init() {}
    private let ud = UserDefaults.standard

    private enum Key {
        // Accessibility
        static let textSizeLevel          = "mediguide.settings.textSizeLevel"
        static let highContrast           = "mediguide.settings.highContrast"
        static let reduceMotion           = "mediguide.settings.reduceMotion"
        static let oneHandedMode          = "mediguide.settings.oneHandedMode"
        static let elderlyLargeUI         = "mediguide.settings.elderlyLargeUI"
        static let boldText               = "mediguide.settings.boldText"
        static let pillShapeButtons       = "mediguide.settings.pillShapeButtons"
        static let maxBrightnessEmergency = "mediguide.settings.maxBrightnessEmergency"
        // Voice & Audio
        static let voiceNarration         = "mediguide.settings.voiceNarration"
        static let narrationSpeed         = "mediguide.settings.narrationSpeed"
        static let autoReadRecommendation = "mediguide.settings.autoReadRecommendation"
        static let autoReadFirstAid       = "mediguide.settings.autoReadFirstAid"
        static let voiceCommands          = "mediguide.settings.voiceCommands"
        static let alertToneCountdown     = "mediguide.settings.alertToneCountdown"
        static let alertToneTimer         = "mediguide.settings.alertToneTimer"
        static let alertToneCPR           = "mediguide.settings.alertToneCPR"
        // Triage
        static let defaultInputMode       = "mediguide.settings.defaultInputMode"
        static let reassessIntervalER     = "mediguide.settings.reassessIntervalER"
        static let reassessIntervalUC     = "mediguide.settings.reassessIntervalUC"
        static let reassessIntervalMonitor = "mediguide.settings.reassessIntervalMonitor"
        static let autoEscalation         = "mediguide.settings.autoEscalation"
        static let instinctButtonStyle    = "mediguide.settings.instinctButtonStyle"
        static let showScoreExplanation   = "mediguide.settings.showScoreExplanation"
        static let warningDetailLevel     = "mediguide.settings.warningDetailLevel"
        // Notifications
        static let checkInNotifications   = "mediguide.settings.checkInNotifications"
        static let emergencySMSEnabled    = "mediguide.settings.emergencySMSEnabled"
        static let notificationPrivacy    = "mediguide.settings.notificationPrivacy"
        static let profileUpdateReminders = "mediguide.settings.profileUpdateReminders"
        // Language/Region
        static let tempUnitFahrenheit     = "mediguide.settings.tempUnitFahrenheit"
        static let distanceUnitMiles      = "mediguide.settings.distanceUnitMiles"
        // App meta
        static let installDate            = "mediguide.settings.installDate"
    }

    // MARK: - Accessibility

    var textSizeLevel: Int {
        get { ud.object(forKey: Key.textSizeLevel) as? Int ?? 2 }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.textSizeLevel) }
    }

    var highContrast: Bool {
        get { ud.bool(forKey: Key.highContrast) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.highContrast) }
    }

    var reduceMotion: Bool {
        get { ud.bool(forKey: Key.reduceMotion) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.reduceMotion) }
    }

    var oneHandedMode: Bool {
        get { ud.bool(forKey: Key.oneHandedMode) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.oneHandedMode) }
    }

    var elderlyLargeUI: Bool {
        get { ud.bool(forKey: Key.elderlyLargeUI) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.elderlyLargeUI) }
    }

    var boldText: Bool {
        get { ud.bool(forKey: Key.boldText) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.boldText) }
    }

    var pillShapeButtons: Bool {
        get { ud.bool(forKey: Key.pillShapeButtons) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.pillShapeButtons) }
    }

    var maxBrightnessEmergency: Bool {
        get {
            if ud.object(forKey: Key.maxBrightnessEmergency) == nil { return true }
            return ud.bool(forKey: Key.maxBrightnessEmergency)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.maxBrightnessEmergency) }
    }

    // MARK: - Voice & Audio

    var voiceNarration: Bool {
        get { ud.bool(forKey: Key.voiceNarration) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.voiceNarration) }
    }

    var narrationSpeed: Double {
        get {
            if ud.object(forKey: Key.narrationSpeed) == nil { return 0.5 }
            return ud.double(forKey: Key.narrationSpeed)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.narrationSpeed) }
    }

    var autoReadRecommendation: Bool {
        get {
            if ud.object(forKey: Key.autoReadRecommendation) == nil { return true }
            return ud.bool(forKey: Key.autoReadRecommendation)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.autoReadRecommendation) }
    }

    var autoReadFirstAid: Bool {
        get {
            if ud.object(forKey: Key.autoReadFirstAid) == nil { return true }
            return ud.bool(forKey: Key.autoReadFirstAid)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.autoReadFirstAid) }
    }

    var voiceCommands: Bool {
        get { ud.bool(forKey: Key.voiceCommands) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.voiceCommands) }
    }

    var alertToneCountdown: Bool {
        get {
            if ud.object(forKey: Key.alertToneCountdown) == nil { return true }
            return ud.bool(forKey: Key.alertToneCountdown)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.alertToneCountdown) }
    }

    var alertToneTimer: Bool {
        get {
            if ud.object(forKey: Key.alertToneTimer) == nil { return true }
            return ud.bool(forKey: Key.alertToneTimer)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.alertToneTimer) }
    }

    var alertToneCPR: Bool {
        get {
            if ud.object(forKey: Key.alertToneCPR) == nil { return true }
            return ud.bool(forKey: Key.alertToneCPR)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.alertToneCPR) }
    }

    // MARK: - Triage

    var defaultInputMode: Int {
        get {
            if ud.object(forKey: Key.defaultInputMode) == nil { return 2 }
            return ud.integer(forKey: Key.defaultInputMode)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.defaultInputMode) }
    }

    var reassessIntervalER: Int {
        get {
            if ud.object(forKey: Key.reassessIntervalER) == nil { return 15 }
            return ud.integer(forKey: Key.reassessIntervalER)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.reassessIntervalER) }
    }

    var reassessIntervalUC: Int {
        get {
            if ud.object(forKey: Key.reassessIntervalUC) == nil { return 30 }
            return ud.integer(forKey: Key.reassessIntervalUC)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.reassessIntervalUC) }
    }

    var reassessIntervalMonitor: Int {
        get {
            if ud.object(forKey: Key.reassessIntervalMonitor) == nil { return 120 }
            return ud.integer(forKey: Key.reassessIntervalMonitor)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.reassessIntervalMonitor) }
    }

    var autoEscalation: Bool {
        get {
            if ud.object(forKey: Key.autoEscalation) == nil { return true }
            return ud.bool(forKey: Key.autoEscalation)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.autoEscalation) }
    }

    var instinctButtonStyle: Int {
        get {
            if ud.object(forKey: Key.instinctButtonStyle) == nil { return 1 }
            return ud.integer(forKey: Key.instinctButtonStyle)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.instinctButtonStyle) }
    }

    var showScoreExplanation: Bool {
        get {
            if ud.object(forKey: Key.showScoreExplanation) == nil { return true }
            return ud.bool(forKey: Key.showScoreExplanation)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.showScoreExplanation) }
    }

    var warningDetailLevel: Int {
        get {
            if ud.object(forKey: Key.warningDetailLevel) == nil { return 1 }
            return ud.integer(forKey: Key.warningDetailLevel)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.warningDetailLevel) }
    }

    // MARK: - Notifications

    var checkInNotifications: Bool {
        get {
            if ud.object(forKey: Key.checkInNotifications) == nil { return true }
            return ud.bool(forKey: Key.checkInNotifications)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.checkInNotifications) }
    }

    var emergencySMSEnabled: Bool {
        get {
            if ud.object(forKey: Key.emergencySMSEnabled) == nil { return true }
            return ud.bool(forKey: Key.emergencySMSEnabled)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.emergencySMSEnabled) }
    }

    var notificationPrivacy: Bool {
        get { ud.bool(forKey: Key.notificationPrivacy) }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.notificationPrivacy) }
    }

    var profileUpdateReminders: Bool {
        get {
            if ud.object(forKey: Key.profileUpdateReminders) == nil { return true }
            return ud.bool(forKey: Key.profileUpdateReminders)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.profileUpdateReminders) }
    }

    // MARK: - Language / Region

    var tempUnitFahrenheit: Bool {
        get {
            if ud.object(forKey: Key.tempUnitFahrenheit) == nil { return true }
            return ud.bool(forKey: Key.tempUnitFahrenheit)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.tempUnitFahrenheit) }
    }

    var distanceUnitMiles: Bool {
        get {
            if ud.object(forKey: Key.distanceUnitMiles) == nil { return true }
            return ud.bool(forKey: Key.distanceUnitMiles)
        }
        set { objectWillChange.send(); ud.set(newValue, forKey: Key.distanceUnitMiles) }
    }

    // MARK: - App Meta

    var installDate: Date {
        if let d = ud.object(forKey: Key.installDate) as? Date { return d }
        let now = Date()
        ud.set(now, forKey: Key.installDate)
        return now
    }

    var hasUsedAppForAWeek: Bool {
        Date().timeIntervalSince(installDate) > 7 * 24 * 3600
    }
}
