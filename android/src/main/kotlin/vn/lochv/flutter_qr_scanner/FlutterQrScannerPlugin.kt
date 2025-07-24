package vn.lochv.flutter_qr_scanner

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.zxing.integration.android.IntentIntegrator
import com.google.zxing.integration.android.IntentResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class FlutterQrScannerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var result: MethodChannel.Result? = null
    private var pendingMethodCall: MethodCall? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_qr_scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "scanQR" -> {
                this.result = result
                this.pendingMethodCall = call

                activity?.let {
                    val permission = ContextCompat.checkSelfPermission(it, Manifest.permission.CAMERA)
                    if (permission == PackageManager.PERMISSION_GRANTED) {
                        startQrScanner(it)
                    } else {
                        ActivityCompat.requestPermissions(it, arrayOf(Manifest.permission.CAMERA), 2001)
                    }
                } ?: run {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                }
            }

            "scanQRFromImage" -> {
                val path = call.argument<String>("path")
                val decoded = path?.let { QrScanHelper.scanQRFromImagePath(it) }
                if (decoded != null) {
                    result.success(decoded)
                } else {
                    result.error("QR_NOT_FOUND", "Không tìm thấy mã QR trong ảnh", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun startQrScanner(activity: Activity) {
        val integrator = IntentIntegrator(activity)
        integrator.setDesiredBarcodeFormats(IntentIntegrator.QR_CODE)
        integrator.setPrompt("Scan a QR code")
        integrator.setBeepEnabled(false)
        integrator.captureActivity = PortraitCaptureActivity::class.java
        integrator.initiateScan()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val resultIntent: IntentResult? = IntentIntegrator.parseActivityResult(requestCode, resultCode, data)
        if (resultIntent != null) {
            val resultMap = HashMap<String, Any?>()
            resultMap["content"] = resultIntent.contents
            resultMap["format"] = resultIntent.formatName ?: ""
            resultMap["rawBytes"] = resultIntent.rawBytes?.joinToString(",") { it.toString() } ?: ""
            resultMap["errorCorrectionLevel"] = resultIntent.errorCorrectionLevel ?: ""
            this.result?.success(resultMap)
            return true
        }
        this.result?.error("QR_NOT_FOUND", "Không tìm thấy mã QR", null)
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)

        binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
            if (requestCode == 2001) {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    activity?.let { startQrScanner(it) }
                } else {
                    result?.error("PERMISSION_DENIED", "Camera permission denied", null)
                }
                true
            } else {
                false
            }
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }
}
