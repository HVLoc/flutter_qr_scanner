import 'package:flutter/material.dart';
import 'package:flutter_qr_scanner/flutter_qr_scanner.dart';
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
    final result = await FlutterQrScanner.scanQR();
    if (result != null) {
      setState(() {
        content = result['content'] as String?;
      });
    }
  }

  Future<void> _pickAndScanImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final result = await FlutterQrScanner.scanQRFromImage(picked.path);
      setState(() {
        fromImage = result;
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
              child: const Text('Scan QR Camera'),
            ),
            if (content != null) ...[
              Text('Camera QR Result: $content'),
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
