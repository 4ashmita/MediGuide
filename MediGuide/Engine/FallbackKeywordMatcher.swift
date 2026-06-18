import Foundation

enum FallbackKeywordMatcher {

    static func match(text: String, treeData: DecisionTreeData) -> LLMResponseParser.ParsedSymptoms {
        let lower = text.lowercased()
        let knownSymptoms = Set(treeData.symptomWeights.keys)
        let knownModifiers = Set(treeData.modifierWeights.keys)
        let hardOverrides = Set(treeData.hardOverrides)

        let matchedSymptomIds = symptomKeywords.compactMap { id, keywords -> String? in
            knownSymptoms.contains(id) && keywords.contains(where: { lower.contains($0) }) ? id : nil
        }
        let matchedModifierIds = modifierKeywords.compactMap { id, keywords -> String? in
            knownModifiers.contains(id) && keywords.contains(where: { lower.contains($0) }) ? id : nil
        }

        let symptoms = matchedSymptomIds.compactMap { id -> Symptom? in
            guard let w = treeData.symptomWeights[id] else { return nil }
            return Symptom(symptomId: id, weight: w)
        }
        let modifiers = matchedModifierIds.compactMap { id -> Modifier? in
            guard let w = treeData.modifierWeights[id] else { return nil }
            return Modifier(modifierId: id, weight: w)
        }

        let hardOverrideDetected = symptoms.contains { hardOverrides.contains($0.symptomId) }
        let uncertain = symptoms.isEmpty

        let summary: String
        if uncertain {
            summary = "No specific symptoms identified in offline mode. Consider switching to guided questions."
        } else {
            let names = symptoms.map { SymptomReferenceProvider.description(for: $0.symptomId) }.joined(separator: ", ")
            summary = "Offline match identified: \(names)."
        }

        return LLMResponseParser.ParsedSymptoms(
            symptoms: symptoms,
            modifiers: modifiers,
            hardOverrideDetected: hardOverrideDetected,
            uncertain: uncertain,
            summary: summary
        )
    }

    // MARK: - Symptom keyword maps

