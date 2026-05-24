//
//  TriageModels.swift
//  MediGuide
//
//  Core data models for the triage system
//

import Foundation

// MARK: - Enums

enum RecommendationTier: String, Codable {
    case call911 = "CALL_911"
    case goToER = "GO_TO_ER"
    case urgentCare = "URGENT_CARE"
    case monitor = "MONITOR"
    
    var displayName: String {
        switch self {
        case .call911: return "Call 911 Now"
        case .goToER: return "Go to ER Now"
        case .urgentCare: return "Go to Urgent Care"
        case .monitor: return "Monitor Carefully"
        }
    }
    
    var color: String {
        switch self {
        case .call911: return "#FF0000"
        case .goToER: return "#FF6600"
        case .urgentCare: return "#FFB300"
        case .monitor: return "#00AA00"
        }
    }
}

enum AgeGroup {
    case infant      // under 2
    case child       // 2-12
    case adult       // 13-64
    case elderly     // 65+
    
    var scoreMultiplier: Double {
        switch self {
        case .infant: return 1.5
        case .child: return 1.2
        case .adult: return 1.0
        case .elderly: return 1.3
        }
    }
}

// MARK: - Data Models

struct Symptom: Identifiable {
    let id = UUID()
    let symptomId: String
    let weight: Int
}

struct Modifier: Identifiable {
    let id = UUID()
    let modifierId: String
    let weight: Int
}

struct TriageSession {
    var symptoms: [Symptom] = []
    var modifiers: [Modifier] = []
    var ageGroup: AgeGroup = .adult
    var hardOverrideTriggered: Bool = false
    var instinctOverrideUsed: Bool = false
    var totalScore: Int = 0
    var currentTier: RecommendationTier = .monitor
}

// MARK: - JSON Decodable Models

struct DecisionTreeData: Codable {
    let version: String
    let symptomWeights: [String: Int]
    let modifierWeights: [String: Int]
    let hardOverrides: [String]
    let recommendationTiers: [String: TierConfig]
    
    struct TierConfig: Codable {
        let minScore: Int
    }
}//
//  TriageModels.swift
//  MediGuide
//
//  Created by Ashmita Appineni on 2/17/26.
//

