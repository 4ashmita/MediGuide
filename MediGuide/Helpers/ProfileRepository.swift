import Foundation
import SwiftUI

enum ProfileRepository {

    static let maxProfiles = 10

    // MARK: - Query

    static var hasProfiles: Bool { !summaries().isEmpty }

    static var profileCount: Int { summaries().count }

    static func summaries() -> [ProfileSummary] {
        let all = ProfileStore.listSummaries()
        let order = ProfileOrderManager.loadOrder()
        return ProfileOrderManager.apply(order: order, to: all)
    }

    static func profile(id: UUID) -> UserProfile? {
        ProfileStore.load(id: id)
    }

    // MARK: - Add

    enum AddError: Error { case limitReached, saveFailed }

    static func add(_ profile: UserProfile) throws {
        guard profileCount < maxProfiles else { throw AddError.limitReached }
        try ProfileStore.save(profile)
        // Append to manual order so new profiles appear at the bottom until used
        var order = ProfileOrderManager.loadOrder() ?? []
        if !order.contains(profile.id) { order.append(profile.id) }
        ProfileOrderManager.saveOrder(order)
    }

    // MARK: - Delete

    static func delete(id: UUID) {
        ProfileStore.delete(id: id)
        var order = ProfileOrderManager.loadOrder() ?? []
        order.removeAll { $0 == id }
        if order.isEmpty {
            ProfileOrderManager.deleteOrder()
        } else {
            ProfileOrderManager.saveOrder(order)
        }
    }

    // MARK: - Reorder

    static func reorder(_ ids: [UUID]) {
        ProfileOrderManager.saveOrder(ids)
    }

    static func move(from source: IndexSet, to destination: Int) {
        var order = summaries().map { $0.id }
        order.move(fromOffsets: source, toOffset: destination)
        ProfileOrderManager.saveOrder(order)
    }
}
