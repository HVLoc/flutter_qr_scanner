import 'flutter_qr_scanner_platform_interface.dart';

class FlutterQrScanner {
  /// Quét mã QR bằng camera
  static Future<Map?> scanQR() async {
    return await FlutterQrScannerPlatform.instance.scanQR();
  }

  /// Quét mã QR từ file ảnh (path)
  static Future<Map?> scanQRFromImage(String filePath) async {
    return await FlutterQrScannerPlatform.instance.scanQRFromImage(filePath);
  }

  /// Lấy thông tin platform (nếu cần)
  static Future<String?> getPlatformVersion() {
    return FlutterQrScannerPlatform.instance.getPlatformVersion();
  }
}
