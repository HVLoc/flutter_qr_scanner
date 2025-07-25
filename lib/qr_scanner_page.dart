import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // for defaultTargetPlatform

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
    const viewType = 'vn.lochv.flutter_qr_scanner/native_view';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          final controller = PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
          );
          controller.addOnPlatformViewCreatedListener((id) {
            setupQrScannerChannel(id, widget.onScanResult);
            params.onPlatformViewCreated(id);
          });
          controller.create();
          return controller;
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType,
        onPlatformViewCreated: (id) {
          setupQrScannerChannel(id, widget.onScanResult);
        },
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      );
    } else {
      return const Text("Unsupported platform");
    }
  }
}
