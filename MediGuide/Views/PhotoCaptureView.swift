import AVFoundation
import PhotosUI
import SwiftUI

struct PhotoCaptureView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var vm: PhotoCaptureViewModel
    @Environment(\.dismiss) private var dismiss

    // Gesture state for pinch-to-zoom
    @GestureState private var pinchScale: CGFloat = 1.0
    @State private var baseZoom: CGFloat = 1.0
    @State private var showLibraryPicker = false

    init(treeData: DecisionTreeData, photoContext: PhotoContext = .general, onComplete: @escaping ([String]) -> Void) {
        _vm = StateObject(wrappedValue: PhotoCaptureViewModel(
            treeData: treeData,
            photoContext: photoContext,
            onComplete: onComplete
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch vm.phase {
            case .viewfinder:       viewfinderPhase
            case .permissionDenied: permissionDeniedPhase
            case .reviewing(let image): reviewPhase(image: image)
            case .analyzing(let image): analyzingPhase(image: image)
            case .confirming(let findings): confirmingPhase(findings: findings)
            case .manualTagging:    manualTaggingPhase
            }
        }
        .preferredColorScheme(.dark)
        .task { await startCamera() }
        .onDisappear { camera.stopSession() }
        .sheet(isPresented: $showLibraryPicker) {
            PhotoLibraryPicker { image in
                showLibraryPicker = false
                if let image { vm.photoCaptured(image) }
            }
        }
    }

    // MARK: - Viewfinder

    private var viewfinderPhase: some View {
        ZStack(alignment: .bottom) {
            // Live preview
            GeometryReader { geo in
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { camera.setFocus(at: $0.location, in: geo.size) }
                    )
                    .gesture(pinchToZoomGesture)
            }
            .ignoresSafeArea()

            // Guidance overlay (shown only when camera is running)
            if camera.isRunning {
                PhotoGuidanceView(context: vm.photoContext)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Controls overlay
            VStack(spacing: 0) {
                viewfinderTopBar
                Spacer()
                viewfinderBottomBar
            }
        }
    }

    private var viewfinderTopBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            flashButton
            Spacer()
            switchCameraButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var flashButton: some View {
        Button { camera.toggleFlash() } label: {
            Image(systemName: camera.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var switchCameraButton: some View {
        Button { camera.switchCamera() } label: {
            Image(systemName: "arrow.triangle.2.circlepath.camera")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var viewfinderBottomBar: some View {
        HStack(alignment: .center, spacing: 0) {
            // Library picker button
            Button { showLibraryPicker = true } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .frame(maxWidth: .infinity)

            // Shutter button
            shutterButton

            // Placeholder for symmetry
            Color.clear
                .frame(width: 56, height: 56)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 48)
    }

    private var shutterButton: some View {
        Button {
            camera.capturePhoto { image in
                vm.photoCaptured(image)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(.white.opacity(0.5), lineWidth: 4)
                    .frame(width: 84, height: 84)
            }
        }
        .disabled(!camera.isRunning)
    }

    // MARK: - Gestures

    private var pinchToZoomGesture: some Gesture {
        MagnificationGesture()
            .updating($pinchScale) { current, state, _ in state = current }
            .onEnded { factor in
                baseZoom = min(max(baseZoom * factor, 1.0), 5.0)
                camera.setZoom(baseZoom)
            }
            .onChanged { factor in
                camera.setZoom(baseZoom * factor)
            }
    }

    // MARK: - Review phase

    private func reviewPhase(image: UIImage) -> some View {
        ZStack(alignment: .bottom) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .clipped()

            // Quality warning if image is very small (rough proxy for poor quality)
            qualityNote(for: image)

            VStack(spacing: 0) {
                reviewTopBar
                Spacer()
                reviewBottomBar(image: image)
            }
        }
    }

    private func qualityNote(for image: UIImage) -> some View {
        let isSmall = image.size.width < 400 || image.size.height < 400
        return Group {
            if isSmall {
                VStack {
                    Spacer()
                    Text("This photo may be too small to analyze accurately — retake for better results.")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 140)
                }
            }
        }
    }

    private var reviewTopBar: some View {
        HStack {
            Button { vm.retakePhoto() } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func reviewBottomBar(image: UIImage) -> some View {
        VStack(spacing: 12) {
            Button { vm.usePhoto(image) } label: {
                Text("Use This Photo")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button { vm.retakePhoto() } label: {
                Text("Retake")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
    }

    // MARK: - Analyzing phase

    private func analyzingPhase(image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .clipped()
                .blur(radius: 3)
                .overlay(Color.black.opacity(0.4).ignoresSafeArea())

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text("Analyzing photo…")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("This usually takes a few seconds")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Confirming phase

    @ViewBuilder
    private func confirmingPhase(findings: VisualSymptomParser.ParsedVisualFindings) -> some View {
        let hardIds = Set(
            findings.calibratedFindings
                .filter(\.isHardEscalation)
                .map(\.symptomId)
        )
        Color.clear
            .sheet(isPresented: .constant(true), onDismiss: { dismiss() }) {
                SymptomTaggingView(
                    findings: findings,
                    hardOverrideIds: hardIds,
                    onConfirm: { ids in
                        vm.confirmSymptomIds(ids)
                        dismiss()
                    },
                    onDismiss: { dismiss() }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
    }

    // MARK: - Manual tagging phase

    private var manualTaggingPhase: some View {
        Color.clear
            .sheet(isPresented: .constant(true), onDismiss: { dismiss() }) {
                manualTaggingSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }

    private var manualTaggingSheet: some View {
        ManualVisualSymptomPicker(
            errorMessage: vm.analysisErrorMessage,
            onConfirm: { ids in
                vm.confirmSymptomIds(ids)
                dismiss()
            },
            onDismiss: { dismiss() }
        )
    }

    // MARK: - Permission denied phase

    private var permissionDeniedPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text("Camera Access Needed")
                    .font(.title3.bold())
                Text("Camera access is needed to analyze visual symptoms. Photos are never saved to your device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                }
                Button { dismiss() } label: {
                    Text("Describe symptoms in words instead")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    // MARK: - Camera startup

    private func startCamera() async {
        camera.requestPermissionAndStart()
        // Brief delay to let the permission state settle before checking it
        try? await Task.sleep(nanoseconds: 300_000_000)
        if camera.permission == .denied {
            vm.permissionDenied()
        }
    }
}

// MARK: - CameraPreviewView (UIViewRepresentable)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> _PreviewUIView {
        let view = _PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: _PreviewUIView, context: Context) {}

    final class _PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - PhotoLibraryPicker (UIViewControllerRepresentable)

private struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage?) -> Void
        init(onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self)
            else {
                onPick(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    self?.onPick(object as? UIImage)
                }
            }
        }
    }
}

// MARK: - ManualVisualSymptomPicker

private struct ManualVisualSymptomPicker: View {
    let errorMessage: String?
    let onConfirm: ([String]) -> Void
    let onDismiss: () -> Void

    @State private var selectedIds: Set<String> = []

    private let sortedIds = VisualSymptomReferenceProvider.visualSymptomIds.sorted()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select what you observe")
                            .font(.headline)
                        if let msg = errorMessage {
                            Text(msg)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Photo analysis is unavailable. Select all that apply.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LazyVStack(spacing: 8) {
                        ForEach(sortedIds, id: \.self) { id in
                            toggleRow(id: id)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            VStack(spacing: 10) {
                Divider()
                VStack(spacing: 10) {
                    Button { onConfirm(Array(selectedIds)) } label: {
                        Text(selectedIds.isEmpty ? "Skip — no visual symptoms" : "Use selected symptoms")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func toggleRow(id: String) -> some View {
        let isOn = selectedIds.contains(id)
        return Button {
            if isOn { selectedIds.remove(id) } else { selectedIds.insert(id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? .blue : .secondary)
                Text(VisualSymptomReferenceProvider.description(for: id))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(12)
            .background(isOn ? Color.blue.opacity(0.08) : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
