import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'flutter_qr_scanner_method_channel.dart';

abstract class FlutterQrScannerPlatform extends PlatformInterface {
  FlutterQrScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterQrScannerPlatform _instance = MethodChannelFlutterQrScanner();

  static FlutterQrScannerPlatform get instance => _instance;

  static set instance(FlutterQrScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<Map?> scanQR({bool showGallery = false}) {
    throw UnimplementedError('scanQR() has not been implemented.');
  }

  Future<Map?> scanQRFromImage(String filePath) {
    throw UnimplementedError('scanQRFromImage() has not been implemented.');
  }
}
