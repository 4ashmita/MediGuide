import UIKit

final class VisualSymptomService {

    enum AnalysisError: Error {
        case preprocessing(ImagePreprocessor.ProcessingError)
        case noConnection
        case apiFailure(APIError)
        case parseFailed
    }

    struct AnalysisResult {
        let parsed: VisualSymptomParser.ParsedVisualFindings
    }

    private let treeData: DecisionTreeData

    init(treeData: DecisionTreeData) {
        self.treeData = treeData
    }

    /// Full pipeline: preprocess → validate → send to Claude → parse → return.
    /// The image is never stored. It exists only as a local variable for the duration of this call.
    /// The caller is responsible for calling PhotoPrivacyManager.dispose on their UIImage reference
    /// once this function returns.
    func analyze(image: UIImage) async -> Result<AnalysisResult, AnalysisError> {

        // Step 1 — Preprocess: resize, strip EXIF metadata, validate size
        let processed: ImagePreprocessor.ProcessedImage
        switch ImagePreprocessor.process(image) {
        case .success(let p): processed = p
        case .failure(let e): return .failure(.preprocessing(e))
        }

        // Step 3 — Check connectivity before building the request
        guard NetworkReachabilityMonitor.shared.isReachable else {
            return .failure(.noConnection)
        }

        // Step 4 — Assemble request (RequestBuilder handles base64 encoding internally)
        let request = ClaudeRequest.image(
            system: assembleSystemPrompt(),
            imageData: processed.data,
            mediaType: processed.mediaType,
            userText: "Analyze this photo and identify any visually observable medical symptoms."
        )

        // Step 5 — Send (reuses existing auth, timeout, retry, and logging)
        let apiResult = await ClaudeAPIClient.shared.send(request)

        // Step 6 — Parse response via JSONResponseHandler (schema validation + parsing)
        switch apiResult {
        case .success(let jsonText):
            switch JSONResponseHandler.handleVisual(jsonText, treeData: treeData) {
            case .success(let parsed):
                return .success(AnalysisResult(parsed: parsed))
            case .failure:
                return .failure(.parseFailed)
            }
        case .failure(let error):
            return .failure(.apiFailure(error))
        }
    }

    // MARK: - Private

    private func assembleSystemPrompt() -> String {
        """
        \(VisualPromptTemplate.content)

        ---

        \(VisualSymptomReferenceProvider.format(treeData: treeData))

        ---

        \(VisualOutputSchemaDefinition.formatInstructions())
        """
    }
}
