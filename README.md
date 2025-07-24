
## 📦 Flutter QR Scanner Plugin

A Flutter plugin for scanning QR codes using the device camera and decoding QR codes from images.
Supports customizable overlay UI, autofocus, flash toggle, and a manual close button.
(Android & iOS native implementation)

---

### 🚀 Features

* 📷 Scan QR code via camera
* 🖼️ Decode QR code from an image (gallery)
* 🔦 Flashlight toggle
* 🎯 Focus box with blur mask overlay
* 🎯 Autofocus (continuous)
* ❌ Close/back button
* ✅ Returns content + format on success

---

### 📱 Platform Support

| Platform | Support |
| -------- | ------- |
| Android  | ✅ Yes   |
| iOS      | ✅ Yes   |

---

### 🛠️ Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_qr_scanner:
    path: ../flutter_qr_scanner
```

Or from Git (if hosted):

```yaml
dependencies:
  flutter_qr_scanner:
    git:
      url: https://github.com/HVLoc/flutter_qr_scanner
```

---

### 🧪 Usage

#### 1. Import the package

```dart
import 'package:flutter_qr_scanner/flutter_qr_scanner.dart';
```

#### 2. Scan via camera

```dart
final result = await FlutterQrScanner.scanQR(
  showGallery: true, // Hiển thị chức năng chọn ảnh trong máy
);

if (result != null) {
  print('QR content: ${result["content"]}');
}

```

#### 3. Scan from image

```dart
final result = await FlutterQrScanner.scanQRFromImage();
if (result != null) {
  print('QR from image: ${result["content"]}');
}
```

---

### 🧰 Result Format

```json
{
  "content": "https://example.com",
  "format": "QR_CODE",
  "rawBytes": "",
  "errorCorrectionLevel": ""
}
```

---

### 📸 iOS Configuration

Make sure you add the following to your `ios/Runner/Info.plist`:

```xml
	<key>NSCameraUsageDescription</key>
	<string>Cho phép ứng dụng sử dụng camera để quét mã QR</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Cho phép ứng dụng truy cập thư viện ảnh để quét mã QR từ ảnh</string>
```

---

### 💡 Customization

* QR scan overlay supports:

  * Custom blur with transparent focus box
  * Autofocus (continuous)
  * Flashlight toggle button
  * Close/back button

No additional configuration needed – UI is native and optimized.

---

### 🔒 Permissions

* Android: Camera, Storage
* iOS: Camera, Photo Library (if using `scanQRFromImage`)

---

### 📄 License

MIT License – feel free to use and modify.

