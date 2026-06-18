import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechRecognitionManager: ObservableObject {

    @Published var isListening = false
    @Published var isAvailable: Bool

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)

    init() {
        let status = SFSpeechRecognizer.authorizationStatus()
        isAvailable = status != .denied && status != .restricted
    }

    func toggleListening(currentText: String, onUpdate: @escaping (String) -> Void) {
        if isListening {
            stop()
        } else {
            requestAndStart(baseText: currentText, onUpdate: onUpdate)
        }
    }

    func stop() {
        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    // MARK: - Private

    private func requestAndStart(baseText: String, onUpdate: @escaping (String) -> Void) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            start(baseText: baseText, onUpdate: onUpdate)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor [weak self] in
                    self?.isAvailable = status == .authorized
                    if status == .authorized {
                        self?.start(baseText: baseText, onUpdate: onUpdate)
                    }
                }
            }
        default:
            isAvailable = false
        }
    }

    private func start(baseText: String, onUpdate: @escaping (String) -> Void) {
        guard let recognizer, recognizer.isAvailable else {
            isAvailable = false
            return
        }

        stop()

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        guard (try? audioEngine.start()) != nil else { return }
        isListening = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let spoken = result.bestTranscription.formattedString
                let combined = baseText.trimmingCharacters(in: .whitespaces).isEmpty
                    ? spoken
                    : "\(baseText.trimmingCharacters(in: .whitespaces)) \(spoken)"
                Task { @MainActor [weak self] in
                    guard self != nil else { return }
                    onUpdate(combined)
                }
            }
            if error != nil || result?.isFinal == true {
                Task { @MainActor [weak self] in self?.stop() }
            }
        }
    }
}
