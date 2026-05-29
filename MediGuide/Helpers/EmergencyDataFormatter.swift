import Foundation

enum EmergencyDataFormatter {

    // MARK: - SMS (compact single line)

    static func smsMedicationLine(_ medications: [MedicationEntry]) -> String {
        guard !medications.isEmpty else { return "No known medications" }
        let names = medications.map { $0.name }.joined(separator: ", ")
        return "Medications: \(names)"
    }

    // MARK: - Dispatcher screen (verbose, with notes, one per line)

    static func dispatcherMedicationText(_ medications: [MedicationEntry]) -> String {
        guard !medications.isEmpty else { return "No known medications" }
        return medications.map { entry in
            entry.note.isEmpty ? entry.name : "\(entry.name) (\(entry.note))"
        }.joined(separator: "\n")
    }

    // MARK: - Voice readout (natural spoken grammar)

    static func voiceMedicationReadout(_ medications: [MedicationEntry]) -> String {
        guard !medications.isEmpty else { return "No known medications." }
        let names = medications.map { $0.name }
        if names.count == 1 {
            return "Current medication is \(names[0])."
        }
        let allButLast = names.dropLast().joined(separator: ", ")
        return "Current medications are \(allButLast), and \(names.last!)."
    }

    // MARK: - Allergy SMS (compact)

    static func smsAllergyLine(_ allergies: [AllergyEntry]) -> String {
        guard !allergies.isEmpty else { return "No known allergies" }
        let anaphylactic = allergies.filter { $0.severity == .anaphylactic }
        let others = allergies.filter { $0.severity != .anaphylactic }
        var parts: [String] = []
        if !anaphylactic.isEmpty {
            let names = anaphylactic.map { $0.allergen.uppercased() }.joined(separator: ", ")
            parts.append("SEVERE ALLERGY: \(names) (anaphylactic)")
        }
        if !others.isEmpty {
            parts.append("Allergies: \(others.map { $0.allergen }.joined(separator: ", "))")
        }
        let hasEpiPen = allergies.contains { $0.carriesEpiPen && $0.severity >= .severe }
        if hasEpiPen { parts.append("Carries EpiPen") }
        return parts.joined(separator: " | ")
    }

    // MARK: - Allergy dispatcher screen (verbose)

    static func dispatcherAllergyText(_ allergies: [AllergyEntry]) -> String {
        guard !allergies.isEmpty else { return "No known allergies" }
        let anaphylactic = allergies.filter { $0.severity == .anaphylactic }
        let others = allergies.filter { $0.severity != .anaphylactic }
        var lines: [String] = []
        for entry in anaphylactic {
            var line = "⚠️ \(entry.allergen) — anaphylactic"
            if !entry.reactionDescription.isEmpty { line += ", \(entry.reactionDescription)" }
            if entry.carriesEpiPen { line += " [EpiPen available]" }
            lines.append(line)
        }
        for entry in others {
            var line = "\(entry.allergen) (\(entry.severity.displayName))"
            if !entry.reactionDescription.isEmpty { line += " — \(entry.reactionDescription)" }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Allergy voice readout

    static func voiceAllergyReadout(_ allergies: [AllergyEntry]) -> String {
        guard !allergies.isEmpty else { return "No known allergies." }
        var sentences: [String] = []
        let anaphylactic = allergies.filter { $0.severity == .anaphylactic }
        if !anaphylactic.isEmpty {
            let names = anaphylactic.map { $0.allergen }.joined(separator: ", ")
            sentences.append("Critical allergy alert. \(names) causes anaphylaxis.")
        }
        let others = allergies.filter { $0.severity != .anaphylactic }
        if !others.isEmpty {
            let names = others.map { $0.allergen }
            if names.count == 1 {
                sentences.append("Additional allergy to \(names[0]).")
            } else {
                let allButLast = names.dropLast().joined(separator: ", ")
                sentences.append("Additional allergies to \(allButLast), and \(names.last!).")
            }
        }
        let hasEpiPen = allergies.contains { $0.carriesEpiPen && $0.severity >= .severe }
        if hasEpiPen { sentences.append("An EpiPen is available.") }
        return sentences.joined(separator: " ")
    }
}
