import Foundation

enum ProfileOrderManager {

    static func saveOrder(_ ids: [UUID]) {
        guard let encrypted = EncryptionManager.encrypt(ids) else { return }
        UserDefaults.standard.set(encrypted, forKey: StorageKeys.Defaults.profileOrder)
    }

    static func loadOrder() -> [UUID]? {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.Defaults.profileOrder) else { return nil }
        return EncryptionManager.decrypt([UUID].self, from: data)
    }

    static func deleteOrder() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.Defaults.profileOrder)
    }

    /// Returns summaries in manual order when available, otherwise by lastUsed descending.
    static func apply(order: [UUID]?, to summaries: [ProfileSummary]) -> [ProfileSummary] {
        guard let order, !order.isEmpty else {
            return summaries.sorted { $0.lastUsed > $1.lastUsed }
        }
        let indexed = Dictionary(uniqueKeysWithValues: summaries.map { ($0.id, $0) })
        var result = order.compactMap { indexed[$0] }
        // Append any summaries not yet in the manual order (e.g. newly added profiles)
        let orderedIds = Set(order)
        result += summaries.filter { !orderedIds.contains($0.id) }
        return result
    }
}
