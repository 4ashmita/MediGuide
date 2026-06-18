import Combine
import Foundation

@MainActor
final class NaturalLanguageInputViewModel: ObservableObject {

    enum State {
        case idle
        case sending
        case confirming(isOffline: Bool)
        case error(String)
    }

    @Published var inputText: String = ""
    @Published private(set) var state: State = .idle

    private(set) var lastResult: LLMResponseParser.ParsedSymptoms?

    var treeData: DecisionTreeData { engine.treeData }
    var hardOverrideIds: Set<String> { Set(engine.treeData.hardOverrides) }

    var isAnalyzeEnabled: Bool {
        guard case .idle = state else { return false }
        return inputText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5
    }

    var isSending: Bool {
        if case .sending = state { return true }
        return false
    }

    var isConfirming: Bool {
        if case .confirming = state { return true }
        return false
    }

    var isOfflineResult: Bool {
        if case .confirming(let offline) = state { return offline }
        return false
    }

    private let engine: TriageEngine
    private let service: SymptomExtractionService

    init(engine: TriageEngine) {
        self.engine = engine
        self.service = SymptomExtractionService(treeData: engine.treeData)
    }

    func analyze() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5 else { return }
        state = .sending
        let result = await service.extract(from: trimmed)
        lastResult = result.parsed
        state = .confirming(isOffline: result.source == .fallback)
    }

    func confirmAndApply() {
        guard let parsed = lastResult else { return }
        for symptom in parsed.symptoms { engine.addSymptom(symptom.symptomId) }
        for modifier in parsed.modifiers { engine.addModifier(modifier.modifierId) }
    }

    func retryInput() {
        state = .idle
        lastResult = nil
    }

    func dismissConfirmation() {
        state = .idle
    }

    // Called after photo analysis completes to inject visual findings into the engine.
    func addVisualSymptom(_ id: String) {
        engine.addSymptom(id)
    }
}
