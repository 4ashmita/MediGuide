import SwiftUI
import Combine

@MainActor
final class AppearanceManager: ObservableObject {
    private let store: SettingsStore

    init(store: SettingsStore = .shared) { self.store = store }

    var dynamicTypeSize: DynamicTypeSize {
        switch store.textSizeLevel {
        case 0: return .medium
        case 1: return .large
        case 2: return .xLarge
        case 3: return .xxLarge
        default: return .accessibility1
        }
    }

    var legibilityWeight: LegibilityWeight {
        store.boldText ? .bold : .regular
    }

    var isReduceMotionEnabled: Bool {
        store.reduceMotion || UIAccessibility.isReduceMotionEnabled
    }

    var isHighContrast: Bool { store.highContrast }
    var isOneHandedMode: Bool { store.oneHandedMode }
    var isElderlyLargeUI: Bool { store.elderlyLargeUI }

    // Called when any setting changes to notify dependent views
    func settingChanged() { objectWillChange.send() }
}
