import 'package:flutter/services.dart';

import 'flutter_qr_scanner_platform_interface.dart';

class FlutterQrScanner {
  /// Quét mã QR bằng camera
  static Future<Map?> scanQR({bool showGallery = false}) async {
    return await FlutterQrScannerPlatform.instance
        .scanQR(showGallery: showGallery);
  }

  /// Quét mã QR từ file ảnh (path)
  static Future<Map?> scanQRFromImage(String filePath) async {
    return await FlutterQrScannerPlatform.instance.scanQRFromImage(filePath);
  }

  /// Lấy thông tin platform (nếu cần)
  static Future<String?> getPlatformVersion() async {
    return await FlutterQrScannerPlatform.instance.getPlatformVersion();
  }

  // Quét từ ảnh (Uint8List)
  Future<Map?> scanQRFromImageBytes(Uint8List bytes) async {
    return await FlutterQrScannerPlatform.instance.scanQRFromImageBytes(bytes);
  }
}
