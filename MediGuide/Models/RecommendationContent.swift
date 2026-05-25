import Foundation

struct TierContent {
    let explanation: String
    let actionMessage: String
    let timeSensitivity: String
    let firstAidSteps: [String]
    let whatToBring: [String]
    let whatToExpect: String
    let reassessmentMinutes: Int?
}

enum RecommendationContent {
    static func content(for tier: RecommendationTier) -> TierContent {
        switch tier {
        case .call911:
            return TierContent(
                explanation: "Based on the symptoms described, this could be a life-threatening emergency requiring immediate medical attention.",
                actionMessage: "Call 911 immediately. Do not drive yourself or the person to the hospital.",
                timeSensitivity: "Every second counts. Call now.",
                firstAidSteps: [
                    "Call 911 and stay on the line with the dispatcher",
                    "Tell them your exact location, what happened, and current symptoms",
                    "Keep the person calm, still, and warm",
                    "Do not give food or water",
                    "Apply firm pressure to any severe bleeding and do not remove",
                    "If the person stops breathing, begin CPR if you are trained",
                    "Unlock the front door so paramedics can enter",
                    "Note the time symptoms started — tell paramedics immediately"
                ],
                whatToBring: [
                    "Medication list or pill bottles",
                    "Photo ID and insurance card if time allows",
                    "Do not delay calling 911 to gather items"
                ],
                whatToExpect: "Paramedics will assess vitals, may start IV, and begin treatment on scene. They will transport to the nearest appropriate facility.",
                reassessmentMinutes: nil
            )

        case .goToER:
            return TierContent(
                explanation: "These symptoms need emergency department evaluation. Do not wait, but if you can get there safely you may drive rather than calling 911.",
                actionMessage: "Go to the nearest emergency room now. If symptoms worsen on the way, pull over and call 911.",
                timeSensitivity: "Go now. Do not wait to see if symptoms improve.",
                firstAidSteps: [
                    "Keep the person as comfortable as possible",
                    "Do not give food or water unless instructed by a medical professional",
                    "If driving, have someone else drive if at all possible",
                    "Bring a list of current medications and any known allergies",
                    "If symptoms worsen significantly on the way, pull over and call 911"
                ],
                whatToBring: [
                    "Photo ID and insurance card",
                    "List of current medications and doses",
                    "List of known allergies",
                    "Recent medical records if available",
                    "Emergency contact information"
                ],
                whatToExpect: "The ER will assess vitals, likely perform blood work and imaging, and monitor for changes. Wait times vary but serious symptoms are prioritized.",
                reassessmentMinutes: 15
            )

        case .urgentCare:
            return TierContent(
                explanation: "These symptoms need medical evaluation soon but are not an immediate emergency. Urgent care or a same-day doctor appointment is appropriate.",
                actionMessage: "Go to urgent care within the next few hours. If symptoms worsen significantly before then, go to the ER instead.",
                timeSensitivity: "Seek care within a few hours. Do not wait overnight.",
                firstAidSteps: [
                    "Rest and avoid strenuous activity",
                    "Stay hydrated — water or clear fluids",
                    "Over-the-counter pain relief is appropriate if no contraindications",
                    "Apply ice wrapped in cloth for injuries — 20 minutes on, 20 minutes off",
                    "Elevate an injured limb above heart level if possible",
                    "Monitor temperature if fever is present"
                ],
                whatToBring: [
                    "Photo ID and insurance card",
                    "List of current medications",
                    "Description of when symptoms started and how they have changed"
                ],
                whatToExpect: "Urgent care can handle stitches, x-rays, basic lab work, and write prescriptions. Most visits are completed within 1-2 hours.",
                reassessmentMinutes: 60
            )

        case .monitor:
            return TierContent(
                explanation: "Based on current symptoms, this can likely be managed at home with careful monitoring. Watch closely for warning signs that would require medical attention.",
                actionMessage: "Rest at home and monitor symptoms. Seek care immediately if any warning signs develop.",
                timeSensitivity: "Monitor closely over the next few hours.",
                firstAidSteps: [
                    "Rest as needed and avoid overexertion",
                    "Stay well hydrated — water, clear broths, or electrolyte drinks",
                    "Over-the-counter relief is appropriate if no contraindications",
                    "Avoid alcohol and caffeine",
                    "Monitor temperature every few hours if relevant",
                    "Do not hesitate to seek care if you feel something is wrong"
                ],
                whatToBring: [],
                whatToExpect: "Most minor symptoms improve with rest and home care within 24 to 48 hours. If symptoms persist beyond 48 hours, contact your doctor.",
                reassessmentMinutes: 120
            )
        }
    }
}
