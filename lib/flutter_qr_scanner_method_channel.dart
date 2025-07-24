import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_qr_scanner_platform_interface.dart';

/// Platform-specific implementation using MethodChannel.
class MethodChannelFlutterQrScanner extends FlutterQrScannerPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_qr_scanner');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Map?> scanQR({bool showGallery = false}) async {
    final result = await methodChannel
        .invokeMethod<Map>('scanQR', {"showGallery": showGallery});
    return result;
  }

  @override
  Future<Map?> scanQRFromImage(String filePath) async {
    final result = await methodChannel.invokeMethod<Map>(
      'scanQRFromImage',
      {"path": filePath},
    );
    return result;
  }
}
