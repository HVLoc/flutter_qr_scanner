package vn.lochv.flutter_qr_scanner

import android.graphics.BitmapFactory
import com.google.zxing.*
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.ResultMetadataType
import java.io.File

object QrScanHelper {
    fun scanQRFromImagePath(imagePath: String?): Map<String, Any?>? {
        if (imagePath.isNullOrBlank()) return null

        val file = File(imagePath)
        if (!file.exists()) return null

        val bitmap = BitmapFactory.decodeFile(imagePath) ?: return null

        val intArray = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(intArray, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)

        val source = RGBLuminanceSource(bitmap.width, bitmap.height, intArray)
        val binaryBitmap = BinaryBitmap(HybridBinarizer(source))

        return try {
            val reader = MultiFormatReader()
            val result = reader.decode(binaryBitmap)

            val resultMap = HashMap<String, Any?>()
            resultMap["content"] = result.text
            resultMap["format"] = result.barcodeFormat.name
            resultMap["rawBytes"] = result.rawBytes?.joinToString(",") { it.toString() } ?: ""
            resultMap["errorCorrectionLevel"] = result.resultMetadata?.get(ResultMetadataType.ERROR_CORRECTION_LEVEL) ?: ""

            resultMap
        } catch (e: Exception) {
            null
        }
    }
}
