import Flutter
import UIKit
import AVFoundation

public class FlutterQrScannerPlugin: NSObject, FlutterPlugin, AVCaptureMetadataOutputObjectsDelegate {
    var result: FlutterResult?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var scanViewController: UIViewController?
    
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
            // iOS không hỗ trợ decode ảnh từ path đơn giản như Android, cần dùng CoreImage phức tạp hơn
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
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
        
        rootVC.present(scanVC, animated: true) {
            self.captureSession?.startRunning()
        }
        self.scanViewController = scanVC
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                                didOutput metadataObjects: [AVMetadataObject],
                                from connection: AVCaptureConnection) {
        captureSession?.stopRunning()
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           metadataObject.type == .qr,
           let stringValue = metadataObject.stringValue {
            self.scanViewController?.dismiss(animated: true) {
                self.result?(["content": stringValue, "format": "QR_CODE", "rawBytes": "", "errorCorrectionLevel": ""])
            }
        } else {
            self.scanViewController?.dismiss(animated: true) {
                self.result?(nil)
            }
        }
    }
}
