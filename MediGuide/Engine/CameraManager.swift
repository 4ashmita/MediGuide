import AVFoundation
import Combine
import PhotosUI
import UIKit

final class CameraManager: NSObject, ObservableObject {

    enum Permission { case undetermined, granted, denied }

    @Published private(set) var permission: Permission = .undetermined
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isFlashOn: Bool = false
    @Published private(set) var isFrontCamera: Bool = false

    // Exposed so CameraPreviewView can attach its preview layer
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.mediguide.camera.session")
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var captureCompletion: ((UIImage) -> Void)?

    // MARK: - Lifecycle

    func requestPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.permission = .granted }
            sessionQueue.async { self.configureAndStart(front: false) }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { self?.permission = granted ? .granted : .denied }
                if granted { self?.sessionQueue.async { self?.configureAndStart(front: false) } }
            }
        default:
            DispatchQueue.main.async { self.permission = .denied }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { self?.isRunning = false }
        }
    }

    // MARK: - Capture

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        captureCompletion = completion
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            // Only set flashMode if the output supports it; simulator has no flash.
            if self.photoOutput.supportedFlashModes.contains(.on) {
                // Settings.flashMode must be set on a fresh AVCapturePhotoSettings instance.
                let flashSettings = AVCapturePhotoSettings()
                flashSettings.flashMode = self.isFlashOn ? .on : .off
                self.photoOutput.capturePhoto(with: flashSettings, delegate: self)
                return
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Controls

    func toggleFlash() {
        DispatchQueue.main.async { self.isFlashOn.toggle() }
    }

    func switchCamera() {
        let toFront = !isFrontCamera
        DispatchQueue.main.async { self.isFrontCamera = toFront }
        sessionQueue.async { [weak self] in self?.reconfigureInput(front: toFront) }
    }

    func setFocus(at point: CGPoint, in viewSize: CGSize) {
        guard let device = currentDevice, device.isFocusPointOfInterestSupported else { return }
        let normalized = CGPoint(
            x: max(0, min(1, point.x / viewSize.width)),
            y: max(0, min(1, point.y / viewSize.height))
        )
        sessionQueue.async {
            guard (try? device.lockForConfiguration()) != nil else { return }
            device.focusPointOfInterest = normalized
            device.focusMode = .autoFocus
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = normalized
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        }
    }

    func setZoom(_ factor: CGFloat) {
        guard let device = currentDevice else { return }
        sessionQueue.async {
            let clamped = min(max(factor, 1.0), min(device.maxAvailableVideoZoomFactor, 5.0))
            guard (try? device.lockForConfiguration()) != nil else { return }
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        }
    }

    // MARK: - Private session management

    private func configureAndStart(front: Bool) {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = captureDevice(front: front),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            session.commitConfiguration()
            return
        }
        currentDevice = device
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            photoOutput = output
        }

        session.commitConfiguration()
        session.startRunning()
        DispatchQueue.main.async { self.isRunning = true }
    }

    private func reconfigureInput(front: Bool) {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        if let device = captureDevice(front: front),
           let input = try? AVCaptureDeviceInput(device: device) {
            currentDevice = device
            if session.canAddInput(input) { session.addInput(input) }
        }
        session.commitConfiguration()
    }

    private func captureDevice(front: Bool) -> AVCaptureDevice? {
        let position: AVCaptureDevice.Position = front ? .front : .back
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else { return }

        DispatchQueue.main.async { [weak self] in
            self?.captureCompletion?(image)
            self?.captureCompletion = nil
        }
    }
}
