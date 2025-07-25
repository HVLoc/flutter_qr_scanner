
import Flutter
import UIKit

class QrScannerViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        let methodChannel = FlutterMethodChannel(name: "flutter_qr_scanner_channel_\(viewId)",
                                                 binaryMessenger: messenger)
        return QrScannerView(frame: frame,
                             messenger: messenger,
                             viewId: viewId,
                             resultCallback: { result in
                                 methodChannel.invokeMethod("onScanResult", arguments: result)
                             })
    }
}
