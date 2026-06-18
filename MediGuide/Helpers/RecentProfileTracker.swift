import Foundation

enum RecentProfileTracker {

    // MARK: - Record usage

    static func record(id: UUID) {
        var usage = load()
        usage[id.uuidString] = Date()
        save(usage)
    }

    // MARK: - Remove on profile deletion

    static func remove(id: UUID) {
        var usage = load()
        usage.removeValue(forKey: id.uuidString)
        save(usage)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.Defaults.recentProfileUsage)
    }

    // MARK: - Ordering

    /// Returns all IDs from the provided set sorted most-recently-used first.
    /// IDs with no recorded usage appear at the end, sorted by their position in `allIds`.
    static func orderedIds(from allIds: [UUID]) -> [UUID] {
        let usage = load()
        return allIds.sorted { a, b in
            let dateA = usage[a.uuidString]
            let dateB = usage[b.uuidString]
            switch (dateA, dateB) {
            case let (.some(a), .some(b)): return a > b
            case (.some, .none): return true
            case (.none, .some): return false
            case (.none, .none): return false
            }
        }
    }

    /// Returns the single most recently used profile ID among the provided set.
    static func mostRecent(from allIds: [UUID]) -> UUID? {
        orderedIds(from: allIds).first
    }

    // MARK: - Private storage

    private static func load() -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.Defaults.recentProfileUsage),
              let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func save(_ usage: [String: Date]) {
        if let data = try? JSONEncoder().encode(usage) {
            UserDefaults.standard.set(data, forKey: StorageKeys.Defaults.recentProfileUsage)
        }
    }
}
