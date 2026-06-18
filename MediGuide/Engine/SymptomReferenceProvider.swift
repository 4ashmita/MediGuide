import Foundation

enum SymptomReferenceProvider {

    static func description(for symptomId: String) -> String {
        symptomDescriptions[symptomId] ?? symptomId.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func modifierDescription(for modifierId: String) -> String {
        modifierDescriptions[modifierId] ?? modifierId.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func format(treeData: DecisionTreeData) -> String {
        let hardOverrides = Set(treeData.hardOverrides)

        let symptomLines = treeData.symptomWeights.keys.sorted().map { id -> String in
            let desc = symptomDescriptions[id] ?? id.replacingOccurrences(of: "_", with: " ")
            let flag = hardOverrides.contains(id) ? " ⚠️ HARD OVERRIDE" : ""
            return "- \(id): \(desc)\(flag)"
        }.joined(separator: "\n")

        let modifierLines = treeData.modifierWeights.keys.sorted().map { id -> String in
            let desc = modifierDescriptions[id] ?? id.replacingOccurrences(of: "_", with: " ")
            return "- \(id): \(desc)"
        }.joined(separator: "\n")

        let overrideList = treeData.hardOverrides.joined(separator: ", ")

        return """
        SYMPTOMS — use only these exact IDs:
        \(symptomLines)

        HARD OVERRIDE IDs — if any of these are present, set hard_override_detected to true:
        \(overrideList)

        MODIFIERS — use only these exact IDs:
        \(modifierLines)
        """
    }

    // MARK: - Symptom descriptions

    private static let symptomDescriptions: [String: String] = [
        "barking_cough":                 "Barking or seal-like cough (croup) in a child",
        "baseline_function_decline":     "Decline in elderly person's ability to perform normal daily activities",
        "blue_lips":                     "Blue, purple, or gray coloration of lips or skin",
        "chest_pain":                    "Pain, pressure, tightness, or discomfort in the chest",
        "confusion":                     "Confusion, disorientation, or altered mental status",
        "decreased_appetite_elderly":    "Elderly person not eating, drinking, or responding normally",
        "dehydration_signs_elderly":     "Signs of dehydration in elderly person — dry mouth, dark urine, confusion",
        "difficulty_breathing":          "Unable to breathe normally, very short of breath, gasping",
        "dizziness":                     "Dizziness, lightheadedness, or feeling faint",
        "fall_no_injury":                "Fall without apparent injury but concerning for an elderly person",
        "fall_unable_to_get_up":         "Fall where person cannot get up from the floor",
        "fall_with_injury":              "Fall resulting in injury such as a cut or possible fracture",
        "fatigue_elderly":               "Unusual or new fatigue or weakness in an elderly person",
        "high_fever":                    "High fever above 103°F (39.5°C)",
        "high_fever_infant":             "Any fever in a newborn or infant under 3 months old",
        "hives_sudden":                  "Sudden outbreak of hives or an allergic skin rash",
        "inconsolable_crying":           "Baby crying inconsolably for more than 3 hours",
        "insect_sting":                  "Insect sting from bee, wasp, or similar insect",
        "lethargy_infant":               "Baby very hard to wake, not responding normally, limp or excessively drowsy",
        "low_oxygen":                    "Low oxygen reading below 95% on a pulse oximeter",
        "medication_side_effect":        "Suspected adverse reaction or side effect from medication",
        "mild_headache":                 "Mild headache without sudden onset or severe intensity",
        "nausea":                        "Nausea, vomiting, or stomach upset",
        "new_weakness_one_side":         "Sudden new weakness or numbness on one side of the body",
        "rapid_heartrate":               "Heart racing, pounding, or palpitations",
        "rash_with_fever_child":         "Rash appearing alongside fever in a child",
        "refusing_to_eat_infant":        "Infant refusing to feed, nurse, or drink",
        "seizure":                       "Convulsions, uncontrolled shaking, or a seizure episode",
        "severe_allergic_reaction":      "Severe allergic reaction with throat tightening or widespread hives — anaphylaxis",
        "severe_bleeding":               "Severe or uncontrolled bleeding that cannot be stopped with pressure",
        "severe_headache":               "Sudden severe or worst-ever headache — thunderclap headache",
        "soft_spot_bulging":             "Bulging fontanelle — soft spot on baby's head is pushing outward",
        "stroke_symptoms":               "Face drooping, arm weakness, slurred speech, sudden numbness on one side",
        "sudden_confusion_elderly":      "Sudden or new-onset confusion in elderly person, different from their normal baseline",
        "sudden_nausea_late_pregnancy":  "Sudden nausea in late pregnancy — possible sign of preeclampsia",
        "sudden_shortness_of_breath":    "Sudden shortness of breath with no prior breathing problems",
        "swelling_sudden":               "Sudden swelling of a leg, arm, or face",
        "throat_tightening":             "Throat tightening or swelling, difficulty swallowing — possible anaphylaxis",
        "unconscious":                   "Unconscious, unresponsive, cannot be woken up",
        "upper_abdominal_pain_right":    "Pain in the upper right abdomen — possible gallbladder issue",
        "urinary_symptoms_elderly":      "Urinary pain, burning, frequency, or urgency in an elderly person",
        "vision_changes":                "Sudden vision changes, blurring, double vision, or loss of vision",
        "vomiting_infant":               "Infant vomiting repeatedly",
        "wheezing":                      "Wheezing or whistling sound when breathing, breathing difficulty in a child",
    ]

    // MARK: - Modifier descriptions

    private static let modifierDescriptions: [String: String] = [
        "adrenal_insufficiency":    "Person has adrenal insufficiency or Addison's disease",
        "advanced_maternal_age":    "Pregnant person is 35 years or older",
        "age_over_65":              "Person is 65 years of age or older",
        "age_under_2":              "Person is an infant under 2 years old",
        "anaphylactic_allergy":     "Person has a known anaphylactic allergy",
        "asthma":                   "Person has asthma",
        "autoimmune":               "Person has an autoimmune condition",
        "baseline_change":          "Elderly person is acting differently from their normal baseline behavior",
        "blood_clotting_disorder":  "Person has a blood clotting disorder",
        "brain_injury":             "Person has a history of traumatic brain injury",
        "cancer_active":            "Person has active cancer — currently in treatment or recently diagnosed",
        "copd":                     "Person has COPD or other chronic obstructive lung disease",
        "dementia":                 "Person has dementia or significant cognitive impairment",
        "diabetic":                 "Person has diabetes",
        "epilepsy":                 "Person has epilepsy or a known seizure disorder",
        "first_pregnancy":          "This is the person's first pregnancy",
        "frail":                    "Person is frail or has significantly reduced physical reserves",
        "getting_worse":            "Symptoms are getting progressively worse over time",
        "heart_condition":          "Person has a diagnosed heart condition",
        "high_blood_pressure":      "Person has hypertension or high blood pressure",
        "history_of_falls":         "Elderly person has a documented history of falls",
        "immunocompromised":        "Person has a weakened or suppressed immune system",
        "insect_allergy":           "Person has a known allergy to insect stings",
        "instinct_override":        "Something feels seriously wrong even if specific symptoms are unclear",
        "kidney_disease":           "Person has kidney disease or renal insufficiency",
        "liver_disease":            "Person has liver disease",
        "lives_alone":              "Elderly person lives alone",
        "medication_nonadherence":  "Person has missed medication doses recently",
        "mental_health_condition":  "Person has a mental health condition",
        "multiple_gestation":       "Person is pregnant with twins, triplets, or more",
        "multiple_medications":     "Person takes multiple medications regularly — polypharmacy",
        "new_medication":           "Person recently started a new medication",
        "obesity_severe":           "Person has severe obesity (BMI 40 or higher)",
        "postpartum":               "Person recently gave birth — postpartum period",
        "pregnant":                 "Person is pregnant (any trimester)",
        "pregnant_t1":              "Person is in the first trimester of pregnancy",
        "pregnant_t2":              "Person is in the second trimester of pregnancy",
        "pregnant_t3":              "Person is in the third trimester of pregnancy",
        "preeclampsia_history":     "Person has a history of preeclampsia in a previous pregnancy",
        "recent_hospitalization":   "Person was recently discharged from the hospital",
        "recent_medication_change": "Person's medications were recently changed or adjusted",
        "severe_allergy":           "Person has known severe allergies",
        "stroke_history":           "Person has a prior history of stroke or TIA",
        "sudden_onset":             "Symptoms came on suddenly within minutes",
        "symptoms_not_improving":   "Symptoms are not improving despite time or home treatment",
        "symptoms_worsening":       "Symptoms are progressively worsening over time",
        "chronic_lung_other":       "Person has a chronic lung condition other than asthma or COPD",
    ]
}
