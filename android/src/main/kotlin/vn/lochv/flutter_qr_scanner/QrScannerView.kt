package vn.lochv.flutter_qr_scanner

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.CompoundBarcodeView
import com.journeyapps.barcodescanner.camera.CameraSettings
import io.flutter.plugin.platform.PlatformView

class QrScannerView(
    context: Context,
    private val onScanResult: (String) -> Unit
) : PlatformView {

    private val view: FrameLayout
    private var lastScanTime = 0L  // Thời gian lần quét gần nhất (ms)

    init {
        view = FrameLayout(context)

        val barcodeView = CompoundBarcodeView(context).apply {
            statusView.text = ""
            cameraSettings.focusMode = CameraSettings.FocusMode.CONTINUOUS
            viewFinder.visibility = View.GONE
        }

        // Thêm barcodeView vào layout
        val layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        view.addView(barcodeView, layoutParams)

        // Overlay (nếu muốn thêm giao diện chồng lên)
        val overlay = FrameLayout(context).apply {
            this.layoutParams = layoutParams
        }
        view.addView(overlay)

        // Xử lý quét liên tục nhưng không spam
        barcodeView.decodeContinuous(object : BarcodeCallback {
            override fun barcodeResult(result: BarcodeResult) {
                val now = System.currentTimeMillis()
                if (now - lastScanTime >= 1000) { // Cách nhau ít nhất 1s
                    lastScanTime = now
                    onScanResult(result.text)
                }
            }

            override fun possibleResultPoints(resultPoints: MutableList<com.google.zxing.ResultPoint>?) {}
        })

        // Bắt đầu quét
        barcodeView.resume()
    }

    override fun getView(): View = view

    override fun dispose() {}
}
