package vn.lochv.flutter_qr_scanner

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.*
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.CompoundBarcodeView
import com.journeyapps.barcodescanner.camera.CameraSettings
import io.flutter.plugin.platform.PlatformView
import android.view.ViewGroup

class QrScannerView(
    context: Context,
    private val onScanResult: (String) -> Unit,
) : PlatformView {

    private val view: FrameLayout

    init {
        view = FrameLayout(context)

        val barcodeView = CompoundBarcodeView(context)
        barcodeView.statusView.text = ""
        barcodeView.cameraSettings.focusMode = CameraSettings.FocusMode.CONTINUOUS
        barcodeView.setTorchOff()
        barcodeView.viewFinder.visibility = View.GONE
        barcodeView.resume()

        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        barcodeView.statusView.text = ""
        view.addView(barcodeView)
        // Giao diện overlay
        val overlay = FrameLayout(context)
        overlay.layoutParams = layoutParams

        view.addView(overlay)

        barcodeView.decodeSingle(object : BarcodeCallback {
            override fun barcodeResult(result: BarcodeResult) {
                onScanResult(result.text)
            }

            override fun possibleResultPoints(resultPoints: MutableList<com.google.zxing.ResultPoint>?) {}
        })
    }

    override fun getView(): View = view

    override fun dispose() {}
}
