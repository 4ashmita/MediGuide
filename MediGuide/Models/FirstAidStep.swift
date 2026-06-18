import Foundation

struct FirstAidStep: Identifiable, Decodable {
    let id: String
    let instruction: String
    let detail: String?
    let warning: String?
    let timerSeconds: Int?
    let illustrationKey: String?
    let linkedEmergencyType: String?
    let isCPRTimer: Bool
    let isAutoAdvance: Bool

    private enum CodingKeys: String, CodingKey {
        case id, instruction, detail, warning, timerSeconds
        case illustrationKey, linkedEmergencyType, isCPRTimer, isAutoAdvance
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = try c.decode(String.self, forKey: .id)
        instruction         = try c.decode(String.self, forKey: .instruction)
        detail              = try c.decodeIfPresent(String.self, forKey: .detail)
        warning             = try c.decodeIfPresent(String.self, forKey: .warning)
        timerSeconds        = try c.decodeIfPresent(Int.self, forKey: .timerSeconds)
        illustrationKey     = try c.decodeIfPresent(String.self, forKey: .illustrationKey)
        linkedEmergencyType = try c.decodeIfPresent(String.self, forKey: .linkedEmergencyType)
        isCPRTimer          = try c.decodeIfPresent(Bool.self, forKey: .isCPRTimer) ?? false
        isAutoAdvance       = try c.decodeIfPresent(Bool.self, forKey: .isAutoAdvance) ?? true
    }
}

struct FirstAidInstructionSet: Decodable {
    let title: String
    let subtitle: String
    let steps: [FirstAidStep]
}
