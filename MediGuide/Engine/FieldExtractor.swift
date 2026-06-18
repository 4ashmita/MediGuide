import Foundation

/// Safe, typed field access on a parsed JSON dictionary.
/// Required accessors treat an absent or wrong-typed field as a reportable error.
/// Optional accessors return a defined default and never crash.
enum FieldExtractor {

    enum FieldError: Error {
        case missing(key: String)
        case wrongType(key: String, expected: String)
    }

    // MARK: - Required fields

    static func requiredString(_ key: String, from dict: [String: Any]) -> Result<String, FieldError> {
        guard let raw = dict[key] else { return .failure(.missing(key: key)) }
        guard let value = raw as? String else { return .failure(.wrongType(key: key, expected: "String")) }
        return .success(value)
    }

    static func requiredBool(_ key: String, from dict: [String: Any]) -> Result<Bool, FieldError> {
        guard let raw = dict[key] else { return .failure(.missing(key: key)) }
        guard let value = raw as? Bool else { return .failure(.wrongType(key: key, expected: "Bool")) }
        return .success(value)
    }

    static func requiredStringArray(_ key: String, from dict: [String: Any]) -> Result<[String], FieldError> {
        guard let raw = dict[key] else { return .failure(.missing(key: key)) }
        guard let value = raw as? [String] else { return .failure(.wrongType(key: key, expected: "[String]")) }
        return .success(value)
    }

    static func requiredObjectArray(_ key: String, from dict: [String: Any]) -> Result<[[String: Any]], FieldError> {
        guard let raw = dict[key] else { return .failure(.missing(key: key)) }
        guard let value = raw as? [[String: Any]] else { return .failure(.wrongType(key: key, expected: "[[String: Any]]")) }
        return .success(value)
    }

    // MARK: - Optional fields

    static func optionalString(_ key: String, from dict: [String: Any], default fallback: String = "") -> String {
        (dict[key] as? String) ?? fallback
    }

    static func optionalBool(_ key: String, from dict: [String: Any], default fallback: Bool = false) -> Bool {
        (dict[key] as? Bool) ?? fallback
    }

    static func optionalStringArray(_ key: String, from dict: [String: Any]) -> [String] {
        (dict[key] as? [String]) ?? []
    }

    static func optionalObjectArray(_ key: String, from dict: [String: Any]) -> [[String: Any]] {
        (dict[key] as? [[String: Any]]) ?? []
    }
}
