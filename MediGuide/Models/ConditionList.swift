import Foundation

struct ConditionEntry {
    let conditionId: String
    let displayName: String
    let modifierId: String
    let weight: Int
    let description: String
}

enum ConditionList {

    static let all: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "diabetic_type1",
            displayName: "Diabetes (Type 1)",
            modifierId: "diabetic",
            weight: 3,
            description: "Insulin-dependent diabetes. Affects blood sugar regulation and wound healing."
        ),
        ConditionEntry(
            conditionId: "diabetic_type2",
            displayName: "Diabetes (Type 2)",
            modifierId: "diabetic",
            weight: 3,
            description: "Non-insulin-dependent diabetes. Affects immune response and symptom presentation."
        ),
        ConditionEntry(
            conditionId: "heart_condition",
            displayName: "Heart Condition",
            modifierId: "heart_condition",
            weight: 4,
            description: "Covers arrhythmia, coronary disease, heart failure, or any diagnosed cardiac condition."
        ),
        ConditionEntry(
            conditionId: "asthma",
            displayName: "Asthma",
            modifierId: "asthma",
            weight: 2,
            description: "Chronic airway condition that can escalate respiratory symptoms rapidly."
        ),
        ConditionEntry(
            conditionId: "copd",
            displayName: "COPD (Chronic Obstructive Pulmonary Disease)",
            modifierId: "copd",
            weight: 3,
            description: "Chronic lung disease that reduces baseline respiratory reserve."
        ),
        ConditionEntry(
            conditionId: "immunocompromised",
            displayName: "Immunocompromised",
            modifierId: "immunocompromised",
            weight: 4,
            description: "Includes cancer treatment, HIV, organ transplant, or long-term steroid use."
        ),
        ConditionEntry(
            conditionId: "epilepsy",
            displayName: "Epilepsy or Seizure Disorder",
            modifierId: "epilepsy",
            weight: 2,
            description: "Known seizure disorder. Seizures in this context may differ from new-onset events."
        ),
        ConditionEntry(
            conditionId: "stroke_history",
            displayName: "Stroke History",
            modifierId: "stroke_history",
            weight: 3,
            description: "Prior stroke increases risk of recurrence; neurological symptoms warrant faster escalation."
        ),
        ConditionEntry(
            conditionId: "high_blood_pressure",
            displayName: "High Blood Pressure",
            modifierId: "high_blood_pressure",
            weight: 2,
            description: "Hypertension increases risk for stroke, heart attack, and kidney complications."
        ),
        ConditionEntry(
            conditionId: "kidney_disease",
            displayName: "Kidney Disease",
            modifierId: "kidney_disease",
            weight: 2,
            description: "Chronic kidney disease affects medication processing and fluid balance."
        ),
        ConditionEntry(
            conditionId: "liver_disease",
            displayName: "Liver Disease",
            modifierId: "liver_disease",
            weight: 2,
            description: "Affects medication metabolism and increases bleeding risk."
        ),
        ConditionEntry(
            conditionId: "blood_clotting_disorder",
            displayName: "Blood Clotting Disorder",
            modifierId: "blood_clotting_disorder",
            weight: 3,
            description: "Includes clotting and bleeding disorders. Affects response to injury and bleeding symptoms."
        ),
        ConditionEntry(
            conditionId: "mental_health_condition",
            displayName: "Severe Mental Health Condition",
            modifierId: "mental_health_condition",
            weight: 2,
            description: "May affect ability to communicate symptoms or follow instructions during triage."
        ),
        ConditionEntry(
            conditionId: "dementia",
            displayName: "Dementia or Alzheimer's",
            modifierId: "dementia",
            weight: 4,
            description: "Cognitive impairment affects symptom reporting and baseline mental status assessment."
        ),
        // Pregnancy — trimester-specific entries
        ConditionEntry(
            conditionId: "pregnant_t1",
            displayName: "Pregnancy — First Trimester",
            modifierId: "pregnant_t1",
            weight: 3,
            description: "Weeks 1–12. Risk of ectopic pregnancy and miscarriage; medications require extra caution."
        ),
        ConditionEntry(
            conditionId: "pregnant_t2",
            displayName: "Pregnancy — Second Trimester",
            modifierId: "pregnant_t2",
            weight: 3,
            description: "Weeks 13–26. Preeclampsia and preterm labor signs begin to apply."
        ),
        ConditionEntry(
            conditionId: "pregnant_t3",
            displayName: "Pregnancy — Third Trimester",
            modifierId: "pregnant_t3",
            weight: 5,
            description: "Weeks 27–40. Highest risk period — preeclampsia, placental abruption, preterm labor."
        ),
        ConditionEntry(
            conditionId: "postpartum",
            displayName: "Postpartum (within 6 weeks of delivery)",
            modifierId: "postpartum",
            weight: 4,
            description: "Elevated risk for hemorrhage, blood clots, postpartum preeclampsia, and infection."
        ),
        ConditionEntry(
            conditionId: "pregnant_unknown",
            displayName: "Pregnancy — Trimester Unknown",
            modifierId: "pregnant",
            weight: 3,
            description: "Pregnancy confirmed but trimester not known."
        )
    ]

    static func entry(for conditionId: String) -> ConditionEntry? {
        all.first { $0.conditionId == conditionId }
    }
}
