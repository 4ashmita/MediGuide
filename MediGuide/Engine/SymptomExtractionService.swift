import Foundation

final class SymptomExtractionService {

    enum Source {
        case api, fallback
    }

    struct ExtractionResult {
        let parsed: LLMResponseParser.ParsedSymptoms
        let source: Source
    }

    private let treeData: DecisionTreeData

    init(treeData: DecisionTreeData) {
        self.treeData = treeData
    }

    func extract(from userText: String) async -> ExtractionResult {
        guard NetworkReachabilityMonitor.shared.isReachable else {
            return fallback(for: userText)
        }

        let request = PromptBuilder.build(userText: userText, treeData: treeData)
        let apiResult = await ClaudeAPIClient.shared.send(request)

        switch apiResult {
        case .success(let jsonText):
            if case .success(let parsed) = JSONResponseHandler.handleText(jsonText, treeData: treeData) {
                return ExtractionResult(parsed: parsed, source: .api)
            }
            return fallback(for: userText)
        case .failure:
            return fallback(for: userText)
        }
    }

    private func fallback(for text: String) -> ExtractionResult {
        ExtractionResult(parsed: FallbackKeywordMatcher.match(text: text, treeData: treeData), source: .fallback)
    }
}
