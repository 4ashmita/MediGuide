import Foundation

struct ConditionEntry {
    let conditionId: String
    let displayName: String
    let modifierId: String
    let weight: Int
    let description: String
    let category: ConditionCategory
    // True for the 4 immunocompromised sub-types (share a parent header, not a toggle)
    var isImmunoSubtype: Bool = false
    // True for pregnancy trimester/stage options
    var isPregnancyStage: Bool = false
    // True for risk factors shown nested under Pregnancy
    var isPregnancyRisk: Bool = false
}

enum ConditionList {

    // MARK: - All Conditions

    static let all: [ConditionEntry] = cardiovascular
        + metabolic
        + respiratory
        + immune
        + reproductive
        + neurological
        + organFunction
        + mentalHealth
        + other

    // MARK: - Cardiovascular

    static let cardiovascular: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "heart_condition",
            displayName: "Heart Condition",
            modifierId: "heart_condition",
            weight: 4,
            description: "Includes coronary artery disease, arrhythmia, heart failure, or history of heart attack.",
            category: .cardiovascular
        ),
        ConditionEntry(
            conditionId: "high_blood_pressure",
            displayName: "High Blood Pressure",
            modifierId: "high_blood_pressure",
            weight: 2,
            description: "Hypertension increases risk for stroke, heart attack, and kidney complications.",
            category: .cardiovascular
        ),
        ConditionEntry(
            conditionId: "stroke_history",
            displayName: "Stroke or TIA History",
            modifierId: "stroke_history",
            weight: 3,
            description: "Prior stroke or transient ischemic attack increases risk of recurrence.",
            category: .cardiovascular
        ),
        ConditionEntry(
            conditionId: "blood_clotting_disorder",
            displayName: "Blood Clotting Disorder",
            modifierId: "blood_clotting_disorder",
            weight: 3,
            description: "Includes clotting and bleeding disorders. Affects response to injury and bleeding symptoms.",
            category: .cardiovascular
        ),
    ]

    // MARK: - Metabolic

    static let metabolic: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "diabetic_type1",
            displayName: "Diabetes (Type 1)",
            modifierId: "diabetic",
            weight: 3,
            description: "Insulin-dependent diabetes. Affects blood sugar regulation and wound healing.",
            category: .metabolic
        ),
        ConditionEntry(
            conditionId: "diabetic_type2",
            displayName: "Diabetes (Type 2)",
            modifierId: "diabetic",
            weight: 3,
            description: "Non-insulin-dependent diabetes. Affects immune response and symptom presentation.",
            category: .metabolic
        ),
    ]

    // MARK: - Respiratory

    static let respiratory: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "asthma",
            displayName: "Asthma",
            modifierId: "asthma",
            weight: 2,
            description: "Chronic airway condition that can escalate respiratory symptoms rapidly.",
            category: .respiratory
        ),
        ConditionEntry(
            conditionId: "copd",
            displayName: "COPD",
            modifierId: "copd",
            weight: 3,
            description: "Chronic obstructive pulmonary disease. Reduces baseline respiratory reserve.",
            category: .respiratory
        ),
        ConditionEntry(
            conditionId: "chronic_lung_other",
            displayName: "Chronic Lung Condition (Other)",
            modifierId: "chronic_lung_other",
            weight: 2,
            description: "Any other diagnosed chronic lung condition not listed above.",
            category: .respiratory
        ),
    ]

    // MARK: - Immune System

    static let immune: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "immunocompromised_cancer",
            displayName: "Immunocompromised — Cancer Treatment",
            modifierId: "immunocompromised",
            weight: 4,
            description: "Currently receiving chemotherapy, radiation, or other cancer-related immunosuppressive treatment.",
            category: .immune,
            isImmunoSubtype: true
        ),
        ConditionEntry(
            conditionId: "immunocompromised_hiv",
            displayName: "Immunocompromised — HIV or AIDS",
            modifierId: "immunocompromised",
            weight: 4,
            description: "Living with HIV or AIDS with reduced immune function.",
            category: .immune,
            isImmunoSubtype: true
        ),
        ConditionEntry(
            conditionId: "immunocompromised_transplant",
            displayName: "Immunocompromised — Organ Transplant",
            modifierId: "immunocompromised",
            weight: 4,
            description: "Taking immunosuppressant drugs following an organ or bone marrow transplant.",
            category: .immune,
            isImmunoSubtype: true
        ),
        ConditionEntry(
            conditionId: "immunocompromised_steroids",
            displayName: "Immunocompromised — Long-term Steroid Use",
            modifierId: "immunocompromised",
            weight: 4,
            description: "On long-term oral corticosteroids (prednisone, dexamethasone) for any condition.",
            category: .immune,
            isImmunoSubtype: true
        ),
        ConditionEntry(
            conditionId: "autoimmune",
            displayName: "Autoimmune Condition",
            modifierId: "autoimmune",
            weight: 2,
            description: "Includes lupus, rheumatoid arthritis, multiple sclerosis, or other diagnosed autoimmune disease.",
            category: .immune
        ),
    ]

    // MARK: - Reproductive

    static let reproductive: [ConditionEntry] = [
        // Trimester stages (shown inline under Pregnancy toggle)
        ConditionEntry(
            conditionId: "pregnant_t1",
            displayName: "Pregnancy — First Trimester",
            modifierId: "pregnant_t1",
            weight: 3,
            description: "Weeks 1–12. Risk of ectopic pregnancy and miscarriage; medications require extra caution.",
            category: .reproductive,
            isPregnancyStage: true
        ),
        ConditionEntry(
            conditionId: "pregnant_t2",
            displayName: "Pregnancy — Second Trimester",
            modifierId: "pregnant_t2",
            weight: 3,
            description: "Weeks 13–26. Preeclampsia and preterm labor signs begin to apply.",
            category: .reproductive,
            isPregnancyStage: true
        ),
        ConditionEntry(
            conditionId: "pregnant_t3",
            displayName: "Pregnancy — Third Trimester",
            modifierId: "pregnant_t3",
            weight: 5,
            description: "Weeks 27–40. Highest risk period — preeclampsia, placental abruption, preterm labor.",
            category: .reproductive,
            isPregnancyStage: true
        ),
        ConditionEntry(
            conditionId: "postpartum",
            displayName: "Postpartum (within 6 weeks of delivery)",
            modifierId: "postpartum",
            weight: 4,
            description: "Elevated risk for hemorrhage, blood clots, postpartum preeclampsia, and infection.",
            category: .reproductive,
            isPregnancyStage: true
        ),
        ConditionEntry(
            conditionId: "pregnant_unknown",
            displayName: "Pregnancy — Trimester Unknown",
            modifierId: "pregnant",
            weight: 3,
            description: "Pregnancy confirmed but trimester not known.",
            category: .reproductive,
            isPregnancyStage: true
        ),
        // Risk factors (shown nested under Pregnancy, after trimester selection)
        ConditionEntry(
            conditionId: "first_pregnancy",
            displayName: "First pregnancy",
            modifierId: "first_pregnancy",
            weight: 2,
            description: "First-time pregnancies carry a higher baseline risk for preeclampsia.",
            category: .reproductive,
            isPregnancyRisk: true
        ),
        ConditionEntry(
            conditionId: "preeclampsia_history",
            displayName: "History of preeclampsia",
            modifierId: "preeclampsia_history",
            weight: 4,
            description: "Prior preeclampsia carries a 20–25% recurrence risk. Single warning symptoms warrant immediate evaluation.",
            category: .reproductive,
            isPregnancyRisk: true
        ),
        ConditionEntry(
            conditionId: "multiple_gestation",
            displayName: "Twins or multiple pregnancy",
            modifierId: "multiple_gestation",
            weight: 3,
            description: "Multiple gestation significantly increases preeclampsia risk and maternal complications.",
            category: .reproductive,
            isPregnancyRisk: true
        ),
        ConditionEntry(
            conditionId: "advanced_maternal_age",
            displayName: "Pregnancy age 35 or older",
            modifierId: "advanced_maternal_age",
            weight: 2,
            description: "Advanced maternal age increases risk of preeclampsia and other complications. Auto-detected from profile if age is known.",
            category: .reproductive,
            isPregnancyRisk: true
        ),
    ]

    // MARK: - Neurological

    static let neurological: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "epilepsy",
            displayName: "Epilepsy or Seizure Disorder",
            modifierId: "epilepsy",
            weight: 2,
            description: "Known seizure disorder. Seizures in this context may differ from new-onset events.",
            category: .neurological
        ),
        ConditionEntry(
            conditionId: "dementia",
            displayName: "Dementia or Alzheimer's",
            modifierId: "dementia",
            weight: 4,
            description: "Cognitive impairment affects symptom reporting and baseline mental status assessment.",
            category: .neurological
        ),
        ConditionEntry(
            conditionId: "brain_injury",
            displayName: "History of Brain Injury",
            modifierId: "brain_injury",
            weight: 2,
            description: "Prior traumatic brain injury affects neurological baseline and symptom interpretation.",
            category: .neurological
        ),
    ]

    // MARK: - Organ Function

    static let organFunction: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "kidney_disease",
            displayName: "Kidney Disease",
            modifierId: "kidney_disease",
            weight: 2,
            description: "Chronic kidney disease affects medication processing and fluid balance.",
            category: .organFunction
        ),
        ConditionEntry(
            conditionId: "liver_disease",
            displayName: "Liver Disease",
            modifierId: "liver_disease",
            weight: 2,
            description: "Affects medication metabolism and increases bleeding risk.",
            category: .organFunction
        ),
        ConditionEntry(
            conditionId: "adrenal_insufficiency",
            displayName: "Adrenal Insufficiency",
            modifierId: "adrenal_insufficiency",
            weight: 3,
            description: "Addison's disease or secondary adrenal insufficiency. Stress events can trigger adrenal crisis.",
            category: .organFunction
        ),
    ]

    // MARK: - Mental Health

    static let mentalHealth: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "mental_health_condition",
            displayName: "Severe Mental Health Condition",
            modifierId: "mental_health_condition",
            weight: 2,
            description: "Includes schizophrenia, bipolar disorder, or severe depression. May affect symptom reporting and instruction-following.",
            category: .mentalHealth
        ),
    ]

    // MARK: - Other

    static let other: [ConditionEntry] = [
        ConditionEntry(
            conditionId: "obesity_severe",
            displayName: "Obesity (BMI over 40)",
            modifierId: "obesity_severe",
            weight: 2,
            description: "Severe obesity increases risk of complications for many conditions and affects medication dosing.",
            category: .other
        ),
        ConditionEntry(
            conditionId: "cancer_active",
            displayName: "Cancer (Active)",
            modifierId: "cancer_active",
            weight: 3,
            description: "Active cancer diagnosis, whether or not currently in treatment.",
            category: .other
        ),
    ]

    // MARK: - Lookup

    static func entry(for conditionId: String) -> ConditionEntry? {
        all.first { $0.conditionId == conditionId }
    }

    // MARK: - Grouped Access

    // Returns conditions grouped by category, excluding pregnancy stages/risks (handled inline by toggle VM)
    static var groups: [ConditionCategory: [ConditionEntry]] {
        Dictionary(grouping: all.filter { !$0.isPregnancyStage && !$0.isPregnancyRisk }) { $0.category }
    }

    static let pregnancyStages: [ConditionEntry] = all.filter { $0.isPregnancyStage }
    static let pregnancyRisks:  [ConditionEntry] = all.filter { $0.isPregnancyRisk }
    static let immunoSubtypes:  [ConditionEntry] = all.filter { $0.isImmunoSubtype }
}
