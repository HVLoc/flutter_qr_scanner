import Flutter
import UIKit
import AVFoundation
import CoreImage

public class FlutterQrScannerPlugin: NSObject, FlutterPlugin, AVCaptureMetadataOutputObjectsDelegate {
    var result: FlutterResult?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var scanViewController: UIViewController?
    var torchOn = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_qr_scanner", binaryMessenger: registrar.messenger())
        let instance = FlutterQrScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "scanQR" {
            self.result = result
            startScanning()
        } else if call.method == "scanQRFromImage" {
            guard let args = call.arguments as? [String: Any],
                  let imagePath = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing image path", details: nil))
                return
            }
            scanQRCodeFromImage(path: imagePath, flutterResult: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - 🔍 QR Scan From Image
    private func scanQRCodeFromImage(path: String, flutterResult: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: path),
              let ciImage = CIImage(image: image) else {
            flutterResult(nil)
            return
        }

        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)

        let features = detector?.features(in: ciImage) ?? []
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature, let message = qrFeature.messageString {
                flutterResult([
                    "content": message,
                    "format": "QR_CODE",
                    "rawBytes": "",
                    "errorCorrectionLevel": ""
                ])
                return
            }
        }

        // Không tìm thấy QR
        flutterResult(nil)
    }

    // MARK: - 📷 QR Scan From Camera
    private func startScanning() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            self.result?(nil)
            return
        }

        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession!.canAddInput(videoInput) else {
            self.result?(nil)
            return
        }
        captureSession!.addInput(videoInput)

        if videoCaptureDevice.isFocusModeSupported(.continuousAutoFocus) {
            try? videoCaptureDevice.lockForConfiguration()
            videoCaptureDevice.focusMode = .continuousAutoFocus
            videoCaptureDevice.unlockForConfiguration()
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession!.canAddOutput(metadataOutput) {
            captureSession!.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            self.result?(nil)
            return
        }

        let scanVC = UIViewController()
        scanVC.view.backgroundColor = UIColor.black

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = scanVC.view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        scanVC.view.layer.addSublayer(previewLayer!)
        
        // ✅ Blur overlay with cut-out center
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = 0.4
        blurView.frame = scanVC.view.bounds
        scanVC.view.addSubview(blurView)

        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: scanVC.view.bounds)
        let focusRect = CGRect(x: (scanVC.view.bounds.width - 250) / 2,
                               y: scanVC.view.bounds.height * 0.25,
                               width: 250, height: 250)

        path.append(UIBezierPath(rect: focusRect).reversing())
        maskLayer.path = path.cgPath
        blurView.layer.mask = maskLayer

        let focusView = UIView(frame: focusRect)
        focusView.layer.borderColor = UIColor.green.cgColor
        focusView.layer.borderWidth = 2
        focusView.backgroundColor = .clear
        scanVC.view.addSubview(focusView)

        
        // ✅ Instruction text
        let label = UILabel()
        label.text = "Đưa mã QR vào khung để quét"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        scanVC.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: scanVC.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: focusView.bottomAnchor, constant: 16)
        ])

        // 🔙 Back Button
        let backButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        }
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(dismissScanner), for: .touchUpInside)
        scanVC.view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: scanVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: scanVC.view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        // 🔦 Flash Button
        let flashButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            flashButton.setImage(UIImage(systemName: "bolt"), for: .normal)
        }
        flashButton.tintColor = .white
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        scanVC.view.addSubview(flashButton)
        NSLayoutConstraint.activate([
            flashButton.topAnchor.constraint(equalTo: scanVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flashButton.trailingAnchor.constraint(equalTo: scanVC.view.trailingAnchor, constant: -16),
            flashButton.widthAnchor.constraint(equalToConstant: 40),
            flashButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        rootVC.present(scanVC, animated: true) {
            self.captureSession?.startRunning()
        }
        self.scanViewController = scanVC
    }

    @objc private func dismissScanner() {
        captureSession?.stopRunning()
        captureSession = nil
        scanViewController?.dismiss(animated: true) {
            self.result?(nil)
        }
    }

    @objc private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if torchOn {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: 1.0)
            }
            torchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Flash error: \(error)")
        }
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                                didOutput metadataObjects: [AVMetadataObject],
                                from connection: AVCaptureConnection) {
        captureSession?.stopRunning()

        DispatchQueue.main.async {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               metadataObject.type == .qr,
               let stringValue = metadataObject.stringValue {
                self.scanViewController?.dismiss(animated: true) {
                    self.result?([
                        "content": stringValue,
                        "format": "QR_CODE",
                        "rawBytes": "",
                        "errorCorrectionLevel": ""
                    ])
                }
            } else {
                self.scanViewController?.dismiss(animated: true) {
                    self.result?(nil)
                }
            }
            self.captureSession = nil
        }
    }
}
