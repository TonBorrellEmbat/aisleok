import AVFoundation
import SwiftUI
import Vision

struct OCRCameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    func makeUIViewController(context: Context) -> OCRCaptureController {
        let vc = OCRCaptureController()
        vc.onCapture = { [onCapture] image in
            onCapture(image)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: OCRCaptureController, context: Context) {
        uiViewController.onCapture = onCapture
    }

    static func dismantleUIViewController(_ uiViewController: OCRCaptureController, coordinator: Coordinator) {
        uiViewController.stop()
    }

    final class Coordinator {
        var onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }
    }
}

final class OCRCaptureController: UIViewController {
    var onCapture: ((UIImage) -> Void)?
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var preview: AVCaptureVideoPreviewLayer?
    private var capturing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemFill
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCaptureNotification),
            name: .aisleokCaptureOCR,
            object: nil
        )
        session.sessionPreset = .photo
        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }
        session.addInput(input)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        preview = layer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func capture() {
        guard !capturing else { return }
        capturing = true
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    @objc func handleCaptureNotification() {
        capture()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension OCRCaptureController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        capturing = false
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        onCapture?(image)
    }
}

enum LabelOCR {
    static func recognize(_ image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }
}
