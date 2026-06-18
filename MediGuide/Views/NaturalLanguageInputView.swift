import SwiftUI

struct NaturalLanguageInputView: View {
    @StateObject private var vm: NaturalLanguageInputViewModel
    @StateObject private var speechManager = SpeechRecognitionManager()
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var emergencyCoordinator: EmergencyButtonCoordinator
    @FocusState private var isTextFocused: Bool
    @State private var showPhotoCapture = false

    init(engine: TriageEngine) {
        _vm = StateObject(wrappedValue: NaturalLanguageInputViewModel(engine: engine))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    contextBanner
                    inputCard
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .onAppear { isTextFocused = true }
        .overlay { if vm.isSending { sendingOverlay } }
        .allowsHitTesting(!vm.isSending)
        .fullScreenCover(isPresented: $showPhotoCapture) {
            PhotoCaptureView(treeData: vm.treeData, photoContext: .general) { symptomIds in
                for id in symptomIds { vm.addVisualSymptom(id) }
                appState.activeScreen = .results
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.isConfirming },
            set: { if !$0 { vm.retryInput() } }
        )) {
            if let parsed = vm.lastResult {
                ConfirmationPanel(
                    parsed: parsed,
                    hardOverrideIds: vm.hardOverrideIds,
                    isOffline: vm.isOfflineResult,
                    onConfirm: {
                        vm.confirmAndApply()
                        appState.activeScreen = .results
                    },
                    onCorrect: { vm.retryInput() },
                    onSwitchToGuided: {
                        vm.retryInput()
                        appState.activeScreen = .triage
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Context Banner

    private var contextBanner: some View {
        Button {
            appState.activeScreen = .profileSelection
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(contextLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var contextLabel: String {
        if let name = appState.activeProfileName {
            return "Triaging for: \(name)"
        }
        return "Triaging for: tap to select profile"
    }

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if vm.inputText.isEmpty {
                    placeholder
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $vm.inputText)
                    .focused($isTextFocused)
                    .frame(minHeight: 150)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .scrollContentBackground(.hidden)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(false)
                    .onChange(of: vm.inputText) { _, new in
                        if new.count > 500 { vm.inputText = String(new.prefix(500)) }
                    }
            }

            Divider().padding(.horizontal, 4)

            HStack {
                if vm.inputText.count > 400 {
                    Text("\(vm.inputText.count)/500")
                        .font(.caption2)
                        .foregroundStyle(vm.inputText.count >= 500 ? .red : .secondary)
                        .padding(.leading, 14)
                }
                Spacer()
                HStack(spacing: 4) {
                    cameraButton
                    if speechManager.isAvailable { micButton }
                }
                .padding(.trailing, 12)
            }
            .frame(height: 36)
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Describe what's happening in your own words...")
                .font(.body)
                .foregroundStyle(Color(.placeholderText))
            Text(#"e.g. "My dad is clutching his chest and having trouble breathing" or "My daughter has a high fever and won't stop crying""#)
                .font(.footnote)
                .foregroundStyle(Color(.placeholderText).opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cameraButton: some View {
        Button {
            speechManager.stop()
            isTextFocused = false
            showPhotoCapture = true
        } label: {
            Image(systemName: "camera.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Analyze a photo")
    }

    private var micButton: some View {
        Button {
            let base = vm.inputText
            speechManager.toggleListening(currentText: base) { updated in
                vm.inputText = updated
            }
        } label: {
            Image(systemName: speechManager.isListening
                  ? "waveform.circle.fill"
                  : "mic.circle.fill")
                .font(.title2)
                .foregroundStyle(speechManager.isListening ? .red : .secondary)
                .symbolEffect(.pulse, isActive: speechManager.isListening)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                speechManager.stop()
                isTextFocused = false
                Task { await vm.analyze() }
            } label: {
                Text("Analyze Symptoms")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(vm.isAnalyzeEnabled ? Color.red : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!vm.isAnalyzeEnabled)

            Button {
                speechManager.stop()
                appState.activeScreen = .triage
            } label: {
                Text("Use Guided Questions Instead")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Sending Overlay

    private var sendingOverlay: some View {
        ZStack {
            Color(.systemBackground).opacity(0.75)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Analyzing symptoms…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Back") {
                speechManager.stop()
                appState.activeScreen = .profileSelection
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            EmergencyButtonView(context: .activeTriage)
        }
    }
}

// MARK: - Confirmation Panel

private struct ConfirmationPanel: View {
    let parsed: LLMResponseParser.ParsedSymptoms
    let hardOverrideIds: Set<String>
    let isOffline: Bool
    let onConfirm: () -> Void
    let onCorrect: () -> Void
    let onSwitchToGuided: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if parsed.uncertain && parsed.symptoms.isEmpty {
                        uncertainView
                    } else {
                        extractedView
                    }
                    if isOffline { offlineBanner }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)
            actionRow
        }
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Sub-views

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Does this look right?")
                .font(.headline)
            Text("Based on your description we identified:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var extractedView: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !parsed.symptoms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Symptoms")
                        .font(.caption.uppercaseSmallCaps())
                        .foregroundStyle(.secondary)
                    ForEach(parsed.symptoms) { symptom in
                        let isOverride = hardOverrideIds.contains(symptom.symptomId)
                        HStack(spacing: 10) {
                            Image(systemName: isOverride ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(isOverride ? .red : .green)
                            Text(SymptomReferenceProvider.description(for: symptom.symptomId))
                                .font(.subheadline)
                                .foregroundStyle(isOverride ? .red : .primary)
                        }
                    }
                }
            }

            if !parsed.modifiers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Context noted")
                        .font(.caption.uppercaseSmallCaps())
                        .foregroundStyle(.secondary)
                    ForEach(parsed.modifiers) { modifier in
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text(SymptomReferenceProvider.modifierDescription(for: modifier.modifierId))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var uncertainView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Couldn't identify specific symptoms", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.subheadline.bold())
            Text("Your description was too vague for reliable extraction. Try adding more detail, or switch to guided questions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var offlineBanner: some View {
        Label(
            "Basic keyword matching — API unavailable. Results may be less precise; guided questions are more reliable.",
            systemImage: "exclamationmark.triangle"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            Divider()
            VStack(spacing: 10) {
                if !parsed.uncertain || !parsed.symptoms.isEmpty {
                    Button(action: onConfirm) {
                        Text("Yes, continue")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                HStack(spacing: 20) {
                    Button(action: onCorrect) {
                        Text(parsed.uncertain && parsed.symptoms.isEmpty ? "Add more detail" : "Something is missing")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if !parsed.symptoms.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Button(action: onSwitchToGuided) {
                            Text("Use guided questions")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Spacer()
                        Button(action: onSwitchToGuided) {
                            Text("Switch to guided questions")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
