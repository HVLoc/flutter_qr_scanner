Dưới đây là bản cập nhật hoàn chỉnh của file `README.md` cho plugin **`flutter_qr_scanner`**, kết hợp nội dung gốc bạn đưa và bổ sung các phần còn thiếu:

---

````markdown
# 📦 Flutter QR Scanner Plugin

A Flutter plugin for scanning QR codes and barcodes using the device camera or decoding from images.  
Supports native camera view (`PlatformView`), custom overlay UI in Flutter, flash toggle, autofocus, and back button.  
Supports both **iOS (Vision Framework)** and **Android (ZXing)**.

---

## 🚀 Features

* 📷 Scan QR/Barcode via native camera (custom overlay supported)
* 🖼️ Decode QR/Barcode from an image (gallery or file path)
* 🔦 Flashlight toggle
* 🎯 Autofocus (continuous)
* 📐 Custom scan box overlay
* ❌ Close/back button
* ✅ Returns content, format, raw bytes, error correction level (if available)

---

## 📱 Platform Support

| Platform | Support | Framework |
|----------|---------|-----------|
| Android  | ✅ Yes  | ZXing     |
| iOS      | ✅ Yes  | VisionKit |

---

## 🛠️ Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_qr_scanner:
    path: ../flutter_qr_scanner
````

Or if hosted on GitHub:

```yaml
dependencies:
  flutter_qr_scanner:
    git:
      url: https://github.com/HVLoc/flutter_qr_scanner
```

---

## 🧪 Usage

### 1. Import the package

```dart
import 'package:flutter_qr_scanner/flutter_qr_scanner.dart';
```

---

### 2. Quick scan via native camera

```dart
final result = await FlutterQrScanner.scanQR(
  showGallery: true, // Show gallery button
);

if (result != null) {
  print('QR content: ${result["content"]}');
}
```

---

### 3. Scan from image (image picker or file path)

```dart
final result = await FlutterQrScanner.scanQRFromImage();
if (result != null) {
  print('QR from image: ${result["content"]}');
}
```

You can also pass a file path:

```dart
final result = await FlutterQrScanner.scanQRFromImage('/path/to/qr_image.png');
```

---

### 4. Embed custom camera with Flutter overlay

Use `QrScannerPage` in your widget tree to show the native camera as `PlatformView`, and customize overlay freely:

```dart
QrScannerPage(
  onScanResult: (result) {
    Navigator.pop(context, result);
  },
)
```

Overlay Flutter UI:

```dart
Stack(
  children: [
    QrScannerPage(
      onScanResult: (result) {
        Navigator.pop(context, result);
      },
    ),
    Positioned(
      top: 40,
      left: 16,
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  ],
)
```

---

## 🧰 Result Format

```json
{
  "content": "https://example.com",
  "format": "QR_CODE",
  "rawBytes": "",
  "errorCorrectionLevel": ""
}
```

---

## 📸 iOS Configuration

Ensure your `ios/Runner/Info.plist` contains:

```xml
<key>NSCameraUsageDescription</key>
<string>Cho phép ứng dụng sử dụng camera để quét mã QR</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cho phép ứng dụng truy cập thư viện ảnh để quét mã QR từ ảnh</string>
```

---

## 🔧 Android Configuration

Add required permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

Ensure your `minSdkVersion` is at least 21.

---

## 📷 Barcode Support

By default, both QR and barcodes (EAN, CODE\_128, etc.) are supported.

If you only want QR codes, you can configure detection mode (in a future update).

---

## ⚡ Performance Notes

* Barcode support may slightly affect scanning performance on low-end devices.
* VisionKit (iOS) is fast and optimized for both QR & barcode.
* Autofocus is enabled by default and runs continuously.

---

## 🛡️ Permissions

| Platform | Required Permissions                                         |
| -------- | ------------------------------------------------------------ |
| Android  | `CAMERA`,                            |
| iOS      | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` |

---

## 🧑‍💻 Maintainer

Developed & maintained by [HVLoc](https://github.com/HVLoc)

---

## 📄 License

MIT License – feel free to use and modify.

```