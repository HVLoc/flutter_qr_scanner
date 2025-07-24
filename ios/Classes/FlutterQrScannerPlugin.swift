import Flutter
import UIKit
import AVFoundation
import CoreImage

public class FlutterQrScannerPlugin: NSObject, FlutterPlugin, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var result: FlutterResult?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var scanViewController: UIViewController?
    var torchOn = false
    var showGalleryButton = true

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_qr_scanner", binaryMessenger: registrar.messenger())
        let instance = FlutterQrScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        if call.method == "scanQR" {
            if let args = call.arguments as? [String: Any] {
                self.showGalleryButton = args["showGallery"] as? Bool ?? false
            }
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

        flutterResult(nil)
    }

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

        // ✅ Blur overlay
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

        // Instruction
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

        // Back button
        let backButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(dismissScanner), for: .touchUpInside)
        scanVC.view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: scanVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: scanVC.view.leadingAnchor, constant: 16)
        ])

        // Flash button
        let flashButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            flashButton.setImage(UIImage(systemName: "bolt"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        flashButton.tintColor = .white
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        scanVC.view.addSubview(flashButton)
        NSLayoutConstraint.activate([
            flashButton.topAnchor.constraint(equalTo: scanVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flashButton.trailingAnchor.constraint(equalTo: scanVC.view.trailingAnchor, constant: -16)
        ])

        // 📸 Gallery Button
        if showGalleryButton {
            let galleryButton = UIButton(type: .system)
            if #available(iOS 13.0, *) {
                galleryButton.setImage(UIImage(systemName: "photo"), for: .normal)
            } else {
                // Fallback on earlier versions
            }
            galleryButton.tintColor = .white
            galleryButton.translatesAutoresizingMaskIntoConstraints = false
            galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
            scanVC.view.addSubview(galleryButton)
            NSLayoutConstraint.activate([
                galleryButton.bottomAnchor.constraint(equalTo: scanVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                galleryButton.centerXAnchor.constraint(equalTo: scanVC.view.centerXAnchor),
                galleryButton.widthAnchor.constraint(equalToConstant: 50),
                galleryButton.heightAnchor.constraint(equalToConstant: 50)
            ])
            // Instruction
            let labelGallery = UILabel()
            labelGallery.text = "Chọn từ ảnh trong máy"
            labelGallery.textColor = .white
            labelGallery.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            labelGallery.textAlignment = .center
            labelGallery.translatesAutoresizingMaskIntoConstraints = false
            scanVC.view.addSubview(labelGallery)
            NSLayoutConstraint.activate([
                labelGallery.centerXAnchor.constraint(equalTo: scanVC.view.centerXAnchor),
                labelGallery.topAnchor.constraint(equalTo: galleryButton.bottomAnchor, constant: 16)
            ])

        }

        rootVC.present(scanVC, animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
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
            device.torchMode = torchOn ? .off : .on
            torchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Flash error: \(error)")
        }
    }

    @objc private func openGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.modalPresentationStyle = .fullScreen
        scanViewController?.present(picker, animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[.originalImage] as? UIImage else {
            self.result?(nil)
            return
        }

        guard let ciImage = CIImage(image: image) else {
            self.result?(nil)
            return
        }

        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)

        let features = detector?.features(in: ciImage) ?? []
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature, let message = qrFeature.messageString {
                self.scanViewController?.dismiss(animated: true) {
                    self.result?([
                        "content": message,
                        "format": "QR_CODE",
                        "rawBytes": "",
                        "errorCorrectionLevel": ""
                    ])
                }
                return
            }
        }

        self.scanViewController?.dismiss(animated: true) {
            self.result?(nil)
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
