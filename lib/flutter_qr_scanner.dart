// import 'flutter_qr_scanner_platform_interface.dart';

// class FlutterQrScanner {
//   Future<String?> getPlatformVersion() {
//     return FlutterQrScannerPlatform.instance.getPlatformVersion();
//   }
// }
import 'package:flutter/services.dart';

class FlutterQrScanner {
  static const MethodChannel _channel = MethodChannel('flutter_qr_scanner');

  static Future<Map?> scanQR() async {
    final result = await _channel.invokeMethod<Map>('scanQR');
    return result;
  }

  static Future<String?> scanQRFromImage(String filePath) async {
    final result = await _channel
        .invokeMethod<String>('scanQRFromImage', {"path": filePath});
    return result;
  }
}
