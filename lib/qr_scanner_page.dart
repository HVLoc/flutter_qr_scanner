import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key, required this.onScanResult});

  final Function(String) onScanResult;

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  void setupQrScannerChannel(int viewId, void Function(String) onScanResult) {
    final methodChannel = MethodChannel('flutter_qr_scanner_channel_$viewId');

    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onScanResult') {
        final qr = call.arguments as String;
        onScanResult(qr);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'vn.lochv.flutter_qr_scanner/native_view',
      onPlatformViewCreated: (id) {
        setupQrScannerChannel(id, (qrCode) {
          widget.onScanResult(qrCode);
        });
      },
      creationParams: const {'showGallery': true},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
