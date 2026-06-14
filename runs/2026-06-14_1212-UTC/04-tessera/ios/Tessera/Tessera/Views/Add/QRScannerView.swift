import SwiftUI
import AVFoundation

/// Camera permission / availability states surfaced to the SwiftUI layer.
enum ScannerStatus: Equatable {
    case ready
    case denied
    case unavailable
}

/// A UIViewControllerRepresentable wrapper over AVFoundation's metadata scanner.
/// Emits the first decoded string via `onFound`, and surfaces status via `onStatus`.
struct QRScannerView: UIViewControllerRepresentable {
    let onFound: (String) -> Void
    let onStatus: (ScannerStatus) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFound: onFound, onStatus: onStatus)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onFound: (String) -> Void
        let onStatus: (ScannerStatus) -> Void
        private var didFind = false

        init(onFound: @escaping (String) -> Void, onStatus: @escaping (ScannerStatus) -> Void) {
            self.onFound = onFound
            self.onStatus = onStatus
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !didFind else { return }
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue, !value.isEmpty else { return }
            didFind = true
            DispatchQueue.main.async { [weak self] in
                self?.onFound(value)
            }
        }
    }
}

/// The hosting controller that owns the AVCaptureSession lifecycle.
final class ScannerViewController: UIViewController {
    weak var coordinator: QRScannerView.Coordinator?
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "com.orbioom.tessera.camera")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestAndConfigure()
    }

    private func requestAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.coordinator?.onStatus(.denied)
                    }
                }
            }
        case .denied, .restricted:
            coordinator?.onStatus(.denied)
        @unknown default:
            coordinator?.onStatus(.unavailable)
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            coordinator?.onStatus(.unavailable)
            return
        }
        session.addInput(input)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            coordinator?.onStatus(.unavailable)
            return
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(coordinator, queue: .main)
        if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        coordinator?.onStatus(.ready)
        startSession()
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.inputs.isEmpty { startSession() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}