    private static let symptomKeywords: [String: [String]] = [
        "barking_cough": [
            "barking cough", "croup", "seal cough", "seal-like cough", "barks when coughing",
        ],
        "baseline_function_decline": [
            "can't do what they normally", "decline in function", "less capable",
            "not themselves functionally", "not functioning normally",
        ],
        "blue_lips": [
            "blue lips", "blue skin", "purple lips", "gray lips", "cyanosis",
            "lips turned blue", "face turned blue", "bluish",
        ],
        "chest_pain": [
            "chest pain", "chest pressure", "chest tightness", "chest discomfort",
            "pain in chest", "pressure in chest", "tight chest", "squeezing chest",
            "heart pain", "chest hurts", "clutching chest", "grabbing chest",
        ],
        "confusion": [
            "confused", "confusion", "disoriented", "doesn't know where",
            "doesn't know what day", "altered mental", "not making sense",
            "making no sense", "incoherent", "not oriented",
        ],
        "decreased_appetite_elderly": [
            "not eating", "won't eat", "refusing to eat", "not drinking",
            "not eating or drinking",
        ],
        "dehydration_signs_elderly": [
            "dehydrated", "dry mouth", "dark urine", "not urinating",
            "very thirsty", "sunken eyes", "signs of dehydration",
        ],
        "difficulty_breathing": [
            "can't breathe", "cannot breathe", "trouble breathing", "difficulty breathing",
            "hard to breathe", "struggling to breathe", "shortness of breath",
            "out of breath", "gasping", "can't catch breath", "can't get air",
            "not breathing well", "breathing is difficult", "breathing problems",
        ],
        "dizziness": [
            "dizzy", "dizziness", "lightheaded", "light-headed", "faint",
            "spinning", "vertigo", "woozy", "unsteady", "feeling faint",
        ],
        "fall_no_injury": [
            "fell", "fall", "fallen", "tripped", "slipped", "no injury",
            "not hurt but fell",
        ],
        "fall_unable_to_get_up": [
            "can't get up", "cannot get up", "unable to get up", "stuck on floor",
            "can't stand", "on the floor and can't move", "can't rise from floor",
        ],
        "fall_with_injury": [
            "fell and hurt", "fall with injury", "fell and cut", "fell and broke",
            "injury from fall", "hurt from falling", "fell and injured",
        ],
        "fatigue_elderly": [
            "very tired elderly", "exhausted elderly", "extreme fatigue elderly",
            "elderly weak", "no energy elderly", "unusual tiredness elderly",
        ],
        "high_fever": [
            "high fever", "fever over 103", "103 degrees", "104 degrees",
            "105 degrees", "very high temperature", "burning up with fever",
            "extremely high fever",
        ],
        "high_fever_infant": [
            "fever in newborn", "baby has fever", "infant fever", "newborn fever",
            "baby temperature", "fever in baby under 3 months",
        ],
        "hives_sudden": [
            "hives", "allergic rash", "breakout", "broke out in rash",
            "welts", "itchy rash", "raised rash", "allergic skin reaction",
        ],
        "inconsolable_crying": [
            "won't stop crying", "can't stop crying", "crying for hours",
            "inconsolable", "crying nonstop", "crying for 3 hours", "crying for three hours",
            "baby crying uncontrollably",
        ],
        "insect_sting": [
            "bee sting", "wasp sting", "stung by bee", "stung by wasp",
            "hornet sting", "insect sting", "got stung", "stung by insect",
        ],
        "lethargy_infant": [
            "won't wake up baby", "hard to wake baby", "baby won't respond",
            "very drowsy baby", "limp baby", "baby not responding",
            "baby won't open eyes", "extremely drowsy infant",
        ],
        "low_oxygen": [
            "low oxygen", "oxygen reading", "pulse ox", "oxygen level",
            "spo2", "o2 saturation", "oxygen below 95", "oxygen below 92",
        ],
        "medication_side_effect": [
            "side effect", "reaction to medication", "medication reaction",
            "adverse reaction", "drug reaction", "medicine reaction",
        ],
        "mild_headache": [
            "mild headache", "slight headache", "head hurts a little",
            "minor headache", "small headache", "dull headache",
        ],
        "nausea": [
            "nausea", "nauseated", "feel sick", "stomach upset", "vomiting",
            "throwing up", "vomited", "puking", "queasy", "sick to stomach",
        ],
        "new_weakness_one_side": [
            "weakness on one side", "arm won't move", "leg won't move",
            "one side weak", "numb on one side", "can't lift arm",
            "one sided weakness", "paralysis on one side",
        ],
        "rapid_heartrate": [
            "heart racing", "rapid heart", "fast heartbeat", "pounding heart",
            "palpitations", "heart pounding", "heart is racing",
            "heart going fast", "heart fluttering", "heartbeat fast",
            "heart going crazy",
        ],
        "rash_with_fever_child": [
            "rash and fever", "fever and rash", "child has rash",
            "spots and fever", "rash with temperature", "fever with spots",
        ],
        "refusing_to_eat_infant": [
            "baby won't eat", "infant refuses to feed", "won't nurse",
            "won't feed", "baby not eating", "baby refusing bottle",
            "won't breastfeed",
        ],
        "seizure": [
            "seizure", "convulsion", "convulsing", "shaking uncontrollably",
            "having a fit", "epileptic episode", "grand mal",
            "twitching all over", "uncontrolled shaking",
        ],
        "severe_allergic_reaction": [
            "anaphylaxis", "anaphylactic", "severe allergic",
            "throat swelling", "throat closing", "anaphylactic shock",
        ],
        "severe_bleeding": [
            "severe bleeding", "uncontrolled bleeding", "can't stop bleeding",
            "bleeding a lot", "heavy bleeding", "blood won't stop",
            "massive bleeding",
        ],
        "severe_headache": [
            "worst headache", "thunderclap headache", "sudden severe headache",
            "worst headache of my life", "excruciating headache",
            "splitting headache came out of nowhere",
        ],
        "soft_spot_bulging": [
            "soft spot bulging", "fontanelle bulging", "bulging soft spot",
            "baby's head bulging", "fontanel pushing out",
        ],
        "stroke_symptoms": [
            "stroke", "face drooping", "face droop", "arm weakness",
            "slurred speech", "sudden numbness", "facial droop",
            "can't speak properly", "face not moving normally",
        ],
        "sudden_confusion_elderly": [
            "suddenly confused", "suddenly disoriented", "new confusion",
            "onset of confusion", "confused out of nowhere",
            "elderly person confused suddenly",
        ],
        "sudden_nausea_late_pregnancy": [
            "nausea late pregnancy", "nausea third trimester",
            "sudden nausea pregnant", "vomiting third trimester",
        ],
        "sudden_shortness_of_breath": [
            "sudden shortness of breath", "suddenly can't breathe",
            "out of nowhere can't breathe", "sudden breathing problem",
            "breathing suddenly difficult",
        ],
        "swelling_sudden": [
            "sudden swelling", "swollen leg", "swollen arm", "swollen face",
            "sudden puffiness", "leg swelled up", "face swelled",
        ],
        "throat_tightening": [
            "throat tightening", "throat closing", "throat swelling",
            "can't swallow", "throat feels tight", "difficulty swallowing",
            "throat closing up",
        ],
        "unconscious": [
            "unconscious", "unresponsive", "won't wake up", "can't wake",
            "passed out", "not responding", "no response", "out cold",
        ],
        "upper_abdominal_pain_right": [
            "upper right pain", "right abdominal pain", "pain under ribs",
            "gallbladder pain", "right side upper pain",
        ],
        "urinary_symptoms_elderly": [
            "pain when urinating", "burning urination", "frequent urination",
            "urinary pain", "uti symptoms", "bladder pain", "burning when peeing",
        ],
        "vision_changes": [
            "vision changes", "blurry vision", "double vision",
            "can't see clearly", "vision loss", "sudden blindness", "seeing double",
        ],
        "vomiting_infant": [
            "baby vomiting", "infant throwing up", "baby throwing up",
            "baby keeps vomiting", "projectile vomiting baby",
        ],
        "wheezing": [
            "wheezing", "whistling when breathing", "breath sounds wheezy",
            "wheeze", "squeaky breathing", "noisy breathing",
        ],
    ]

