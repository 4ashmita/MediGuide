import Foundation

/// Strips personally identifying information from free-text fields in API responses
/// (summary, plain_description) before those fields are logged or displayed.
/// Uses the same redaction patterns as InputSanitizer, applied to response content.
enum ResponseSanitizer {

    static func sanitize(_ text: String) -> String {
        var result = text
        result = redact(result, pattern: phonePattern,     with: "[number]")
        result = redact(result, pattern: emailPattern,     with: "[email]")
        result = redact(result, pattern: ssnPattern,       with: "[id]")
        result = redact(result, pattern: fullDatePattern,  with: "[date]")
        return result
    }

    // MARK: - Private

    private static func redact(_ text: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: replacement
        )
    }

    private static let phonePattern    = #"(\+?1[\s.\-]?)?\(?\d{3}\)?[\s.\-]?\d{3}[\s.\-]?\d{4}"#
    private static let emailPattern    = #"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"#
    private static let ssnPattern      = #"\b\d{3}-\d{2}-\d{4}\b"#
    private static let fullDatePattern = #"\b\d{1,2}[/\-]\d{1,2}[/\-]\d{4}\b|\b\d{4}[/\-]\d{2}[/\-]\d{2}\b"#
}
