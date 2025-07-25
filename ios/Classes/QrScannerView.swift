import Flutter
import UIKit
import AVFoundation

class QrScannerView: NSObject, FlutterPlatformView, AVCaptureMetadataOutputObjectsDelegate {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var resultCallback: ((String) -> Void)?
//    private let qrView: UIView
    private let qrViewContainer: QrPreviewContainerView


    init(frame: CGRect,
         messenger: FlutterBinaryMessenger,
         viewId: Int64,
         resultCallback: @escaping (String) -> Void) {
        self.qrViewContainer = QrPreviewContainerView()
        self.resultCallback = resultCallback
        super.init()
        
//        qrView.backgroundColor = UIColor.red   tạm thời để test xem view có lên không

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

                if session.canAddInput(input) { session.addInput(input) }

                let output = AVCaptureMetadataOutput()
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    output.metadataObjectTypes = [.qr]
                }

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
                print("Error setting up camera: \(error)")
            }
        
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           metadataObject.type == .qr,
           let stringValue = metadataObject.stringValue {
            resultCallback?(stringValue)
            captureSession?.stopRunning()
        }
    }

    deinit {
        captureSession?.stopRunning()
        captureSession = nil
    }
}


class QrPreviewContainerView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = layer
        self.layer.insertSublayer(layer, at: 0)
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.previewLayer?.frame = self.bounds
    }
}
