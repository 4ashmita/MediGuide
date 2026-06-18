import Combine
import UIKit

@MainActor
final class PhotoCaptureViewModel: ObservableObject {

    enum Phase {
        case viewfinder
        case permissionDenied
        case reviewing(UIImage)
        case analyzing(UIImage)
        case confirming(VisualSymptomParser.ParsedVisualFindings)
        case manualTagging
    }

    @Published private(set) var phase: Phase = .viewfinder
    @Published private(set) var analysisErrorMessage: String? = nil

    let photoContext: PhotoContext
    private let service: VisualSymptomService
    private let onComplete: ([String]) -> Void  // called with confirmed symptom IDs

    init(
        treeData: DecisionTreeData,
        photoContext: PhotoContext = .general,
        onComplete: @escaping ([String]) -> Void
    ) {
        self.service = VisualSymptomService(treeData: treeData)
        self.photoContext = photoContext
        self.onComplete = onComplete
    }

    // MARK: - State transitions

    func permissionDenied() {
        phase = .permissionDenied
    }

    func photoCaptured(_ image: UIImage) {
        phase = .reviewing(image)
    }

    func retakePhoto() {
        analysisErrorMessage = nil
        phase = .viewfinder
    }

    func usePhoto(_ image: UIImage) {
        analysisErrorMessage = nil
        phase = .analyzing(image)
        Task { await submit(image) }
    }

    func confirmSymptomIds(_ ids: [String]) {
        onComplete(ids)
    }

    func openManualTagging() {
        // Discard any image reference — user is switching to manual selection
        phase = .manualTagging
    }

    // MARK: - Analysis

    private func submit(_ image: UIImage) async {
        let result = await service.analyze(image: image)

        // Discard the image reference immediately after the API call completes,
        // before any other state is updated. A second copy in the caller must be
        // disposed by the caller as documented on VisualSymptomService.analyze.
        var imageRef: UIImage? = image
        PhotoPrivacyManager.dispose(&imageRef)

        switch result {
        case .success(let analysisResult):
            // Only advance to confirming if there's anything to confirm.
            // An empty finding set goes straight to manual tagging.
            if analysisResult.parsed.symptoms.isEmpty && analysisResult.parsed.fullResult.findings.isEmpty {
                analysisErrorMessage = "No visual symptoms could be identified. Please select what you observe."
                phase = .manualTagging
            } else {
                phase = .confirming(analysisResult.parsed)
            }

        case .failure(let error):
            analysisErrorMessage = message(for: error)
            phase = .manualTagging
        }
    }

    // MARK: - Error messaging

    private func message(for error: VisualSymptomService.AnalysisError) -> String {
        switch error {
        case .preprocessing:
            return "The photo could not be processed. Please try a different photo or describe symptoms in words."
        case .noConnection:
            return "No internet connection. Please select what you observe from the list below."
        case .apiFailure:
            return "Analysis service is unavailable. Please select what you observe from the list below."
        case .parseFailed:
            return "Could not interpret the analysis result. Please select what you observe from the list below."
        }
    }
}
