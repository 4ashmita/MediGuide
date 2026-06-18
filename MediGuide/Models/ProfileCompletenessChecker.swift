import Foundation

struct CompletenessIssue: Identifiable {
    enum Category { case requiredMissing, recommendedMissing, outdated }
    enum RecommendedAction { case editProfile, addEmergencyContact, reviewProfile }

    let id: String
    let category: Category
    let description: String
    let recommendedAction: RecommendedAction
}

struct CompletenessReport {
    enum Status { case complete, incomplete, outdated }
    let score: Int           // 0–100
    let status: Status
    let issues: [CompletenessIssue]
    let daysSinceModified: Int
}

enum ProfileCompletenessChecker {

    static func check(_ profile: UserProfile) -> CompletenessReport {
        var issues: [CompletenessIssue] = []
        var earned = 0
        let total = 100

        // Required: name (25 pts)
        if !profile.displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            earned += 25
        } else {
            issues.append(CompletenessIssue(
                id: "name",
                category: .requiredMissing,
                description: "Display name is required",
                recommendedAction: .editProfile
            ))
        }

        // Recommended: emergency contact (30 pts — most impactful for app function)
        if !profile.emergencyContactPhone.trimmingCharacters(in: .whitespaces).isEmpty {
            earned += 30
        } else {
            issues.append(CompletenessIssue(
                id: "contact",
                category: .recommendedMissing,
                description: "No emergency contact — SMS feature disabled",
                recommendedAction: .addEmergencyContact
            ))
        }

        // Optional: blood type (15 pts bonus — not required for complete status)
        if profile.bloodType != .unknown {
            earned += 15
        }

        // Currency (30 pts total, degraded over time)
        let days = Calendar.current.dateComponents([.day], from: profile.dateModified, to: Date()).day ?? 0
        if days < 180 {
            earned += 30
        } else if days < 365 {
            earned += 15
            issues.append(CompletenessIssue(
                id: "aging",
                category: .outdated,
                description: "Last updated \(days) days ago — consider reviewing",
                recommendedAction: .reviewProfile
            ))
        } else {
            issues.append(CompletenessIssue(
                id: "stale",
                category: .outdated,
                description: "Not updated in over a year",
                recommendedAction: .reviewProfile
            ))
        }

        let score = min(total, earned)

        let status: CompletenessReport.Status
        if issues.contains(where: { $0.category == .outdated }) {
            status = .outdated
        } else if issues.isEmpty {
            status = .complete
        } else {
            status = .incomplete
        }

        return CompletenessReport(
            score: score,
            status: status,
            issues: issues,
            daysSinceModified: days
        )
    }
}