    // MARK: - Modifier keyword maps

    // State-change descriptors (getting worse, getting better, worsening, improving) are intentionally
    // excluded. Simple substring matching cannot distinguish "getting worse" from "not getting worse,
    // actually getting better" — a contains check on "getting worse" matches both. The API handles
    // these correctly via semantic understanding; the fallback omits them to avoid false positives.
    private static let modifierKeywords: [String: [String]] = [
        "age_over_65": [
            "elderly", "senior", "65 years", "70 years", "75 years",
            "80 years", "85 years", "90 years", "old person", "older adult",
        ],
        "age_under_2": [
            "infant", "baby", "newborn", "1 year old", "8 months",
            "6 months", "3 months", "toddler",
        ],
        "asthma": ["asthma", "asthmatic", "has asthma", "uses inhaler", "inhaler"],
        "copd": ["copd", "emphysema", "chronic obstructive", "chronic lung disease"],
        "diabetic": ["diabetic", "diabetes", "has diabetes", "blood sugar", "insulin"],
        "heart_condition": [
            "heart condition", "heart disease", "heart failure",
            "cardiac", "heart problems", "pacemaker", "stent",
        ],
        "pregnant": ["pregnant", "pregnancy", "expecting a baby", "with child"],
        "pregnant_t3": [
            "third trimester", "8 months pregnant", "9 months pregnant",
            "due soon", "late pregnancy",
        ],
        "immunocompromised": [
            "immune compromised", "immunocompromised", "weak immune system",
            "chemotherapy", "immune suppressed",
        ],
        "cancer_active": [
            "cancer", "tumor", "malignancy", "oncology",
            "chemotherapy", "radiation treatment",
        ],
        "epilepsy": ["epilepsy", "epileptic", "seizure disorder", "known seizures"],
        "sudden_onset": [
            "came on suddenly", "out of nowhere", "all of a sudden",
            "just started suddenly", "happened all at once",
        ],
        "instinct_override": [
            "something feels wrong", "something is wrong",
            "doesn't seem right", "feels off", "very worried about",
        ],
    ]
}
