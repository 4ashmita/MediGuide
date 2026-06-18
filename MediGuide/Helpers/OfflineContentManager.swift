import Foundation

enum OfflineContentManager {

    enum ContentError: Error {
        case missingFile(String)
        case malformed(String)
    }

    private static let requiredBundleFiles: [(name: String, ext: String)] = [
        ("DecisionTree",    "json"),
        ("FirstAidContent", "json"),
        ("WarningSignsData","json"),
    ]

    // Returns nil if all required content is present, or an error describing the first missing file.
    static func verifyContent() -> ContentError? {
        for file in requiredBundleFiles {
            guard let url = Bundle.main.url(forResource: file.name, withExtension: file.ext) else {
                return .missingFile("\(file.name).\(file.ext)")
            }
            guard (try? Data(contentsOf: url)) != nil else {
                return .malformed("\(file.name).\(file.ext)")
            }
        }
        return nil
    }

    static var isAllContentAvailable: Bool {
        verifyContent() == nil
    }
}
