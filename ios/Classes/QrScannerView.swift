import Flutter
import UIKit
import AVFoundation
import Vision

class QrScannerView: NSObject, FlutterPlatformView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var resultCallback: ((String) -> Void)?
    private let qrViewContainer: QrPreviewContainerView
    private var isDetected = false
    private let visionQueue = DispatchQueue(label: "qr.vision.queue")

    init(frame: CGRect,
         messenger: FlutterBinaryMessenger,
         viewId: Int64,
         resultCallback: @escaping (String) -> Void) {
        self.qrViewContainer = QrPreviewContainerView()
        self.resultCallback = resultCallback
        super.init()

        checkCameraPermissionAndStart()
    }

    func view() -> UIView {
        return self.qrViewContainer
    }

    private func checkCameraPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            let session = AVCaptureSession()
            session.sessionPreset = .high

            if device.isFocusModeSupported(.continuousAutoFocus) {
                try? device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            // Video output
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
            ]
            output.setSampleBufferDelegate(self, queue: visionQueue)

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            self.videoOutput = output
            self.captureSession = session

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            self.previewLayer = preview

            DispatchQueue.main.async {
                self.qrViewContainer.setPreviewLayer(preview)
            }

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }

        } catch {
            print("Camera error: \(error)")
        }
    }

    private func handleVisionRequest(pixelBuffer: CVPixelBuffer) {
        let request = VNDetectBarcodesRequest { request, error in
            guard error == nil else { return }

            if let results = request.results as? [VNBarcodeObservation],
               let qr = results.first,
               let value = qr.payloadStringValue,
               !self.isDetected {
                self.isDetected = true
                DispatchQueue.main.async {
                    self.resultCallback?(value)
                    self.captureSession?.stopRunning()
                }
            }
        }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? requestHandler.perform([request])
    }

    deinit {
        captureSession?.stopRunning()
        captureSession = nil
    }
}

// MARK: - Camera Output Delegate
extension QrScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard !isDetected,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        self.handleVisionRequest(pixelBuffer: pixelBuffer)
    }
}

// MARK: - View container
class QrPreviewContainerView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer?.removeFromSuperlayer()
        self.previewLayer = layer
        layer.frame = self.bounds
        layer.videoGravity = .resizeAspectFill
        self.layer.insertSublayer(layer, at: 0)
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.previewLayer?.frame = self.bounds
    }
}
