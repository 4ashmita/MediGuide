import Foundation

enum InputSanitizer {
    private static let maxLength = 500

    static func sanitize(_ input: String) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > maxLength {
            text = String(text.prefix(maxLength))
        }
        text = redact(text, pattern: phonePattern,    with: "[number]")
        text = redact(text, pattern: emailPattern,    with: "[email]")
        text = redact(text, pattern: ssnPattern,      with: "[id]")
        text = redact(text, pattern: fullDatePattern, with: "[date]")
        return text
    }

    private static func redact(_ text: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }

    // US phone: (123) 456-7890 / 123-456-7890 / 123.456.7890 / +1 xxx xxx xxxx
    private static let phonePattern = #"(\+?1[\s.\-]?)?\(?\d{3}\)?[\s.\-]?\d{3}[\s.\-]?\d{4}"#

    private static let emailPattern = #"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"#

    // SSN: XXX-XX-XXXX
    private static let ssnPattern = #"\b\d{3}-\d{2}-\d{4}\b"#

    // MM/DD/YYYY, MM-DD-YYYY, YYYY-MM-DD
    private static let fullDatePattern = #"\b\d{1,2}[/\-]\d{1,2}[/\-]\d{4}\b|\b\d{4}[/\-]\d{2}[/\-]\d{2}\b"#
}
