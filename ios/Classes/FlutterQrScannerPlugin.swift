import Flutter
import UIKit
import AVFoundation
import CoreImage
import Vision

public class FlutterQrScannerPlugin: NSObject, FlutterPlugin, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var result: FlutterResult?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var scanViewController: UIViewController?
    var torchOn = false
    var showGalleryButton = true
    var isProcessingFrame = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_qr_scanner", binaryMessenger: registrar.messenger())
        let instance = FlutterQrScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let factory = QrScannerViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "vn.lochv.flutter_qr_scanner/native_view")
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
        guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
            flutterResult(nil)
            return
        }

        let request = VNDetectBarcodesRequest { request, error in
            if let results = request.results as? [VNBarcodeObservation],
               let qr = results.first(where: { $0.symbology == .QR }),
               let payload = qr.payloadStringValue {
                DispatchQueue.main.async {
                    flutterResult([
                        "content": payload,
                        "format": "QR_CODE",
                        "rawBytes": "",
                        "errorCorrectionLevel": ""
                    ])
                }
            } else {
                DispatchQueue.main.async {
                    flutterResult(nil)
                }
            }
        }
        request.symbologies = [.QR]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
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

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "qr.scan.queue"))
        if captureSession!.canAddOutput(videoOutput) {
            captureSession!.addOutput(videoOutput)
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

        setupBlurOverlay(in: scanVC)
        setupInstructionAndButtons(in: scanVC)

        rootVC.present(scanVC, animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }

        self.scanViewController = scanVC
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isProcessingFrame { return }
        isProcessingFrame = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self else { return }
            defer { self.isProcessingFrame = false }

            if let results = request.results as? [VNBarcodeObservation],
               let qr = results.first(where: { $0.symbology == .QR }),
               let payload = qr.payloadStringValue {
                self.captureSession?.stopRunning()
                DispatchQueue.main.async {
                    self.scanViewController?.dismiss(animated: true) {
                        self.result?([
                            "content": payload,
                            "format": "QR_CODE",
                            "rawBytes": "",
                            "errorCorrectionLevel": ""
                        ])
                    }
                }
            }
        }
        request.symbologies = [.QR]
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }
    
    private func setupBlurOverlay(in viewController: UIViewController) {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = 0.4
        blurView.frame = viewController.view.bounds
        viewController.view.addSubview(blurView)

        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: viewController.view.bounds)
        let focusRect = CGRect(x: (viewController.view.bounds.width - 250) / 2,
                               y: viewController.view.bounds.height * 0.25,
                               width: 250, height: 250)
        path.append(UIBezierPath(rect: focusRect).reversing())
        maskLayer.path = path.cgPath
        blurView.layer.mask = maskLayer

        let focusView = UIView(frame: focusRect)
        focusView.layer.borderColor = UIColor.green.cgColor
        focusView.layer.borderWidth = 2
        focusView.backgroundColor = .clear
        viewController.view.addSubview(focusView)
    }

    private func setupInstructionAndButtons(in viewController: UIViewController) {
        // Focus khung QR
        let focusRect = CGRect(x: (viewController.view.bounds.width - 250) / 2,
                               y: viewController.view.bounds.height * 0.25,
                               width: 250, height: 250)

        // Text hướng dẫn
        let label = UILabel()
        label.text = "Đưa mã QR vào khung để quét"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: focusRect.maxY + 16)
        ])

        // Nút back
        let backButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        }
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(dismissScanner), for: .touchUpInside)
        viewController.view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 16)
        ])

        // Nút flash
        let flashButton = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            flashButton.setImage(UIImage(systemName: "bolt"), for: .normal)
        }
        flashButton.tintColor = .white
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        viewController.view.addSubview(flashButton)
        NSLayoutConstraint.activate([
            flashButton.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flashButton.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -16)
        ])

        // Nút chọn ảnh (nếu có bật)
        if showGalleryButton {
            let galleryButton = UIButton(type: .system)
            if #available(iOS 13.0, *) {
                galleryButton.setImage(UIImage(systemName: "photo"), for: .normal)
            }
            galleryButton.tintColor = .white
            galleryButton.translatesAutoresizingMaskIntoConstraints = false
            galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
            viewController.view.addSubview(galleryButton)
            NSLayoutConstraint.activate([
                galleryButton.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                galleryButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                galleryButton.widthAnchor.constraint(equalToConstant: 50),
                galleryButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            let labelGallery = UILabel()
            labelGallery.text = "Chọn từ ảnh trong máy"
            labelGallery.textColor = .white
            labelGallery.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            labelGallery.textAlignment = .center
            labelGallery.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.addSubview(labelGallery)
            NSLayoutConstraint.activate([
                labelGallery.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                labelGallery.topAnchor.constraint(equalTo: galleryButton.bottomAnchor, constant: 16)
            ])
        }
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

            guard let image = info[.originalImage] as? UIImage,
                  let cgImage = image.cgImage else {
                self.result?(nil)
                return
            }

            let request = VNDetectBarcodesRequest { request, error in
                if let results = request.results as? [VNBarcodeObservation],
                   let qr = results.first(where: { $0.symbology == .QR }),
                   let payload = qr.payloadStringValue {
                    DispatchQueue.main.async {
                        self.scanViewController?.dismiss(animated: true) {
                            self.result?([
                                "content": payload,
                                "format": "QR_CODE",
                                "rawBytes": "",
                                "errorCorrectionLevel": ""
                            ])
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.scanViewController?.dismiss(animated: true) {
                            self.result?(nil)
                        }
                    }
                }
            }
            request.symbologies = [.QR]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    DispatchQueue.main.async {
                        self.scanViewController?.dismiss(animated: true) {
                            self.result?(nil)
                        }
                    }
                }
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
