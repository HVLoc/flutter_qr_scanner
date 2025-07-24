import 'package:flutter/material.dart';
import 'package:flutter_qr_scanner/flutter_qr_scanner.dart';
import 'package:flutter_qr_scanner/qr_scanner_page.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRScannerExampleScreen(),
    );
  }
}

class QRScannerExampleScreen extends StatefulWidget {
  const QRScannerExampleScreen({super.key});

  @override
  State<QRScannerExampleScreen> createState() => _QRScannerExampleScreenState();
}

class _QRScannerExampleScreenState extends State<QRScannerExampleScreen> {
  String? content;
  String? fromImage;

  Future<void> _scanQRCode() async {
    final result = await FlutterQrScanner.scanQR(showGallery: true);
    if (result != null) {
      setState(() {
        content = result['content'] as String?;
      });
    }
  }

  Future<void> _scanWithCustomView() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomQRScannerScreen(),
      ),
    );
    if (result != null) {
      setState(() {
        content = result as String?;
      });
    }
  }

  Future<void> _pickAndScanImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final result = await FlutterQrScanner.scanQRFromImage(picked.path);
      setState(() {
        fromImage = result?['content'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter QR Scanner Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: _scanQRCode,
              child: const Text('Scan QR (Simple Native View)'),
            ),
            ElevatedButton(
              onPressed: _scanWithCustomView,
              child: const Text('Scan QR (Custom Flutter Overlay)'),
            ),
            if (content != null) ...[
              Text('QR Result: $content'),
            ],
            const Divider(height: 30),
            ElevatedButton(
              onPressed: _pickAndScanImage,
              child: const Text('Pick Image From Gallery To Scan QR'),
            ),
            if (fromImage != null) ...[
              Text('Image QR Result: $fromImage'),
            ]
          ],
        ),
      ),
    );
  }
}

class CustomQRScannerScreen extends StatefulWidget {
  const CustomQRScannerScreen({super.key});

  @override
  State<CustomQRScannerScreen> createState() => _CustomQRScannerScreenState();
}

class _CustomQRScannerScreenState extends State<CustomQRScannerScreen> {
  bool flashOn = false;

  void _onScanResult(String result) {
    print('Scan result: $result');

    Navigator.pop(context, result);
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  void _toggleFlash() {
    // Gửi toggle flash qua MethodChannel nếu bạn hỗ trợ
    setState(() {
      flashOn = !flashOn;
    });
  }

  void _openGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final result = await FlutterQrScanner.scanQRFromImage(picked.path);
      if (result?['content'] != null) {
        Navigator.pop(context, result?['content']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          QrScannerPage(
            onScanResult: _onScanResult,
          ),
          // Overlay UI
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _onCancel,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _openGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Hoàng LĐ Gà'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
